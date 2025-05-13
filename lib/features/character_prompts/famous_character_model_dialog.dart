import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'famous_character_prompts.dart';

class FamousCharacterModelDialog extends StatefulWidget {
  final String characterName;

  const FamousCharacterModelDialog({Key? key, required this.characterName})
    : super(key: key);

  static Future<String?> show(
    BuildContext context, {
    required String characterName,
  }) async {
    return await showDialog<String>(
      context: context,
      builder:
          (context) => FamousCharacterModelDialog(characterName: characterName),
    );
  }

  @override
  State<FamousCharacterModelDialog> createState() =>
      _FamousCharacterModelDialogState();
}

class _FamousCharacterModelDialogState
    extends State<FamousCharacterModelDialog> {
  late String _selectedModel;
  late List<Map<String, dynamic>> _availableModels;

  @override
  void initState() {
    super.initState();
    _availableModels = FamousCharacterPrompts.getModelsForCharacter(
      widget.characterName,
    );
    _selectedModel = FamousCharacterPrompts.getSelectedModel(
      widget.characterName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.deepIndigo,
      title: Text(
        'Select AI Model for ${widget.characterName}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose the AI model that will power ${widget.characterName}:',
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
                    margin: const EdgeInsets.only(bottom: 12),
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
                          _selectedModel = model['id'] as String;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: model['id'] as String,
                              groupValue: _selectedModel,
                              onChanged: (value) {
                                setState(() {
                                  _selectedModel = value!;
                                });
                              },
                              activeColor: AppTheme.warmGold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        model['name'] as String,
                                        style: const TextStyle(
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
                                          child: const Text(
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
                                  const SizedBox(height: 6),
                                  Text(
                                    model['description'] as String,
                                    style: const TextStyle(
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
          child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            // Save the selected model
            FamousCharacterPrompts.setSelectedModel(
              widget.characterName,
              _selectedModel,
            );
            Navigator.of(context).pop(_selectedModel);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warmGold,
            foregroundColor: Colors.black,
          ),
          child: const Text('SELECT'),
        ),
      ],
    );
  }
}
