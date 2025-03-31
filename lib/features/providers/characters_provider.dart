import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';

class CharactersProvider with ChangeNotifier {
  List<CharacterModel> _characters = [];
  bool _isLoading = false;
  String? _selectedCharacterId;

  List<CharacterModel> get characters => _characters;
  bool get isLoading => _isLoading;

  CharacterModel? get selectedCharacter {
    if (_selectedCharacterId == null) {
      return _characters.isNotEmpty ? _characters.first : null;
    }

    try {
      return _characters.firstWhere((char) => char.id == _selectedCharacterId);
    } catch (_) {
      return _characters.isNotEmpty ? _characters.first : null;
    }
  }

  CharactersProvider() {
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final charactersJson = prefs.getStringList('characters') ?? [];

      _characters =
          charactersJson
              .map((json) => CharacterModel.fromJson(jsonDecode(json)))
              .toList();

      // Sort by most recently created
      _characters.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Select first character if available and none selected
      if (_characters.isNotEmpty && _selectedCharacterId == null) {
        _selectedCharacterId = _characters.first.id;
      }
    } catch (e) {
      print('Error loading characters: $e');
      _characters = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCharacters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final charactersJson =
          _characters.map((char) => jsonEncode(char.toJson())).toList();

      await prefs.setStringList('characters', charactersJson);
    } catch (e) {
      print('Error saving characters: $e');
    }
  }

  Future<void> addCharacter(CharacterModel character) async {
    _characters.add(character);
    _selectedCharacterId = character.id;
    notifyListeners();
    await _saveCharacters();
  }

  Future<void> updateCharacter(CharacterModel updatedCharacter) async {
    final index = _characters.indexWhere(
      (char) => char.id == updatedCharacter.id,
    );

    if (index >= 0) {
      _characters[index] = updatedCharacter;
      notifyListeners();
      await _saveCharacters();
    }
  }

  Future<void> deleteCharacter(String id) async {
    _characters.removeWhere((char) => char.id == id);

    // If we deleted the selected character, select the first one
    if (_selectedCharacterId == id && _characters.isNotEmpty) {
      _selectedCharacterId = _characters.first.id;
    } else if (_characters.isEmpty) {
      _selectedCharacterId = null;
    }

    notifyListeners();
    await _saveCharacters();
  }

  void selectCharacter(String id) {
    _selectedCharacterId = id;
    notifyListeners();
  }

  Future<void> addMessageToSelectedCharacter({
    required String text,
    required bool isUser,
  }) async {
    if (selectedCharacter == null) return;

    final updatedCharacter = selectedCharacter!.addMessage(
      text: text,
      isUser: isUser,
    );

    await updateCharacter(updatedCharacter);
  }
}
