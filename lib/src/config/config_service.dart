import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import 'app_config.dart';

/// Service to manage application configuration
class ConfigService extends ChangeNotifier {
  final StorageService _storageService;
  AppConfig _config;

  ConfigService(this._storageService) : _config = AppConfig.defaults();

  AppConfig get config => _config;

  bool get isConfigured => _config.hasApiKey;

  /// Initialize and load saved configuration
  Future<void> initialize() async {
    final savedConfig = await _storageService.loadConfig();

    if (savedConfig != null) {
      _config = AppConfig.fromJson(savedConfig);
      notifyListeners();
    }
  }

  /// Update configuration
  Future<void> updateConfig(AppConfig newConfig) async {
    _config = newConfig;

    // Only persist if "Remember API key" is enabled
    if (newConfig.rememberApiKey && newConfig.hasApiKey) {
      await _storageService.saveConfig(newConfig.toJson());
    } else {
      // Clear stored config if remember is disabled
      await _storageService.clearConfig();
    }

    notifyListeners();
  }

  /// Update base URL only
  Future<void> updateBaseUrl(String baseUrl) async {
    await updateConfig(_config.copyWith(baseUrl: baseUrl));
  }

  /// Update API key only
  Future<void> updateApiKey(String apiKey, bool remember) async {
    await updateConfig(_config.copyWith(
      apiKey: apiKey,
      rememberApiKey: remember,
    ));
  }

  /// Clear configuration
  Future<void> clearConfig() async {
    _config = AppConfig.defaults();
    await _storageService.clearConfig();
    notifyListeners();
  }

  /// Clear API key but keep base URL
  Future<void> clearApiKey() async {
    await updateConfig(_config.copyWith(
      apiKey: null,
      rememberApiKey: false,
    ));
  }
}
