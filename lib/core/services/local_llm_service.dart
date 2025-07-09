import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';

// Model download status
enum ModelDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  error,
}

// Model configuration for DeepSeek
class ModelConfig {
  static const String url = 'https://huggingface.co/litert-community/Hammer2.1-1.5b/resolve/main/Hammer2.1-1.5b_multi-prefill-seq_q8_ekv1280.task';
  static const String filename = 'Hammer2.1-1.5b_multi-prefill-seq_q8_ekv1280.task';
  static const String displayName = 'Hammer2.1-1.5b (CPU) 1.6Gb';
  static const int fileSizeBytes = 1597556473;
  static const int maxTokens = 1024;
  static const double temperature = 0.7;
  static const int topK = 40;
  static const double topP = 0.95;
  static const PreferredBackend preferredBackend = PreferredBackend.cpu;
  static const ModelType modelType = ModelType.deepSeek;
}

class LocalLLMService {
  static LocalLLMService? _instance;
  static LocalLLMService get instance => _instance ??= LocalLLMService._();
  LocalLLMService._();

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
  static bool get isAvailable => _isInitialized && _model != null && _chat != null;
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
    _modelStatusController ??= StreamController<ModelDownloadStatus>.broadcast();
    return _modelStatusController!.stream;
  }

  // Initialize the service
  static Future<void> initialize() async {
    try {
      print('Initializing LocalLLMService...');
      
      // Initialize flutter_gemma plugin
      _gemmaPlugin = FlutterGemmaPlugin.instance;
      
      // Load preferences
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('local_llm_enabled') ?? false;
      _modelPath = prefs.getString('local_llm_model_path');
      _huggingFaceToken = prefs.getString('huggingface_token');
      _googleAgreementAccepted = prefs.getBool('google_agreement_accepted') ?? false;

      // Check if model file exists
      await _checkModelStatus();

      // If model is downloaded and enabled, initialize it
      if (_modelStatus == ModelDownloadStatus.downloaded && _isEnabled) {
        await _initializeModel();
      }

      print('LocalLLMService initialized - enabled: $_isEnabled, status: $_modelStatus');
    } catch (e) {
      print('LocalLLMService initialization error: $e');
      _modelStatus = ModelDownloadStatus.error;
      _downloadError = e.toString();
    }
  }

  // Check model status
  static Future<void> _checkModelStatus() async {
    if (_modelPath != null && await File(_modelPath!).exists()) {
      final fileSize = await File(_modelPath!).length();
      
      // Verify file size with tolerance
      if (_verifyDownload(fileSize, ModelConfig.fileSizeBytes)) {
        _modelStatus = ModelDownloadStatus.downloaded;
        print('Model file found and verified at: $_modelPath');
      } else {
        print('Model file size mismatch. Expected: ${ModelConfig.fileSizeBytes}, Actual: $fileSize');
        _modelStatus = ModelDownloadStatus.error;
        _downloadError = 'File size verification failed';
      }
    } else {
      _modelStatus = ModelDownloadStatus.notDownloaded;
      _modelPath = null;
      print('No model file found');
    }
  }

  // Verify download file size
  static bool _verifyDownload(int actualSize, int expectedSize) {
    // Allow 10% tolerance for file size
    final tolerance = expectedSize * 0.10;
    return (actualSize - expectedSize).abs() <= tolerance;
  }

  // Initialize the model
  static Future<void> _initializeModel() async {
    if (_modelPath == null || !await File(_modelPath!).exists()) {
      print('Cannot initialize model: file not found at $_modelPath');
      return;
    }

    try {
      print('Initializing DeepSeek model at: $_modelPath');
      
      // Set model path in the model manager
      await _gemmaPlugin.modelManager.setModelPath(_modelPath!);
      
      // Create the model
      _model = await _gemmaPlugin.createModel(
        modelType: ModelConfig.modelType,
        maxTokens: ModelConfig.maxTokens,
        preferredBackend: ModelConfig.preferredBackend,
        supportImage: false, // DeepSeek doesn't support images
      );

      // Create chat session
      _chat = await _model!.createChat(
        temperature: ModelConfig.temperature,
        randomSeed: 1,
        topK: ModelConfig.topK,
        topP: ModelConfig.topP,
        tokenBuffer: 256,
        supportImage: false,
      );

      _isInitialized = true;
      print('DeepSeek model initialized successfully');
    } catch (e) {
      print('Model initialization error: $e');
      _isInitialized = false;
      _model = null;
      _chat = null;
      throw Exception('Failed to initialize model: $e');
    }
  }

  // Get settings (method needed by settings screen)
  static Map<String, dynamic> getSettings() {
    return {
      'enabled': _isEnabled,
      'modelStatus': _modelStatus.name,
      'downloadProgress': _downloadProgress,
      'downloadError': _downloadError,
      'modelConfig': {
        'displayName': ModelConfig.displayName,
        'filename': ModelConfig.filename,
        'maxTokens': ModelConfig.maxTokens,
        'fileSizeGB': (ModelConfig.fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1),
        'supportImage': false,
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
      print('Error updating settings: $e');
      throw Exception('Failed to update settings: $e');
    }
  }

  // Download model
  static Future<bool> downloadModel({bool acceptGoogleAgreement = false, String? huggingFaceToken}) async {
    if (_modelStatus == ModelDownloadStatus.downloading) {
      print('Model download already in progress');
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
      final modelPath = '${directory.path}/${ModelConfig.filename}';
      
      print('Downloading ${ModelConfig.displayName} to: $modelPath');

      // Enable wakelock
      await WakelockPlus.enable();

      // Create HTTP client
      final client = http.Client();

      try {
        // Make request
        final request = http.Request('GET', Uri.parse(ModelConfig.url));
        final response = await client.send(request);

        if (response.statusCode != 200) {
          throw Exception('Failed to download model: HTTP ${response.statusCode}');
        }

        // Get content length
        final contentLength = response.contentLength ?? ModelConfig.fileSizeBytes;
        
        // Create file
        final file = File(modelPath);
        final sink = file.openWrite();
        
        int downloadedBytes = 0;
        
        // Download with progress tracking
        await for (final chunk in response.stream) {
          if (_shouldCancelDownload) {
            await sink.close();
            if (await file.exists()) {
              await file.delete();
            }
            throw Exception('Download cancelled by user');
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
        final actualSize = await file.length();
        print('Downloaded file size: $actualSize bytes');
        
        if (!_verifyDownload(actualSize, ModelConfig.fileSizeBytes)) {
          await file.delete();
          throw Exception('Downloaded file size verification failed');
        }

        // Save model path
        _modelPath = modelPath;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_llm_model_path', modelPath);

        _modelStatus = ModelDownloadStatus.downloaded;
        _downloadProgress = 1.0;
        _modelStatusController?.add(_modelStatus);
        _downloadProgressController?.add(1.0);

        print('Model download completed successfully');
        return true;
      } finally {
        client.close();
        await WakelockPlus.disable();
      }
    } catch (e) {
      print('Model download error: $e');
      _modelStatus = ModelDownloadStatus.error;
      _downloadError = e.toString();
      _modelStatusController?.add(_modelStatus);
      return false;
    }
  }

  // Stop download
  static void stopDownload() {
    _shouldCancelDownload = true;
    print('Download cancellation requested');
  }

  // Enable local LLM
  static Future<bool> enableLocalLLM() async {
    try {
      print('Enabling local LLM...');
      
      if (_modelStatus != ModelDownloadStatus.downloaded || _modelPath == null) {
        print('Cannot enable local LLM: model not downloaded');
        return false;
      }

      _isEnabled = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('local_llm_enabled', true);

      await _initializeModel();
      
      print('Local LLM enabled: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      print('Enable local LLM error: $e');
      return false;
    }
  }

  // Disable local LLM
  static Future<void> disableLocalLLM() async {
    try {
      print('Disabling local LLM...');
      
      _isEnabled = false;
      _isInitialized = false;
      
      // Close model and chat
      await _chat?.session?.close();
      await _model?.close();
      _chat = null;
      _model = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('local_llm_enabled', false);
      
      print('Local LLM disabled');
    } catch (e) {
      print('Disable local LLM error: $e');
    }
  }

  // Send message to local LLM
  static Future<String> sendMessage(String message, {String? systemPrompt}) async {
    if (!isAvailable) {
      throw Exception('Local LLM is not available');
    }

    try {
      print('Sending message to local LLM: $message');
      
      // Create message with system prompt if provided
      final prompt = systemPrompt != null ? '$systemPrompt\n\nUser: $message' : message;
      
      // Add query chunk and get response
      await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await _chat!.generateChatResponse();
      
      print('Local LLM response received');
      return response;
    } catch (e) {
      print('Local LLM error: $e');
      throw Exception('Failed to get response from local LLM: $e');
    }
  }

  // Send message with streaming response
  static Stream<String> sendMessageStream(String message, {String? systemPrompt}) async* {
    if (!isAvailable) {
      throw Exception('Local LLM is not available');
    }

    try {
      print('Sending streaming message to local LLM: $message');
      
      // Create message with system prompt if provided
      final prompt = systemPrompt != null ? '$systemPrompt\n\nUser: $message' : message;
      
      // Add query chunk and stream response
      await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));
      await for (final chunk in _chat!.generateChatResponseAsync()) {
        yield chunk;
      }
    } catch (e) {
      print('Local LLM streaming error: $e');
      throw Exception('Failed to get streaming response from local LLM: $e');
    }
  }

  // Set Google agreement acceptance
  static Future<void> setGoogleAgreementAccepted(bool accepted) async {
    _googleAgreementAccepted = accepted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_agreement_accepted', accepted);
  }

  // Set Hugging Face token
  static Future<void> setHuggingFaceToken(String? token) async {
    _huggingFaceToken = token;
    final prefs = await SharedPreferences.getInstance();
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
      await _chat?.session?.close();
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
      _isInitialized = false;
      _downloadProgress = 0.0;
      _downloadError = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_llm_model_path');
      
      _modelStatusController?.add(_modelStatus);
      print('Model deleted successfully');
    } catch (e) {
      print('Error deleting model: $e');
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
        'fileSizeGB': (ModelConfig.fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1),
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
      print('Cannot initialize model: not downloaded or path is null');
      return false;
    }
    
    await _initializeModel();
    return _isInitialized;
  }

  // Dispose resources
  static Future<void> dispose() async {
    try {
      await _chat?.session?.close();
      await _model?.close();
      _chat = null;
      _model = null;
      _isInitialized = false;
      _downloadProgressController?.close();
      _modelStatusController?.close();
      _downloadProgressController = null;
      _modelStatusController = null;
    } catch (e) {
      print('Dispose error: $e');
    }
  }
} 