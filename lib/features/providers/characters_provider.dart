import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';

class CharactersProvider with ChangeNotifier {
  static const String _storageKey = 'characters';

  // Cache for shared preferences to avoid repeated access
  SharedPreferences? _prefsCache;

  List<CharacterModel> _characters = [];
  bool _isLoading = false;
  String? _selectedCharacterId;
  String? _lastError;

  // Memory cache for characters by ID for faster lookups
  final Map<String, CharacterModel> _characterCache = {};

  List<CharacterModel> get characters => List.unmodifiable(_characters);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;

  CharacterModel? get selectedCharacter {
    if (_selectedCharacterId == null) {
      return _characters.isNotEmpty ? _characters.first : null;
    }

    // Check the cache first for faster lookup
    if (_characterCache.containsKey(_selectedCharacterId)) {
      return _characterCache[_selectedCharacterId];
    }

    // If not in cache, look in the main list
    try {
      final character = _characters.firstWhere(
        (char) => char.id == _selectedCharacterId,
      );

      // Update cache
      _characterCache[_selectedCharacterId!] = character;
      return character;
    } catch (_) {
      return _characters.isNotEmpty ? _characters.first : null;
    }
  }

  CharactersProvider() {
    _loadCharacters();
  }

  // Get shared preferences instance with caching
  Future<SharedPreferences> _getPrefs() async {
    if (_prefsCache != null) {
      return _prefsCache!;
    }
    _prefsCache = await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  Future<void> _loadCharacters() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final prefs = await _getPrefs();
      final charactersJson = prefs.getStringList(_storageKey) ?? [];

      if (charactersJson.isEmpty) {
        _characters = [];
      } else {
        try {
          _characters = await compute(_parseCharactersJson, charactersJson);

          // Update cache
          _characterCache.clear();
          for (var char in _characters) {
            _characterCache[char.id] = char;
          }
        } catch (e) {
          _lastError = 'Error parsing characters: $e';
          _characters = [];
        }
      }

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

  // Parse character JSON in an isolate for better performance
  static List<CharacterModel> _parseCharactersJson(
    List<String> charactersJson,
  ) {
    return charactersJson.map((json) {
      final decoded = jsonDecode(json);
      return CharacterModel.fromJson(decoded);
    }).toList();
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
      final prefs = await _getPrefs();

      // Encode in an isolate for better performance with large data
      final charactersJson = await compute(_encodeCharactersJson, _characters);

      // First clear existing data
      await prefs.remove(_storageKey);

      // Then save the new list
      await prefs.setStringList(_storageKey, charactersJson);
      _lastError = null;
    } catch (e) {
      _lastError = 'Error saving characters: $e';
      rethrow;
    }
  }

  // Encode character JSON in an isolate for better performance
  static List<String> _encodeCharactersJson(List<CharacterModel> characters) {
    return characters.map((char) => jsonEncode(char.toJson())).toList();
  }

  Future<void> addCharacter(CharacterModel character) async {
    try {
      _characters.add(character);
      _characterCache[character.id] = character;
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
        _characterCache[updatedCharacter.id] = updatedCharacter;
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
      _characterCache.remove(id);
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

      // Update the cache directly for immediate access
      _characterCache[updatedCharacter.id] = updatedCharacter;

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

  Future<CharacterModel?> loadCharacterById(String id) async {
    try {
      // Check the memory cache first for fastest access
      if (_characterCache.containsKey(id)) {
        return _characterCache[id];
      }

      // If not in cache, look in the main list
      if (_characters.isNotEmpty) {
        try {
          final existingChar = _characters.firstWhere((c) => c.id == id);
          _characterCache[id] = existingChar;
          return existingChar;
        } catch (_) {
          // Character not found in memory, continue to storage
        }
      }

      // Try to load from storage if not in memory
      final prefs = await _getPrefs();
      final charactersJson = prefs.getStringList(_storageKey) ?? [];

      if (charactersJson.isEmpty) {
        return null;
      }

      // Try to find the character in storage
      for (var json in charactersJson) {
        try {
          final charData = CharacterModel.fromJson(jsonDecode(json));
          if (charData.id == id) {
            // Add to in-memory cache and list if not already there
            if (!_characters.any((c) => c.id == id)) {
              _characters.add(charData);
              _characterCache[id] = charData;
              notifyListeners();
            }

            return charData;
          }
        } catch (e) {
          // Skip invalid entries
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Public method to reload characters
  Future<void> reloadCharacters() async {
    await _loadCharacters();
  }

  // Batch update multiple characters at once for better performance
  Future<void> batchUpdateCharacters(
    List<CharacterModel> updatedCharacters,
  ) async {
    if (updatedCharacters.isEmpty) return;

    for (var updatedChar in updatedCharacters) {
      final index = _characters.indexWhere((char) => char.id == updatedChar.id);
      if (index >= 0) {
        _characters[index] = updatedChar;
        _characterCache[updatedChar.id] = updatedChar;
      } else {
        _characters.add(updatedChar);
        _characterCache[updatedChar.id] = updatedChar;
      }
    }

    await _saveCharacters();
    notifyListeners();
  }

  // Clear all characters and data
  Future<void> clearAll() async {
    try {
      // Clear in-memory data
      _characters.clear();
      _characterCache.clear();
      _selectedCharacterId = null;

      // Clear stored data
      final prefs = await _getPrefs();
      await prefs.remove(_storageKey);

      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = 'Error clearing all data: $e';
      rethrow;
    }
  }
}
