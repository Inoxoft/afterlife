import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher_string.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/local_llm_service.dart';
import 'dart:async';
import '../../core/widgets/adaptive_text.dart';
import '../../l10n/app_localizations.dart';

class LocalLLMSettingsScreen extends StatefulWidget {
  const LocalLLMSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LocalLLMSettingsScreen> createState() => _LocalLLMSettingsScreenState();
}

class _LocalLLMSettingsScreenState extends State<LocalLLMSettingsScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Model download state
  ModelDownloadStatus _modelStatus = ModelDownloadStatus.notDownloaded;
  double _downloadProgress = 0.0;
  // Optional error detail; displayed via snackbars elsewhere
  // ignore: unused_field
  String? _downloadError;

  // Token UI removed; download uses embedded token

  // Stream subscriptions
  StreamSubscription<double>? _progressSubscription;
  StreamSubscription<ModelDownloadStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupStreamListeners();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _statusSubscription?.cancel();
    // No token controller to dispose
    super.dispose();
  }

  void _setupStreamListeners() {
    // Listen to download progress
    _progressSubscription = LocalLLMService.downloadProgressStream.listen((
      progress,
    ) {
      if (mounted) {
        setState(() {
          _downloadProgress = progress;
        });
      }
    });

    // Listen to model status changes
    _statusSubscription = LocalLLMService.modelStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _modelStatus = status;
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final settings = LocalLLMService.getSettings();

      if (mounted) {
        setState(() {
          _modelStatus = ModelDownloadStatus.values.firstWhere(
            (e) => e.name == settings['modelStatus'],
            orElse: () => ModelDownloadStatus.notDownloaded,
          );
          _downloadProgress = settings['downloadProgress'] ?? 0.0;
          _downloadError = settings['downloadError'];
          // Token UI removed

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).failedToLoadSettings(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  // Token UI removed

  Future<void> _saveSettings() async {
    try {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).localLlmSettingsSaved),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).failedToSaveSettingsWithDetails(e.toString());
        });
      }
    }
  }

  Future<void> _downloadModel() async {
    try {
      // Don't set global loading state - just handle download progress
      setState(() {
        _errorMessage = null;
      });

      final success = await LocalLLMService.downloadModel(
        acceptGoogleAgreement: true, // Always true for Hammer2.1
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).modelDownloadedSuccessfully)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).modelDownloadFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).failedToDownloadModel(e.toString());
        });
      }
    }
  }

  Future<void> _deleteModel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).deleteModel),
            content: Text(
              AppLocalizations.of(context).deleteModelConfirmation,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await LocalLLMService.deleteModel();
        if (mounted) {
          setState(() {
            _modelStatus = ModelDownloadStatus.notDownloaded;
            _downloadProgress = 0.0;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).modelDeletedSuccessfully)),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = AppLocalizations.of(context).failedToDeleteModel(e.toString());
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).localAiSettings),
        backgroundColor: AppTheme.midnightPurple,
        foregroundColor: AppTheme.silverMist,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildModelCard(),
                    const SizedBox(height: 16),
                    // Token section removed
                    const SizedBox(height: 16),
                    _buildDownloadSection(),
                  ],
                ),
              ),
    );
  }

  // Token section removed

  Widget _buildModelCard() {
    // Read settings to ensure up-to-date info if needed later
    final settings = LocalLLMService.getSettings();
    final modelConfig = settings['modelConfig'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    modelConfig['displayName'] ?? 'Gemma 3 1B IT (Local)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow(AppLocalizations.of(context).status, _getStatusText(), _getStatusColor()),
            const SizedBox(height: 8),
            _buildStatusRow(
              AppLocalizations.of(context).size,
              '${modelConfig['fileSizeGB'] ?? '1.6'} GB',
              Colors.grey[600],
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              AppLocalizations.of(context).supportsImages,
              modelConfig['supportImage'] == true ? AppLocalizations.of(context).yes : AppLocalizations.of(context).no,
              Colors.grey[600],
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              AppLocalizations.of(context).maxTokens,
              '${modelConfig['maxTokens'] ?? '1024'}',
              Colors.grey[600],
            ),
            if (_modelStatus == ModelDownloadStatus.downloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.midnightPurple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.of(context).downloadingProgress} ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color? color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: color ?? Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    switch (_modelStatus) {
      case ModelDownloadStatus.notDownloaded:
        return AppLocalizations.of(context).notDownloaded;
      case ModelDownloadStatus.downloading:
        return AppLocalizations.of(context).downloading;
      case ModelDownloadStatus.downloaded:
        return AppLocalizations.of(context).ready;
      case ModelDownloadStatus.error:
        return AppLocalizations.of(context).error;
    }
  }

  Color? _getStatusColor() {
    switch (_modelStatus) {
      case ModelDownloadStatus.notDownloaded:
        return Colors.orange;
      case ModelDownloadStatus.downloading:
        return Colors.blue;
      case ModelDownloadStatus.downloaded:
        return Colors.green;
      case ModelDownloadStatus.error:
        return Colors.red;
    }
  }

  // Removed AI Provider Settings: provider always Auto (smart selection)

  Widget _buildDownloadSection() {
    if (_modelStatus == ModelDownloadStatus.downloaded) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).modelManagement,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).gemmaModelReady),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _deleteModel,
                icon: const Icon(Icons.delete),
                label: Text(AppLocalizations.of(context).deleteModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).downloadModelSection,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).downloadGemmaModel, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).storageSpaceNeeded),
            Text(AppLocalizations.of(context).runsLocallyPrivacy),
            Text(AppLocalizations.of(context).optimizedMobileInference),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child:
                  _modelStatus == ModelDownloadStatus.downloading
                      ? Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              LocalLLMService.stopDownload();
                              if (mounted) {
                                setState(() {
                                  _modelStatus = ModelDownloadStatus.error;
                                  _downloadError = AppLocalizations.of(context).downloadCancelledByUser;
                                });
                              }
                            },
                            icon: const Icon(Icons.stop),
                            label: Text(AppLocalizations.of(context).cancelDownload),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${AppLocalizations.of(context).downloadingProgress} ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                      : ElevatedButton(
                        onPressed: _downloadModel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.midnightPurple,
                          foregroundColor: AppTheme.silverMist,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Icon(Icons.download),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AdaptiveText(
                                text: AppLocalizations.of(context).downloadGemmaModelButton,
                                baseStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxFontSize: 16,
                                minFontSize: 12,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}