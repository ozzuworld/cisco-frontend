import 'package:flutter/foundation.dart';
import 'profile.dart';

/// Represents the current step in the log collection flow
enum CollectionStep {
  /// Initial state - no cluster discovered yet
  initial,

  /// Cluster discovered, waiting for node selection
  clusterDiscovered,

  /// At least one node selected
  nodesSelected,

  /// Profile selected
  profileSelected,

  /// Time configuration completed (valid)
  timeConfigured,

  /// All requirements met, ready to start collection
  ready,
}

/// Manages the state of the collection flow
/// This is the single source of truth for tracking user progress
class CollectionFlowState extends ChangeNotifier {
  CollectionStep _currentStep = CollectionStep.initial;

  // Flow data
  String? _publisherHost;
  int? _port;
  String? _username;
  String? _password;
  List<String> _selectedNodeIps = [];
  Profile? _selectedProfile;

  // Time selection state
  bool _isRelativeTime = true;
  int? _relativeMinutes;
  DateTime? _startTime;
  DateTime? _endTime;

  // Getters
  CollectionStep get currentStep => _currentStep;
  String? get publisherHost => _publisherHost;
  int? get port => _port;
  String? get username => _username;
  String? get password => _password;
  List<String> get selectedNodeIps => List.unmodifiable(_selectedNodeIps);
  Profile? get selectedProfile => _selectedProfile;
  bool get isRelativeTime => _isRelativeTime;
  int? get relativeMinutes => _relativeMinutes;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;

  // Computed properties
  bool get hasClusterInfo =>
      _publisherHost != null &&
      _port != null &&
      _username != null &&
      _password != null;

  bool get hasNodesSelected => _selectedNodeIps.isNotEmpty;

  bool get hasProfileSelected => _selectedProfile != null;

  bool get hasValidTimeConfig {
    if (_isRelativeTime) {
      // Relative time is always valid (will use profile default if null)
      return true;
    } else {
      // Absolute time requires both start and end times
      return _startTime != null && _endTime != null;
    }
  }

  bool get isReadyToCollect =>
      hasClusterInfo &&
      hasNodesSelected &&
      hasProfileSelected &&
      hasValidTimeConfig;

  /// Set cluster discovery information
  void setClusterInfo({
    required String publisherHost,
    required int port,
    required String username,
    required String password,
  }) {
    _publisherHost = publisherHost;
    _port = port;
    _username = username;
    _password = password;
    _updateStep();
  }

  /// Set selected node IPs
  void setSelectedNodes(List<String> nodeIps) {
    _selectedNodeIps = List.from(nodeIps);
    _updateStep();
  }

  /// Set selected profile
  void setSelectedProfile(Profile? profile) {
    _selectedProfile = profile;
    _updateStep();
  }

  /// Set time selection mode
  void setTimeMode({required bool isRelative}) {
    _isRelativeTime = isRelative;
    if (isRelative) {
      // Clear absolute time when switching to relative
      _startTime = null;
      _endTime = null;
    } else {
      // Clear relative time when switching to absolute
      _relativeMinutes = null;
    }
    _updateStep();
  }

  /// Set relative time (in minutes)
  void setRelativeTime(int? minutes) {
    _relativeMinutes = minutes;
    _updateStep();
  }

  /// Set absolute time range
  void setAbsoluteTime({DateTime? startTime, DateTime? endTime}) {
    _startTime = startTime;
    _endTime = endTime;
    _updateStep();
  }

  /// Reset the entire flow
  void reset() {
    _currentStep = CollectionStep.initial;
    _publisherHost = null;
    _port = null;
    _username = null;
    _password = null;
    _selectedNodeIps = [];
    _selectedProfile = null;
    _isRelativeTime = true;
    _relativeMinutes = null;
    _startTime = null;
    _endTime = null;
    notifyListeners();
  }

  /// Reset from profile selection onwards (keep cluster and nodes)
  void resetFromProfileSelection() {
    _selectedProfile = null;
    _isRelativeTime = true;
    _relativeMinutes = null;
    _startTime = null;
    _endTime = null;
    _updateStep();
  }

  /// Automatically update the current step based on state
  void _updateStep() {
    final previousStep = _currentStep;

    if (isReadyToCollect) {
      _currentStep = CollectionStep.ready;
    } else if (hasProfileSelected && hasValidTimeConfig) {
      _currentStep = CollectionStep.timeConfigured;
    } else if (hasProfileSelected) {
      _currentStep = CollectionStep.profileSelected;
    } else if (hasNodesSelected) {
      _currentStep = CollectionStep.nodesSelected;
    } else if (hasClusterInfo) {
      _currentStep = CollectionStep.clusterDiscovered;
    } else {
      _currentStep = CollectionStep.initial;
    }

    // Only notify if step actually changed
    if (previousStep != _currentStep) {
      notifyListeners();
    } else {
      // Still notify for data changes even if step didn't change
      notifyListeners();
    }
  }

  /// Get human-readable step name
  String get stepName {
    switch (_currentStep) {
      case CollectionStep.initial:
        return 'Initial';
      case CollectionStep.clusterDiscovered:
        return 'Cluster Discovered';
      case CollectionStep.nodesSelected:
        return 'Nodes Selected';
      case CollectionStep.profileSelected:
        return 'Profile Selected';
      case CollectionStep.timeConfigured:
        return 'Time Configured';
      case CollectionStep.ready:
        return 'Ready to Collect';
    }
  }

  /// Get step progress (0.0 to 1.0)
  double get progress {
    switch (_currentStep) {
      case CollectionStep.initial:
        return 0.0;
      case CollectionStep.clusterDiscovered:
        return 0.2;
      case CollectionStep.nodesSelected:
        return 0.4;
      case CollectionStep.profileSelected:
        return 0.6;
      case CollectionStep.timeConfigured:
        return 0.8;
      case CollectionStep.ready:
        return 1.0;
    }
  }
}
