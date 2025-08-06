import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_chat_model.dart';

/// Storage service for persisting group chat data using SharedPreferences
class GroupChatStorage {
  static const String _storageKey = 'group_chats_v1';
  static const String _backupKey = 'group_chats_backup_v1';
  static const String _lastBackupKey = 'last_backup_timestamp';
  
  // Configuration
  static const int _maxStorageSize = 50 * 1024 * 1024; // 50MB limit
  static const Duration _backupInterval = Duration(hours: 24);
  
  /// Load all group chats from storage
  static Future<List<GroupChatModel>> loadGroupChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      // Use isolate for JSON parsing if data is large
      if (jsonString.length > 100000) {
        return await _parseJsonInIsolate(jsonString);
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => GroupChatModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading group chats: $e');
      }
      // Try to load from backup
      return await _loadFromBackup();
    }
  }
  
  /// Save all group chats to storage
  static Future<void> saveGroupChats(List<GroupChatModel> groupChats) async {
    print('🔧 [GroupChatStorage] saveGroupChats called with ${groupChats.length} groups');
    
    try {
      print('🔧 [GroupChatStorage] Converting groups to JSON...');
      final jsonList = groupChats.map((group) {
        print('🔧 [GroupChatStorage] Converting group: ${group.id} (${group.name})');
        return group.toJson();
      }).toList();
      print('✅ [GroupChatStorage] JSON conversion completed');
      
      print('🔧 [GroupChatStorage] Encoding JSON string...');
      final jsonString = jsonEncode(jsonList);
      print('🔧 [GroupChatStorage] JSON string size: ${jsonString.length} bytes');
      
      // Check size limit
      if (jsonString.length > _maxStorageSize) {
        print('❌ [GroupChatStorage] Data size exceeds limit: ${jsonString.length} > $_maxStorageSize');
        throw Exception('Group chats data exceeds storage limit');
      }
      
      print('🔧 [GroupChatStorage] Getting SharedPreferences instance...');
      final prefs = await SharedPreferences.getInstance();
      print('✅ [GroupChatStorage] SharedPreferences obtained');
      
      print('🔧 [GroupChatStorage] Saving to key: $_storageKey');
      await prefs.setString(_storageKey, jsonString);
      print('✅ [GroupChatStorage] Data saved to SharedPreferences');
      
      // Create backup periodically
      print('🔧 [GroupChatStorage] Creating backup if needed...');
      await _createBackupIfNeeded(jsonString);
      print('✅ [GroupChatStorage] Backup process completed');
      
      print('✅ [GroupChatStorage] Successfully saved ${groupChats.length} group chats');
    } catch (e, stackTrace) {
      print('❌ [GroupChatStorage] Error saving group chats: $e');
      print('❌ [GroupChatStorage] Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Delete a specific group chat
  static Future<void> deleteGroupChat(String groupId) async {
    try {
      final groupChats = await loadGroupChats();
      final updatedChats = groupChats.where((g) => g.id != groupId).toList();
      await saveGroupChats(updatedChats);
      
      if (kDebugMode) {
        print('GroupChatStorage: Deleted group $groupId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting group chat: $e');
      }
      rethrow;
    }
  }
  
  /// Clear all group chats
  static Future<void> clearAllGroupChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_backupKey);
      
      if (kDebugMode) {
        print('GroupChatStorage: Cleared all group chats');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing group chats: $e');
      }
      rethrow;
    }
  }
  
  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey) ?? '';
      final backupString = prefs.getString(_backupKey) ?? '';
      
      return {
        'totalSize': jsonString.length,
        'backupSize': backupString.length,
        'groupCount': jsonString.isEmpty ? 0 : (jsonDecode(jsonString) as List).length,
        'lastBackup': prefs.getInt(_lastBackupKey),
      };
    } catch (e) {
      return {
        'totalSize': 0,
        'backupSize': 0,
        'groupCount': 0,
        'lastBackup': null,
        'error': e.toString(),
      };
    }
  }
  
  // Private helper methods
  
  static Future<List<GroupChatModel>> _parseJsonInIsolate(String jsonString) async {
    try {
      final result = await Isolate.run(() {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => GroupChatModel.fromJson(json)).toList();
      });
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing JSON in isolate: $e');
      }
      // Fallback to main thread
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => GroupChatModel.fromJson(json)).toList();
    }
  }
  
  static Future<List<GroupChatModel>> _loadFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupString = prefs.getString(_backupKey);
      
      if (backupString == null || backupString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(backupString);
      return jsonList.map((json) => GroupChatModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading from backup: $e');
      }
      return [];
    }
  }
  
  static Future<void> _createBackupIfNeeded(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackup = prefs.getInt(_lastBackupKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - lastBackup > _backupInterval.inMilliseconds) {
        await prefs.setString(_backupKey, jsonString);
        await prefs.setInt(_lastBackupKey, now);
        
        if (kDebugMode) {
          print('GroupChatStorage: Created backup');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating backup: $e');
      }
      // Don't rethrow - backup failure shouldn't fail main operation
    }
  }
}