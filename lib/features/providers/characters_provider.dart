import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';
import '../../core/providers/base_provider.dart';

class CharactersProvider extends BaseProvider {
  static const String _storageKey = 'characters';

  // Cache for shared preferences to avoid repeated access
  SharedPreferences? _prefsCache;

  List<CharacterModel> _characters = [];
  String? _selectedCharacterId;

  // Memory cache for characters by ID for faster lookups
  final Map<String, CharacterModel> _characterCache = {};

  List<CharacterModel> get characters => List.unmodifiable(_characters);

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
    await executeWithState(
      operation: () async {
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
            setError('Error parsing characters: $e', error: e);
            _characters = [];
          }
        }

        _sortCharacters();
        _updateSelectedCharacter();
      },
      operationName: 'load characters',
    );
  }

  // Parse character JSON in an isolate for better performance
  static List<CharacterModel> _parseCharactersJson(
    List<String> charactersJson,
  ) {
    return charactersJson.map((json) {
      // Explicitly decode as UTF-8 to preserve Ukrainian characters
      final jsonBytes = utf8.encode(json);
      final decodedJson = utf8.decode(jsonBytes);
      final decoded = jsonDecode(decodedJson);
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
      clearError();
    } catch (e) {
      setError('Error saving characters: $e', error: e);
      rethrow;
    }
  }

  // Encode character JSON in an isolate for better performance
  static List<String> _encodeCharactersJson(List<CharacterModel> characters) {
    return characters.map((char) {
      // Explicitly encode to UTF-8 to preserve Ukrainian characters
      final jsonString = jsonEncode(char.toJson());
      final jsonBytes = utf8.encode(jsonString);
      return utf8.decode(jsonBytes);
    }).toList();
  }

  Future<void> addCharacter(CharacterModel character) async {
    try {
      _characters.add(character);
      await _saveCharacters();
      notifyListeners();
    } catch (e) {
      setError('Error adding character: $e', error: e);
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
      setError('Error updating character: $e', error: e);
      rethrow;
    }
  }

  // Update a specific field of a character by ID
  Future<void> updateCharacterField({
    required String characterId,
    required String field,
    required dynamic value,
  }) async {
    try {
      final index = _characters.indexWhere((char) => char.id == characterId);

      if (index < 0) {
        throw Exception('Character not found');
      }

      // Get a copy of the character to modify
      final character = _characters[index];

      // Create a new JSON representation
      final json = character.toJson();

      // Update the specific field
      json[field] = value;

      // Create an updated character model
      final updatedCharacter = CharacterModel.fromJson(json);

      // Update the character
      _characters[index] = updatedCharacter;
      _characterCache[characterId] = updatedCharacter;

      await _saveCharacters();
      notifyListeners();
    } catch (e) {
      setError('Error updating character field: $e', error: e);
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
      setError('Error deleting character: $e', error: e);
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
      setError('Error adding message: $e', error: e);
      rethrow;
    }
  }

  // Add messages to a specific character by ID
  Future<void> addMessageToCharacter({
    required String characterId,
    required String text,
    required bool isUser,
  }) async {
    try {
      // Find the character by ID
      final characterIndex = _characters.indexWhere(
        (char) => char.id == characterId,
      );
      if (characterIndex == -1) {
        throw Exception('Character with ID $characterId not found');
      }

      final character = _characters[characterIndex];
      final updatedCharacter = character.addMessage(text: text, isUser: isUser);

      // Update the character in the list
      _characters[characterIndex] = updatedCharacter;

      // Update the cache directly for immediate access
      _characterCache[updatedCharacter.id] = updatedCharacter;

      await _saveCharacters();
      notifyListeners();
    } catch (e) {
      setError('Error adding message to character: $e', error: e);
      rethrow;
    }
  }

  // This method is now inherited from BaseProvider
  // void clearError() is already available

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

      clearError();
      notifyListeners();
    } catch (e) {
      setError('Error clearing all data: $e', error: e);
      rethrow;
    }
  }

  @override
  void dispose() {
    // Clear caches to prevent memory leaks
    _characterCache.clear();
    _prefsCache = null;
    _characters.clear();
    _selectedCharacterId = null;
    super.dispose();
  }
}
