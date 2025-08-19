import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/local_llm_service.dart';
import 'dart:async';

class LocalLLMSettingsScreen extends StatefulWidget {
  const LocalLLMSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LocalLLMSettingsScreen> createState() => _LocalLLMSettingsScreenState();
}

class _LocalLLMSettingsScreenState extends State<LocalLLMSettingsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEnabled = false;
  LLMProvider _preferredProvider = LLMProvider.auto;
  
  // Model download state
  ModelDownloadStatus _modelStatus = ModelDownloadStatus.notDownloaded;
  double _downloadProgress = 0.0;
  String? _downloadError;
  
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
    _hfTokenController.dispose();
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
      final prefs = await SharedPreferences.getInstance();
      
      if (mounted) {
        setState(() {
          _modelStatus = ModelDownloadStatus.values.firstWhere(
            (e) => e.name == settings['modelStatus'],
            orElse: () => ModelDownloadStatus.notDownloaded,
          );
          _downloadProgress = settings['downloadProgress'] ?? 0.0;
          _downloadError = settings['downloadError'];
          _preferredProvider = LLMProvider.values[
            prefs.getInt('preferred_llm_provider') ?? LLMProvider.auto.index
          ];
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load settings: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await LocalLLMService.updateSettings({
        'enabled': _isEnabled,
      });
      
      await _savePreferredProvider();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local LLM settings saved successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save settings: $e';
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
            const SnackBar(content: Text('Model downloaded successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to download model. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to download model: $e';
        });
      }
    }
  }

  Future<void> _deleteModel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: const Text('Are you sure you want to delete the downloaded Hammer2.1 model? This will free up 1.6GB of storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
            const SnackBar(content: Text('Model deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to delete model: $e';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local AI Settings'),
        backgroundColor: AppTheme.midnightPurple,
        foregroundColor: AppTheme.silverMist,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body: _isLoading
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
                  _buildProviderSettings(),
                  const SizedBox(height: 16),
                  _buildDownloadSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildModelCard() {
    final status = LocalLLMService.getStatus();
    final isAvailable = status['isAvailable'] ?? false;
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
                    modelConfig['displayName'] ?? 'Hammer2.1-1.5b (CPU) 1.6Gb',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Status', _getStatusText(), _getStatusColor()),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Size',
              '${modelConfig['fileSizeGB'] ?? '1.6'} GB',
              Colors.grey[600],
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Supports Images',
              modelConfig['supportImage'] == true ? 'Yes' : 'No',
              Colors.grey[600],
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Max Tokens',
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
                'Downloading... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    switch (_modelStatus) {
      case ModelDownloadStatus.notDownloaded:
        return 'Not Downloaded';
      case ModelDownloadStatus.downloading:
        return 'Downloading...';
      case ModelDownloadStatus.downloaded:
        return 'Ready';
      case ModelDownloadStatus.error:
        return 'Error';
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

  Widget _buildProviderSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Provider Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Local AI'),
              subtitle: const Text('Use local AI when available'),
              value: _isEnabled,
              onChanged: _modelStatus == ModelDownloadStatus.downloaded
                  ? (value) {
                      if (mounted) {
                        setState(() {
                          _isEnabled = value;
                        });
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            const Text(
              'Preferred Provider',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<LLMProvider>(
              value: _preferredProvider,
              isExpanded: true,
              items: LLMProvider.values.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(HybridChatService.getProviderDisplayName(provider)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && mounted) {
                  setState(() {
                    _preferredProvider = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection() {
    if (_modelStatus == ModelDownloadStatus.downloaded) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Model Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('The Gemma 3n model is ready to use!'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _deleteModel,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Model'),
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
            const Text(
              'Download Model',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('To use local AI, download the Gemma 3n (AI Edge) model:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            const Text('This model requires accepting Google’s license and using a Hugging Face access token.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => launchUrlString('https://huggingface.co/google/gemma-3n-E2B-it-litert-preview', mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open License Page'),
                ),
                TextButton.icon(
                  onPressed: () => launchUrlString('https://huggingface.co/settings/tokens', mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Open HF Tokens'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('• Hammer2.1 is an open-source model (no authentication required)'),
            const Text('• 1.6GB of free storage space needed'),
            const Text('• Runs locally on your device for privacy'),
            const Text('• Optimized for mobile devices with fast inference'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _modelStatus == ModelDownloadStatus.downloading
                  ? Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            LocalLLMService.stopDownload();
                            if (mounted) {
                              setState(() {
                                _modelStatus = ModelDownloadStatus.error;
                                _downloadError = 'Download cancelled by user';
                              });
                            }
                          },
                          icon: const Icon(Icons.stop),
                          label: const Text('Cancel Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Downloading... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _downloadModel,
                      icon: const Icon(Icons.download),
                      label: const Text('Download Hammer2.1 Model (1.6GB)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.midnightPurple,
                        foregroundColor: AppTheme.silverMist,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
