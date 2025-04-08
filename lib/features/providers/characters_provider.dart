import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';

class CharactersProvider with ChangeNotifier {
  static const String _storageKey = 'characters';

  List<CharacterModel> _characters = [];
  bool _isLoading = false;
  String? _selectedCharacterId;
  String? _lastError;

  List<CharacterModel> get characters => List.unmodifiable(_characters);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;

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
    _lastError = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final charactersJson = prefs.getStringList(_storageKey) ?? [];

      _characters =
          charactersJson
              .map((json) => CharacterModel.fromJson(jsonDecode(json)))
              .toList();

      _sortCharacters();
      _updateSelectedCharacter();
    } catch (e) {
      _lastError = 'Error loading characters: $e';
      _characters = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortCharacters() {
    _characters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _updateSelectedCharacter() {
    if (_characters.isNotEmpty && _selectedCharacterId == null) {
      _selectedCharacterId = _characters.first.id;
    } else if (_characters.isEmpty) {
      _selectedCharacterId = null;
    }
  }

  Future<void> _saveCharacters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final charactersJson =
          _characters.map((char) => jsonEncode(char.toJson())).toList();

      await prefs.setStringList(_storageKey, charactersJson);
      _lastError = null;
    } catch (e) {
      _lastError = 'Error saving characters: $e';
      rethrow;
    }
  }

  Future<void> addCharacter(CharacterModel character) async {
    try {
      _characters.add(character);
      _selectedCharacterId = character.id;
      await _saveCharacters();
      notifyListeners();
    } catch (e) {
      _lastError = 'Error adding character: $e';
      rethrow;
    }
  }

  Future<void> updateCharacter(CharacterModel updatedCharacter) async {
    try {
      final index = _characters.indexWhere(
        (char) => char.id == updatedCharacter.id,
      );

      if (index >= 0) {
        _characters[index] = updatedCharacter;
        await _saveCharacters();
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Error updating character: $e';
      rethrow;
    }
  }

  Future<void> deleteCharacter(String id) async {
    try {
      _characters.removeWhere((char) => char.id == id);
      _updateSelectedCharacter();
      await _saveCharacters();
      notifyListeners();
    } catch (e) {
      _lastError = 'Error deleting character: $e';
      rethrow;
    }
  }

  void selectCharacter(String id) {
    if (_characters.any((char) => char.id == id)) {
      _selectedCharacterId = id;
      notifyListeners();
    }
  }

  Future<void> addMessageToSelectedCharacter({
    required String text,
    required bool isUser,
  }) async {
    if (selectedCharacter == null) return;

    try {
      final updatedCharacter = selectedCharacter!.addMessage(
        text: text,
        isUser: isUser,
      );

      await updateCharacter(updatedCharacter);
    } catch (e) {
      _lastError = 'Error adding message: $e';
      rethrow;
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
