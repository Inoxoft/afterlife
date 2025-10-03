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
        
      }
      // Try to load from backup
      return await _loadFromBackup();
    }
  }
  
  /// Save all group chats to storage
  static Future<void> saveGroupChats(List<GroupChatModel> groupChats) async {
    
    
    try {
      
      final jsonList = groupChats.map((group) {
        
        return group.toJson();
      }).toList();
      
      
      
      final jsonString = jsonEncode(jsonList);
      
      
      // Check size limit
      if (jsonString.length > _maxStorageSize) {
        
        throw Exception('Group chats data exceeds storage limit');
      }
      
      
      final prefs = await SharedPreferences.getInstance();
      
      
      
      await prefs.setString(_storageKey, jsonString);
      
      
      // Create backup periodically
      
      await _createBackupIfNeeded(jsonString);
      
      
      
    } catch (e) {
      
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
        
      }
    } catch (e) {
      if (kDebugMode) {
        
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
        
      }
    } catch (e) {
      if (kDebugMode) {
        
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
          
        }
      }
    } catch (e) {
      if (kDebugMode) {
        
      }
      // Don't rethrow - backup failure shouldn't fail main operation
    }
  }
}