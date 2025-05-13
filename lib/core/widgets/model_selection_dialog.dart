import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModelSelectionDialog extends StatefulWidget {
  final String currentModel;
  final Function(String) onModelSelected;

  const ModelSelectionDialog({
    Key? key,
    required this.currentModel,
    required this.onModelSelected,
  }) : super(key: key);

  static Future<String?> show(
    BuildContext context, {
    required String currentModel,
  }) async {
    return await showDialog<String>(
      context: context,
      builder:
          (context) => ModelSelectionDialog(
            currentModel: currentModel,
            onModelSelected: (model) {
              Navigator.of(context).pop(model);
            },
          ),
    );
  }

  @override
  State<ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends State<ModelSelectionDialog> {
  late String _selectedModel;

  // List of available models
  // You can expand this list as needed
  final List<Map<String, dynamic>> _availableModels = [
    {
      'id': 'google/gemini-2.0-flash-001',
      'name': 'Gemini 2.0 Flash',
      'provider': 'Google',
      'description':
          'Fast responses with good quality, ideal for most conversations.',
      'recommended': true,
    },
    {
      'id': 'anthropic/claude-3-5-sonnet',
      'name': 'Claude 3.5 Sonnet',
      'provider': 'Anthropic',
      'description': 'High quality responses with strong reasoning abilities.',
      'recommended': true,
    },
    {
      'id': 'google/gemini-2.0-pro-001',
      'name': 'Gemini 2.0 Pro',
      'provider': 'Google',
      'description': 'Higher quality responses, but may be slower than Flash.',
      'recommended': false,
    },
    {
      'id': 'anthropic/claude-3-opus',
      'name': 'Claude 3 Opus',
      'provider': 'Anthropic',
      'description': 'Top-tier intelligence, but slower and more expensive.',
      'recommended': false,
    },
    {
      'id': 'meta-llama/llama-3-70b-instruct',
      'name': 'Llama 3 70B',
      'provider': 'Meta',
      'description': 'Open-source model with good all-around capabilities.',
      'recommended': false,
    },
    {
      'id': 'openai/gpt-4o',
      'name': 'GPT-4o',
      'provider': 'OpenAI',
      'description': 'Powerful model with excellent language understanding.',
      'recommended': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.currentModel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.deepIndigo,
      title: Text(
        'Select AI Model',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose the AI model that will power this character:',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableModels.length,
                itemBuilder: (context, index) {
                  final model = _availableModels[index];
                  final isSelected = model['id'] == _selectedModel;

                  return Card(
                    color:
                        isSelected
                            ? AppTheme.warmGold.withOpacity(0.2)
                            : AppTheme.backgroundEnd.withOpacity(0.3),
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            isSelected ? AppTheme.warmGold : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedModel = model['id'];
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: model['id'],
                              groupValue: _selectedModel,
                              onChanged: (value) {
                                setState(() {
                                  _selectedModel = value!;
                                });
                              },
                              activeColor: AppTheme.warmGold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        model['name'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (model['recommended'] == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warmGold
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'RECOMMENDED',
                                            style: TextStyle(
                                              color: AppTheme.warmGold,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'by ${model['provider']}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    model['description'],
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CANCEL', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onModelSelected(_selectedModel);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warmGold),
          child: Text('SELECT', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}
