import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afterlife/features/models/character_model.dart';

/// Service for storing and retrieving character data
class CharacterStorage {
  static const String _charactersKey = 'characters';

  /// Get all saved characters
  static Future<List<CharacterModel>> getCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    final charactersJson = prefs.getStringList(_charactersKey) ?? [];

    return charactersJson
        .map((json) => CharacterModel.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Get a specific character by ID
  static Future<CharacterModel?> getCharacter(String id) async {
    final characters = await getCharacters();
    return characters.firstWhere(
      (character) => character.id == id,
      orElse: () => throw Exception('Character not found'),
    );
  }

  /// Save a character
  static Future<void> saveCharacter(CharacterModel character) async {
    final prefs = await SharedPreferences.getInstance();
    final characters = await getCharacters();

    // Update existing or add new
    final index = characters.indexWhere((c) => c.id == character.id);
    if (index >= 0) {
      characters[index] = character;
    } else {
      characters.add(character);
    }

    // Save back to prefs
    await prefs.setStringList(
      _charactersKey,
      characters.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  /// Delete a character
  static Future<void> deleteCharacter(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final characters = await getCharacters();

    characters.removeWhere((c) => c.id == id);

    // Save back to prefs
    await prefs.setStringList(
      _charactersKey,
      characters.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }
}
