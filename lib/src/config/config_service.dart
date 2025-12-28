import '../services/storage_service.dart';
import '../services/persisted_service.dart';
import 'app_config.dart';

/// FE-REFACTOR-12: Service to manage application configuration
///
/// Extends PersistedService to handle loading/saving config with consistent pattern.
class ConfigService extends PersistedService {
  AppConfig _config;

  ConfigService(super.storage) : _config = AppConfig.defaults();

  AppConfig get config => _config;

  bool get isConfigured => _config.hasApiKey;

  @override
  Future<void> loadPreferences() async {
    final savedConfig = await storage.loadConfig();
    if (savedConfig != null) {
      _config = AppConfig.fromJson(savedConfig);
    }
  }

  @override
  Future<void> savePreferences() async {
    // Only persist if "Remember API key" is enabled
    if (_config.rememberApiKey && _config.hasApiKey) {
      await storage.saveConfig(_config.toJson());
    } else {
      // Clear stored config if remember is disabled
      await storage.clearConfig();
    }
  }

  /// Update configuration
  Future<void> updateConfig(AppConfig newConfig) async {
    _config = newConfig;
    await saveAndNotify();
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

  @override
  Future<void> clearPersistedData() async {
    await storage.clearConfig();
  }

  /// Clear configuration
  Future<void> clearConfig() async {
    _config = AppConfig.defaults();
    await clearPersistedData();
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
