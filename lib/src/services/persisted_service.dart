import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// FE-REFACTOR-12: Base class for services that persist state to storage
///
/// This base class provides a common pattern for services that:
/// 1. Extend ChangeNotifier for state management
/// 2. Use StorageService for persistence
/// 3. Load preferences on initialization
/// 4. Save preferences when state changes
///
/// Usage:
/// ```dart
/// class MyService extends PersistedService {
///   MyService(super.storageService);
///
///   @override
///   Future<void> loadPreferences() async {
///     final value = await storage.read('my_key');
///     // Update state...
///   }
///
///   @override
///   Future<void> savePreferences() async {
///     await storage.write('my_key', myValue);
///   }
///
///   Future<void> updateMyValue(String newValue) async {
///     myValue = newValue;
///     await saveAndNotify();
///   }
/// }
/// ```
abstract class PersistedService extends ChangeNotifier {
  /// Storage service for persistence
  @protected
  final StorageService storage;

  /// Whether the service has been initialized
  bool _initialized = false;

  bool get initialized => _initialized;

  PersistedService(this.storage);

  /// Initialize the service by loading preferences
  ///
  /// Call this method in the constructor or from a provider initializer.
  /// Subclasses should not override this - override [loadPreferences] instead.
  @mustCallSuper
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await loadPreferences();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ${runtimeType}: $e');
      rethrow;
    }
  }

  /// Load preferences from storage
  ///
  /// Override this method to load your service's state from storage.
  /// Use [storage.read()] or [storage.loadConfig()] to read values.
  /// Errors will be caught by [initialize].
  @protected
  Future<void> loadPreferences();

  /// Save preferences to storage
  ///
  /// Override this method to persist your service's state to storage.
  /// Use [storage.write()] or [storage.saveConfig()] to save values.
  /// Errors will be caught and logged by [saveAndNotify].
  @protected
  Future<void> savePreferences();

  /// Save preferences and notify listeners
  ///
  /// Call this method after updating state to persist changes and trigger UI updates.
  /// Errors during save are logged but don't prevent notification.
  @protected
  Future<void> saveAndNotify() async {
    try {
      await savePreferences();
    } catch (e) {
      debugPrint('Error saving ${runtimeType} preferences: $e');
    }
    notifyListeners();
  }

  /// Clear all persisted data
  ///
  /// Override this to define how to clear service-specific storage.
  /// Default implementation does nothing - subclasses should implement.
  @protected
  Future<void> clearPersistedData() async {
    // Override in subclasses
  }
}
