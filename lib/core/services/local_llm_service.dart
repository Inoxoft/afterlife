import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/pigeon.g.dart';
// shared_preferences imported via PreferencesService
import 'package:path_provider/path_provider.dart';
import 'preferences_service.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../utils/app_logger.dart';
import '../utils/env_config.dart';

// Model download status
enum ModelDownloadStatus { notDownloaded, downloading, downloaded, error }

// Model configuration (Gemma 3n E2B-it LiteRT preview)
class ModelConfig {
  // Smaller LiteRT .task suitable for iOS memory mapping
  static const String url =
      'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task';
  static const String filename = 'gemma-3n-E2B-it-int4.task';
  static const String displayName = 'Gemma 3n E2B-it (int4, LiteRT preview)';
  // Unknown/large size; relax verification (accept >1GB)
  static const int fileSizeBytes = 0;
  static const int maxTokens = 1024; // safe default for iOS
  static const double temperature = 0.7;
  static const int topK = 40;
  static const double topP = 0.95;
  static const PreferredBackend preferredBackend = PreferredBackend.gpu;
  // Use Gemma instruction type as a generic text-only type for compatibility
  static const ModelType modelType = ModelType.gemmaIt;
}

class LocalLLMService {
  static LocalLLMService? _instance;
  static LocalLLMService get instance => _instance ??= LocalLLMService._();
  LocalLLMService._();

  // No embedded token; use .env or user-provided token via settings

  // Flutter Gemma plugin instance
  static late FlutterGemmaPlugin _gemmaPlugin;
  static InferenceModel? _model;
  static InferenceChat? _chat;

  // Settings
  static bool _isEnabled = false;
  static bool _isInitialized = false;
  static String? _huggingFaceToken;
  static bool _googleAgreementAccepted = false;

  // Model state
  static ModelDownloadStatus _modelStatus = ModelDownloadStatus.notDownloaded;
  static String? _modelPath;
  static double _downloadProgress = 0.0;
  static String? _downloadError;

  // Stream controllers
  static StreamController<double>? _downloadProgressController;
  static StreamController<ModelDownloadStatus>? _modelStatusController;

  // Download cancellation
  static bool _shouldCancelDownload = false;

  // Getters
  static bool get isEnabled => _isEnabled;
  static bool get isAvailable =>
      _isInitialized && _model != null && _chat != null;
  static bool get isInitialized => _isInitialized;
  static ModelDownloadStatus get modelStatus => _modelStatus;
  static String? get modelPath => _modelPath;
  static double get downloadProgress => _downloadProgress;
  static String? get downloadError => _downloadError;
  static bool get googleAgreementAccepted => _googleAgreementAccepted;

  // Stream getters
  static Stream<double> get downloadProgressStream {
    _downloadProgressController ??= StreamController<double>.broadcast();
    return _downloadProgressController!.stream;
  }

  static Stream<ModelDownloadStatus> get modelStatusStream {
    _modelStatusController ??=
        StreamController<ModelDownloadStatus>.broadcast();
    return _modelStatusController!.stream;
  }

  // Initialization guard
  static bool _initializing = false;

  // Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializing) return;
    
    _initializing = true;
    try {
      if (kDebugMode) {
        AppLogger.debug('Initializing LocalLLMService', tag: 'LocalLLMService');
      }

      // Initialize flutter_gemma plugin
      _gemmaPlugin = FlutterGemmaPlugin.instance;

      // Load preferences
      final prefs = await PreferencesService.getPrefs();
      _isEnabled = prefs.getBool('local_llm_enabled') ?? false;
      _modelPath = prefs.getString('local_llm_model_path');
      // Prefer user-saved token; otherwise read from EnvConfig (.env)
      final savedToken = prefs.getString('huggingface_token');
      _huggingFaceToken = (savedToken != null && savedToken.isNotEmpty)
          ? savedToken
          : (EnvConfig.get('HUGGINGFACE_TOKEN') ?? '');
      _googleAgreementAccepted =
          prefs.getBool('google_agreement_accepted') ?? true; // assumed accepted

      // Check if model file exists
      await _checkModelStatus();

      // If model is downloaded and enabled, initialize it
      if (_modelStatus == ModelDownloadStatus.downloaded) {
        // Auto-enable when a valid model file is present
        _isEnabled = true;
        final prefs = await PreferencesService.getPrefs();
        await prefs.setBool('local_llm_enabled', true);
        await _initializeModel();
      }

      _isInitialized = true;
      
      if (kDebugMode) {
        AppLogger.serviceInitialized('LocalLLMService');
        AppLogger.debug(
          'Enabled: $_isEnabled, Status: $_modelStatus',
          tag: 'LocalLLMService'
        );
      }
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'initialization error', e);
      _modelStatus = ModelDownloadStatus.error;
      _downloadError = e.toString();
      _isInitialized = false;
    } finally {
      _initializing = false;
    }
  }

  // Check model status
  static Future<void> _checkModelStatus() async {
    // If we don't have a stored path, try the expected filename first
    if (_modelPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      final candidatePath = '${directory.path}/' + ModelConfig.filename;
      if (await File(candidatePath).exists()) {
        _modelPath = candidatePath;
      }
    }

    // If the stored path points to a missing file, attempt to rediscover any .task model in Documents
    if (_modelPath != null && !await File(_modelPath!).exists()) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final dir = Directory(directory.path);
        final candidates = await dir
            .list(recursive: false, followLinks: false)
            .where((e) => e is File && e.path.toLowerCase().endsWith('.task'))
            .cast<File>()
            .toList();
        // Prefer a file that matches the configured filename; otherwise take the largest .task file
        File? chosen;
        for (final f in candidates) {
          if (f.path.endsWith('/' + ModelConfig.filename)) {
            chosen = f;
            break;
          }
        }
        chosen ??= candidates.isEmpty
            ? null
            : (await _pickLargestTaskFile(candidates));
        if (chosen != null && await chosen.exists()) {
          _modelPath = chosen.path;
          final prefs = await PreferencesService.getPrefs();
          await prefs.setString('local_llm_model_path', _modelPath!);
        }
      } catch (_) {}
    }

    if (_modelPath != null && await File(_modelPath!).exists()) {
      final fileSize = await File(_modelPath!).length();

      // Verify file size with tolerance
      if (_verifyDownload(fileSize, ModelConfig.fileSizeBytes)) {
        _modelStatus = ModelDownloadStatus.downloaded;
        AppLogger.debug('Model file found and verified at: $_modelPath', tag: 'LocalLLMService');
      } else {
        AppLogger.warning(
          'Model file size mismatch - Expected: ${ModelConfig.fileSizeBytes}, Actual: $fileSize',
          tag: 'LocalLLMService'
        );
        _modelStatus = ModelDownloadStatus.error;
        _downloadError = 'File size verification failed';
      }
    } else {
      _modelStatus = ModelDownloadStatus.notDownloaded;
      _modelPath = null;
      AppLogger.debug('No model file found', tag: 'LocalLLMService');
    }
  }

  // Helper to pick the largest .task file (most likely the model)
  static Future<File> _pickLargestTaskFile(List<File> files) async {
    File largest = files.first;
    int maxSize = await largest.length();
    for (final f in files.skip(1)) {
      final s = await f.length();
      if (s > maxSize) {
        maxSize = s;
        largest = f;
      }
    }
    return largest;
  }

  // Verify download file size
  static bool _verifyDownload(int actualSize, int expectedSize) {
    // Relaxed verification: allow 10% tolerance; if unknown expected,
    // accept any file larger than ~1GB as valid .task model
    if (expectedSize <= 0) {
      return actualSize > 1024 * 1024 * 1024;
    }
    final tolerance = (expectedSize * 0.10).toInt();
    final withinTolerance = (actualSize - expectedSize).abs() <= tolerance;
    if (withinTolerance) return true;
    // Fallback acceptance for repackaged .task files
    return actualSize > 1024 * 1024 * 1024;
  }

  // Initialize the model
  static Future<void> _initializeModel() async {
    if (_modelPath == null || !await File(_modelPath!).exists()) {
      if (kDebugMode) {
        AppLogger.warning('Cannot initialize model: file not found at $_modelPath', tag: 'LocalLLMService');
      }
      return;
    }

    try {
      // On iOS, very large .task files may fail to memory-map (ODML LiteRT) with
      // "Cannot allocate memory". Proactively guard and provide a clear error.
      if (Platform.isIOS) {
        final int fileSizeBytes = await File(_modelPath!).length();
        // Empirical safe threshold for iOS devices. Recommend <= ~2.0GB.
        const int iosRecommendedMaxBytes = 2200 * 1024 * 1024; // ~2.2 GB
        if (fileSizeBytes > iosRecommendedMaxBytes) {
          final double sizeGb = fileSizeBytes / (1024 * 1024 * 1024);
          _downloadError =
              'The selected local model is too large for iOS memory mapping (size: ' +
              sizeGb.toStringAsFixed(2) +
              ' GB). Please download and use a smaller iOS .task variant (<= ~2.0 GB).';
          AppLogger.serviceError(
            'LocalLLMService',
            'iOS model too large for memory mapping',
            _downloadError,
          );
          throw Exception(_downloadError);
        }
      }

      if (kDebugMode) {
        AppLogger.debug('Initializing Gemma 3n model at: $_modelPath', tag: 'LocalLLMService');
      }

      // Close existing instances to prevent memory leaks
      if (_chat?.session != null) {
        await _chat!.session.close();
      }
      if (_model != null) {
        await _model!.close();
      }
      _chat = null;
      _model = null;

      // Set model path in the model manager
      await _gemmaPlugin.modelManager.setModelPath(_modelPath!);

      // Create the model (use iOS-friendly settings to avoid memory issues)
      final bool isIOS = Platform.isIOS;
      final int iosMaxTokens = 1024; // conservative default for iOS
      final bool iosSupportImage = false; // disable images on iOS initially
      _model = await _gemmaPlugin.createModel(
        modelType: ModelConfig.modelType,
        maxTokens: isIOS ? iosMaxTokens : ModelConfig.maxTokens,
        preferredBackend: ModelConfig.preferredBackend,
        supportImage: isIOS ? iosSupportImage : true,
      );

      // Create chat session
      _chat = await _model!.createChat(
        temperature: ModelConfig.temperature,
        randomSeed: 1,
        topK: ModelConfig.topK,
        topP: ModelConfig.topP,
        tokenBuffer: isIOS ? 64 : 256,
        supportImage: isIOS ? iosSupportImage : true,
      );

      if (kDebugMode) {
        AppLogger.debug('Gemma 3n model initialized successfully', tag: 'LocalLLMService');
      }
      _isInitialized = true;
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'model initialization error', e);
      _model = null;
      _chat = null;
      _isInitialized = false;
      throw Exception('Failed to initialize model: $e');
    }
  }

  // Get settings (method needed by settings screen)
  static Map<String, dynamic> getSettings() {
    // Derive file size from actual downloaded file when available
    double computedSizeGb = 0.0;
    try {
      if (_modelPath != null) {
        final f = File(_modelPath!);
        if (f.existsSync()) {
          computedSizeGb = f.lengthSync() / (1024 * 1024 * 1024);
        }
      }
    } catch (_) {}

    // Fallback to configured size if real size not available
    if (computedSizeGb <= 0 && ModelConfig.fileSizeBytes > 0) {
      computedSizeGb = ModelConfig.fileSizeBytes / (1024 * 1024 * 1024);
    }

    return {
      'enabled': _isEnabled,
      'modelStatus': _modelStatus.name,
      'downloadProgress': _downloadProgress,
      'downloadError': _downloadError,
      'modelConfig': {
        'displayName': ModelConfig.displayName,
        'filename': ModelConfig.filename,
        'maxTokens': ModelConfig.maxTokens,
        'fileSizeGB': computedSizeGb.toStringAsFixed(1),
        'supportImage': true,
      },
    };
  }

  // Update settings (method needed by settings screen)
  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('enabled')) {
        final enabled = settings['enabled'] as bool;
        if (enabled) {
          await enableLocalLLM();
        } else {
          await disableLocalLLM();
        }
      }
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'settings update error', e);
      throw Exception('Failed to update settings: $e');
    }
  }

  // Download model
  static Future<bool> downloadModel({
    bool acceptGoogleAgreement = false,
    String? huggingFaceToken,
  }) async {
    if (_modelStatus == ModelDownloadStatus.downloading) {
      if (kDebugMode) {
        AppLogger.debug('Model download already in progress', tag: 'LocalLLMService');
      }
      return false;
    }

    try {
      _shouldCancelDownload = false;
      _modelStatus = ModelDownloadStatus.downloading;
      _downloadProgress = 0.0;
      _downloadError = null;
      _modelStatusController?.add(_modelStatus);

              // Get download directory
        final directory = await getApplicationDocumentsDirectory();
        String dynamicFilename = ModelConfig.filename;
        String modelPath = '${directory.path}/' + dynamicFilename;
        String tempPath = '${modelPath}.part';

        if (kDebugMode) {
          AppLogger.debug('Downloading ${ModelConfig.displayName} to: $modelPath', tag: 'LocalLLMService');
        }

      // Enable wakelock
      await WakelockPlus.enable();

      // Create HTTP client
      final client = http.Client();

      try {
        // Make request with token if available
        Uri targetUri = Uri.parse(ModelConfig.url);
        final request = http.Request('GET', targetUri);
        
        // Add Hugging Face token if provided or stored (.env/user)
        final token = (huggingFaceToken ?? _huggingFaceToken ?? '').trim();
        if (token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.headers['User-Agent'] = 'afterlife-app/1.0';
        request.headers['Accept'] = 'application/octet-stream';
        
        http.StreamedResponse response = await client.send(request);

        if (response.statusCode != 200) {
          if (response.statusCode == 401 || response.statusCode == 403) {
            throw Exception('Access denied (HTTP ${response.statusCode}). Please ensure HUGGINGFACE_TOKEN in .env (or Settings) has access.');
          }
          // If 404, try to resolve the actual .task filename via the Hugging Face API
          if (response.statusCode == 404) {
            final alt = await _resolveHuggingFaceTaskFile(ModelConfig.url, token);
            if (alt != null) {
              // Update paths with the discovered filename
              dynamicFilename = alt.$2;
              modelPath = '${directory.path}/' + dynamicFilename;
              tempPath = '${modelPath}.part';
              if (kDebugMode) {
                AppLogger.debug('Resolved .task filename via HF API: $dynamicFilename', tag: 'LocalLLMService');
              }
              final retryReq = http.Request('GET', Uri.parse(alt.$1));
              if (token.isNotEmpty) {
                retryReq.headers['Authorization'] = 'Bearer $token';
              }
              retryReq.headers['User-Agent'] = 'afterlife-app/1.0';
              retryReq.headers['Accept'] = 'application/octet-stream';
              response = await client.send(retryReq);
              if (response.statusCode != 200) {
                throw Exception('Failed to download model after resolving filename: HTTP ${response.statusCode}');
              }
            } else {
              throw Exception('Failed to download model: HTTP 404 (no .task file found in repo)');
            }
          } else {
          throw Exception(
            'Failed to download model: HTTP ${response.statusCode}',
          );
          }
        }

        // Get content length
        final contentLength =
            response.contentLength ?? ModelConfig.fileSizeBytes;

        // Create temporary file for atomic write
        final tempFile = File(tempPath);
        final sink = tempFile.openWrite();

        int downloadedBytes = 0;

        try {
          // Download with progress tracking
          await for (final chunk in response.stream) {
            if (_shouldCancelDownload) {
              await sink.close();
              if (await tempFile.exists()) {
                await tempFile.delete();
              }
              // Set proper state instead of error
              _modelStatus = ModelDownloadStatus.notDownloaded;
              _downloadProgress = 0.0;
              _downloadError = null;
              _modelStatusController?.add(_modelStatus);
              _downloadProgressController?.add(_downloadProgress);
              if (kDebugMode) {
                AppLogger.debug('Download cancelled by user', tag: 'LocalLLMService');
              }
              return false;
            }

            sink.add(chunk);
            downloadedBytes += chunk.length;

            // Update progress
            _downloadProgress = downloadedBytes / contentLength;
            _downloadProgressController?.add(_downloadProgress);

            // Optional: Add small delay to prevent UI blocking
            if (downloadedBytes % (1024 * 1024) == 0) {
              await Future.delayed(Duration(milliseconds: 1));
            }
          }

          await sink.close();

          // Verify file size
          final actualSize = await tempFile.length();
          if (kDebugMode) {
            AppLogger.debug('Downloaded file size: $actualSize bytes', tag: 'LocalLLMService');
          }

          final expected = response.contentLength ?? ModelConfig.fileSizeBytes;
          if (!_verifyDownload(actualSize, expected)) {
            await tempFile.delete();
            throw Exception('Downloaded file size verification failed');
          }

          // Atomic move: rename temp file to final name
          await tempFile.rename(modelPath);
        } catch (e) {
          await sink.close();
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          rethrow;
        }

        // Save model path
        _modelPath = modelPath;
        final prefs = await PreferencesService.getPrefs();
        await prefs.setString('local_llm_model_path', modelPath);

        _modelStatus = ModelDownloadStatus.downloaded;
        _downloadProgress = 1.0;
        _modelStatusController?.add(_modelStatus);
        _downloadProgressController?.add(1.0);

        if (kDebugMode) {
          AppLogger.debug('Model download completed successfully', tag: 'LocalLLMService');
        }

        // Auto-enable and initialize immediately after successful download
        await enableLocalLLM();
        return true;
      } finally {
        client.close();
        await WakelockPlus.disable();
      }
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'model download error', e);
      _modelStatus = ModelDownloadStatus.error;
      _downloadError = e.toString();
      _modelStatusController?.add(_modelStatus);
      return false;
    }
  }

  // Attempt to resolve the actual .task filename via Hugging Face API
  // Returns (downloadUrl, filename) or null if not found
  static Future<(String, String)?> _resolveHuggingFaceTaskFile(
    String configuredUrl,
    String? token,
  ) async {
    try {
      final uri = Uri.parse(configuredUrl);
      if (uri.host != 'huggingface.co' || uri.pathSegments.length < 2) {
        return null;
      }
      final org = uri.pathSegments[0];
      final repo = uri.pathSegments[1];
      final apiUrl = Uri.parse('https://huggingface.co/api/models/$org/$repo?full=1');
      final resp = await http.get(
        apiUrl,
        headers: {
          if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token',
          'User-Agent': 'afterlife-app/1.0',
          'Accept': 'application/json',
        },
      );
      if (resp.statusCode != 200) return null;
      final json = resp.body;
      // Very lightweight parsing to find a .task filename (avoid full JSON decode dependency)
      final regex = RegExp(r'"rfilename"\s*:\s*"([^"]+\.task)"');
      final match = regex.firstMatch(json);
      if (match != null) {
        final fname = match.group(1)!;
        final dl = 'https://huggingface.co/$org/$repo/resolve/main/$fname';
        return (dl, fname);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Stop download
  static void stopDownload() {
    _shouldCancelDownload = true;
    if (kDebugMode) {
      AppLogger.debug('Download cancellation requested', tag: 'LocalLLMService');
    }
  }

  // Enable local LLM
  static Future<bool> enableLocalLLM() async {
    try {
      if (kDebugMode) {
        AppLogger.debug('Enabling local LLM...', tag: 'LocalLLMService');
      }

      if (_modelStatus != ModelDownloadStatus.downloaded ||
          _modelPath == null) {
        if (kDebugMode) {
          AppLogger.warning('Cannot enable local LLM: model not downloaded', tag: 'LocalLLMService');
        }
        return false;
      }

      _isEnabled = true;
      final prefs = await PreferencesService.getPrefs();
      await prefs.setBool('local_llm_enabled', true);

      await _initializeModel();

      if (kDebugMode) {
        AppLogger.debug('Local LLM enabled. Available: $isAvailable', tag: 'LocalLLMService');
      }
      return isAvailable;
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'enable local LLM error', e);
      return false;
    }
  }

  // Disable local LLM
  static Future<void> disableLocalLLM() async {
    try {
      if (kDebugMode) {
        AppLogger.debug('Disabling local LLM...', tag: 'LocalLLMService');
      }

      _isEnabled = false;
      _isInitialized = false;

      // Close model and chat
      if (_chat?.session != null) {
        await _chat!.session.close();
      }
      if (_model != null) {
        await _model!.close();
      }
      _chat = null;
      _model = null;

      final prefs = await PreferencesService.getPrefs();
      await prefs.setBool('local_llm_enabled', false);

      if (kDebugMode) {
        AppLogger.debug('Local LLM disabled', tag: 'LocalLLMService');
      }
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'disable local LLM error', e);
    }
  }

  // Send message to local LLM
  static Future<String> sendMessage(
    String message, {
    String? systemPrompt,
  }) async {
    if (!isAvailable) {
      throw Exception('Local LLM is not available');
    }

    try {
      if (kDebugMode) {
        AppLogger.debug('Sending message to local LLM: $message', tag: 'LocalLLMService');
      }

      // Build prompt: if systemPrompt already contains the full dialogue
      // (used by local provider), avoid appending an empty "User:" suffix.
      final String prompt;
      if (systemPrompt != null) {
        prompt = message.isEmpty ? systemPrompt : '$systemPrompt\n\nUser: $message';
      } else {
        prompt = message;
      }

      // Add query chunk and get response
      await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await _chat!.generateChatResponse();

      if (kDebugMode) {
        AppLogger.debug('Local LLM response received', tag: 'LocalLLMService');
      }
      return response;
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'local LLM error', e);
      throw Exception('Failed to get response from local LLM: $e');
    }
  }

  // Send message with streaming response
  static Stream<String> sendMessageStream(
    String message, {
    String? systemPrompt,
  }) async* {
    if (!isAvailable) {
      throw Exception('Local LLM is not available');
    }

    try {
      if (kDebugMode) {
        AppLogger.debug('Sending streaming message to local LLM: $message', tag: 'LocalLLMService');
      }

      // Build prompt similar to non-streaming path
      final String prompt;
      if (systemPrompt != null) {
        prompt = message.isEmpty ? systemPrompt : '$systemPrompt\n\nUser: $message';
      } else {
        prompt = message;
      }

      // Add query chunk and stream response
      await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));
      await for (final chunk in _chat!.generateChatResponseAsync()) {
        yield chunk;
      }
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'local LLM streaming error', e);
      throw Exception('Failed to get streaming response from local LLM: $e');
    }
  }

  // Set Google agreement acceptance
  static Future<void> setGoogleAgreementAccepted(bool accepted) async {
    _googleAgreementAccepted = accepted;
    final prefs = await PreferencesService.getPrefs();
    await prefs.setBool('google_agreement_accepted', accepted);
  }

  // Set Hugging Face token
  static Future<void> setHuggingFaceToken(String? token) async {
    _huggingFaceToken = token;
    final prefs = await PreferencesService.getPrefs();
    if (token != null) {
      await prefs.setString('huggingface_token', token);
    } else {
      await prefs.remove('huggingface_token');
    }
  }

  // Delete model
  static Future<void> deleteModel() async {
    try {
      // Close model and chat first
      if (_chat?.session != null) {
        await _chat!.session.close();
      }
      await _model?.close();
      _chat = null;
      _model = null;

      if (_modelPath != null) {
        final file = File(_modelPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _modelStatus = ModelDownloadStatus.notDownloaded;
      _modelPath = null;
      _isEnabled = false;
      _isInitialized = false;
      _downloadProgress = 0.0;
      _downloadError = null;

      final prefs = await PreferencesService.getPrefs();
      await prefs.remove('local_llm_model_path');
      await prefs.setBool('local_llm_enabled', false);

      _modelStatusController?.add(_modelStatus);
      if (kDebugMode) {
        AppLogger.debug('Model deleted successfully', tag: 'LocalLLMService');
      }
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'delete model error', e);
    }
  }

  // Get status information
  static Map<String, dynamic> getStatus() {
    return {
      'isEnabled': _isEnabled,
      'isAvailable': isAvailable,
      'isInitialized': _isInitialized,
      'modelStatus': _modelStatus.name,
      'modelPath': _modelPath,
      'downloadProgress': _downloadProgress,
      'downloadError': _downloadError,
      'hasHuggingFaceToken': _huggingFaceToken != null,
      'googleAgreementAccepted': _googleAgreementAccepted,
      'modelConfig': {
        'displayName': ModelConfig.displayName,
        'filename': ModelConfig.filename,
        'maxTokens': ModelConfig.maxTokens,
        'fileSizeGB': (ModelConfig.fileSizeBytes / (1024 * 1024 * 1024))
            .toStringAsFixed(1),
      },
    };
  }

  // Get diagnostics
  static Map<String, dynamic> getDiagnostics() {
    final diagnostics = getStatus();

    if (_modelPath != null) {
      final file = File(_modelPath!);
      diagnostics['modelFileExists'] = file.existsSync();
      if (file.existsSync()) {
        diagnostics['modelFileSize'] = file.lengthSync();
      }
    }

    return diagnostics;
  }

  // Public method to manually initialize the model
  static Future<bool> initializeModel() async {
    if (_modelStatus != ModelDownloadStatus.downloaded || _modelPath == null) {
      if (kDebugMode) {
        AppLogger.warning('Cannot initialize model: not downloaded or path is null', tag: 'LocalLLMService');
      }
      return false;
    }

    await _initializeModel();
    return _isInitialized;
  }

  // Dispose resources
  static Future<void> dispose() async {
    try {
      if (_chat?.session != null) {
        await _chat!.session.close();
      }
      await _model?.close();
      _chat = null;
      _model = null;
      _isInitialized = false;
      _downloadProgressController?.close();
      _modelStatusController?.close();
      _downloadProgressController = null;
      _modelStatusController = null;
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'dispose error', e);
    }
  }

  // Clean LLM response by removing role labels and framework tokens
  static String cleanLocalResponse(String raw) {
    String text = raw.replaceAll('\r\n', '\n').trim();

    // Remove framework-specific tokens often emitted by Gemma
    text = text.replaceAll('<end_of_turn>', '').trim();

    // If the response contains role sections, take the last Assistant segment
    final int lastAssistant = text.lastIndexOf('Assistant:');
    if (lastAssistant >= 0) {
      text = text.substring(lastAssistant + 'Assistant:'.length).trim();
    }

    // Drop any lines that start with 'Human:'
    final lines = text.split('\n');
    final filtered = lines.where((l) => !l.trim().startsWith('Human:'));
    text = filtered.join('\n').trim();

    // Remove any remaining leading 'Assistant:' labels
    text = text.replaceAll(RegExp(r'^\s*Assistant:\s*', multiLine: true), '').trim();

    return text;
  }
}
