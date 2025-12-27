import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;

/// Platform-aware storage service
/// - Android: Uses flutter_secure_storage
/// - Web/Desktop: Uses in-memory storage
class StorageService {
  static const String _configKey = 'app_config';

  // Secure storage for Android
  final FlutterSecureStorage? _secureStorage;

  // In-memory storage for Web/Desktop
  final Map<String, String> _memoryStorage = {};

  StorageService()
      : _secureStorage = _shouldUseSecureStorage()
            ? const FlutterSecureStorage(
                aOptions: AndroidOptions(
                  encryptedSharedPreferences: true,
                ),
              )
            : null;

  static bool _shouldUseSecureStorage() {
    // Use secure storage only on Android
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  bool get isUsingSecureStorage => _secureStorage != null;

  Future<void> saveConfig(Map<String, dynamic> config) async {
    final jsonString = jsonEncode(config);

    if (_secureStorage != null) {
      // Android: Use secure storage
      await _secureStorage!.write(key: _configKey, value: jsonString);
    } else {
      // Web/Desktop: Use in-memory storage
      _memoryStorage[_configKey] = jsonString;
    }
  }

  Future<Map<String, dynamic>?> loadConfig() async {
    String? jsonString;

    if (_secureStorage != null) {
      // Android: Load from secure storage
      jsonString = await _secureStorage!.read(key: _configKey);
    } else {
      // Web/Desktop: Load from in-memory storage
      jsonString = _memoryStorage[_configKey];
    }

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearConfig() async {
    if (_secureStorage != null) {
      await _secureStorage!.delete(key: _configKey);
    } else {
      _memoryStorage.remove(_configKey);
    }
  }

  Future<void> clearAll() async {
    if (_secureStorage != null) {
      await _secureStorage!.deleteAll();
    } else {
      _memoryStorage.clear();
    }
  }
}
