import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../models/collection_flow_state.dart';
import '../services/http_client.dart';
import 'job_status_screen.dart';

class ProfileSelectionScreen extends StatefulWidget {
  final List<String> selectedNodeIps;
  final String publisherHost;
  final int port;
  final String username;
  final String password;

  const ProfileSelectionScreen({
    super.key,
    required this.selectedNodeIps,
    required this.publisherHost,
    required this.port,
    required this.username,
    required this.password,
  });

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  List<Profile>? _profiles;
  Profile? _selectedProfile;
  bool _isLoading = true;
  String? _errorMessage;

  // Override values
  int? _overrideReltimeMinutes;
  bool? _overrideCompress;
  bool? _overrideRecurs;
  String? _overrideMatch;
  bool _showOverrides = false;

  // Time selection mode: 'relative' or 'absolute'
  String _timeMode = 'relative';
  DateTime? _startTime;
  DateTime? _endTime;
  String? _timeRangeError;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      final profiles = await httpClient.getProfiles();

      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _validateTimeRange() {
    setState(() {
      _timeRangeError = null;
    });

    if (_startTime == null || _endTime == null) {
      setState(() {
        _timeRangeError = 'Please select both start and end times';
      });
      return false;
    }

    final now = DateTime.now();

    // Check for future dates
    if (_startTime!.isAfter(now)) {
      setState(() {
        _timeRangeError = 'Start time cannot be in the future';
      });
      return false;
    }

    if (_endTime!.isAfter(now)) {
      setState(() {
        _timeRangeError = 'End time cannot be in the future';
      });
      return false;
    }

    // Check that start is before end
    if (_startTime!.isAfter(_endTime!) || _startTime!.isAtSameMomentAs(_endTime!)) {
      setState(() {
        _timeRangeError = 'Start time must be before end time';
      });
      return false;
    }

    return true;
  }

  Future<void> _showConfirmationDialog() async {
    if (_selectedProfile == null) return;

    // Validate time range if in absolute mode
    if (_timeMode == 'absolute') {
      if (!_validateTimeRange()) {
        return; // Error message already set by _validateTimeRange
      }
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(),
    );

    if (confirmed == true) {
      await _startCollection();
    }
  }

  Future<void> _startCollection() async {
    if (_selectedProfile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);

      // Build options map from overrides (only include if user specified overrides)
      Map<String, dynamic>? options;
      if (_timeMode == 'absolute' ||
          _overrideReltimeMinutes != null ||
          _overrideCompress != null ||
          _overrideRecurs != null ||
          _overrideMatch != null) {
        options = {};

        // Add time-related options based on mode
        if (_timeMode == 'relative' && _overrideReltimeMinutes != null) {
          options['reltime_minutes'] = _overrideReltimeMinutes;
        } else if (_timeMode == 'absolute' && _startTime != null && _endTime != null) {
          options['start_time'] = _startTime!.toIso8601String();
          options['end_time'] = _endTime!.toIso8601String();
        }

        if (_overrideCompress != null) {
          options['compress'] = _overrideCompress;
        }
        if (_overrideRecurs != null) {
          options['recurs'] = _overrideRecurs;
        }
        if (_overrideMatch != null) {
          options['match'] = _overrideMatch;
        }
      }

      final request = CreateJobRequest(
        publisherHost: widget.publisherHost,
        port: widget.port,
        username: widget.username,
        password: widget.password,
        nodes: widget.selectedNodeIps,
        profile: _selectedProfile!.name,
        options: options,
      );

      final response = await httpClient.createJob(request);

      if (!mounted) return;

      // Navigate to Job Status screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => JobStatusScreen(jobId: response.jobId),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onSelected,
  }) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();

        // Show date picker
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2020),
          lastDate: now, // Cannot select future dates
          helpText: 'Select $label Date',
        );

        if (pickedDate == null) return;

        if (!mounted) return;

        // Show time picker
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: value != null ? TimeOfDay.fromDateTime(value) : TimeOfDay.now(),
          helpText: 'Select $label Time',
        );

        if (pickedTime == null) return;

        // Combine date and time
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Validate not in future - just call the callback,
        // validation will be shown inline in the time range error
        onSelected(selectedDateTime);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onSelected(null),
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? _formatDateTime(value)
              : 'Tap to select date and time',
          style: TextStyle(
            color: value != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  String _getTimeRangeSummary() {
    if (_timeMode == 'relative') {
      final minutes = _overrideReltimeMinutes ?? _selectedProfile!.reltimeMinutes;
      return 'Last $minutes minutes';
    } else {
      // Absolute mode
      if (_startTime != null && _endTime != null) {
        return '${_formatDateTime(_startTime!)} to ${_formatDateTime(_endTime!)}';
      }
      return 'Time range not set';
    }
  }

  Widget _buildConfirmationDialog() {
    final compress = _overrideCompress ?? _selectedProfile!.compress;
    final recurs = _overrideRecurs ?? _selectedProfile!.recurs;
    final match = _overrideMatch ?? _selectedProfile!.match;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          const Text('Confirm Collection'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please review the collection settings:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 20),

            // Nodes
            _buildSummaryItem(
              icon: Icons.devices,
              label: 'Nodes',
              value: '${widget.selectedNodeIps.length} node${widget.selectedNodeIps.length > 1 ? 's' : ''} selected',
            ),
            const SizedBox(height: 12),

            // Profile
            _buildSummaryItem(
              icon: Icons.description,
              label: 'Profile',
              value: _selectedProfile!.name,
            ),
            const SizedBox(height: 12),

            // Time Range
            _buildSummaryItem(
              icon: _timeMode == 'relative' ? Icons.access_time : Icons.date_range,
              label: 'Time Range',
              value: _getTimeRangeSummary(),
            ),
            const SizedBox(height: 12),

            // Compress
            _buildSummaryItem(
              icon: Icons.compress,
              label: 'Compress',
              value: compress ? 'Enabled' : 'Disabled',
            ),
            const SizedBox(height: 12),

            // Recurs
            _buildSummaryItem(
              icon: Icons.repeat,
              label: 'Recurs',
              value: recurs ? 'Enabled' : 'Disabled',
            ),

            // Match (only if set)
            if (match.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSummaryItem(
                icon: Icons.filter_alt,
                label: 'Match Pattern',
                value: match,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Collection'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    bool isCompact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isCompact ? 18 : 20,
          color: iconColor ?? Colors.grey.shade600,
        ),
        SizedBox(width: isCompact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isCompact ? 2 : 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CollectionFlowState>(
      builder: (context, flowState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Profile'),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildProfileList(),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profiles',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfiles,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowProgressCard(CollectionFlowState flowState) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collection Setup Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildProgressStep(
                  icon: Icons.cloud_done,
                  label: 'Cluster',
                  isComplete: flowState.hasClusterInfo,
                ),
                _buildProgressArrow(),
                _buildProgressStep(
                  icon: Icons.devices,
                  label: 'Nodes',
                  isComplete: flowState.hasNodesSelected,
                ),
                _buildProgressArrow(),
                _buildProgressStep(
                  icon: Icons.description,
                  label: 'Profile',
                  isComplete: flowState.hasProfileSelected,
                ),
                _buildProgressArrow(),
                _buildProgressStep(
                  icon: Icons.schedule,
                  label: 'Time',
                  isComplete: flowState.hasValidTimeConfig,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep({
    required IconData icon,
    required String label,
    required bool isComplete,
  }) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Animated icon container with background
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isComplete ? Colors.green.shade100 : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isComplete ? Colors.green.shade700 : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey('$icon-$isComplete'),
                    color: isComplete ? Colors.green.shade700 : Colors.grey.shade500,
                    size: 20,
                  ),
                ),
              ),
              // Animated checkmark badge overlay for completed steps
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isComplete ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 300),
                  scale: isComplete ? 1.0 : 0.0,
                  curve: Curves.easeOutBack,
                  child: Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontSize: 11,
              color: isComplete ? Colors.green.shade700 : Colors.grey.shade600,
              fontWeight: isComplete ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
            ),
          ),
          // Animated "Completed" badge for completed steps
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isComplete
                ? Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressArrow() {
    return Icon(
      Icons.arrow_forward,
      size: 16,
      color: Colors.grey.shade400,
    );
  }

  Widget _buildProfileList() {
    if (_profiles == null || _profiles!.isEmpty) {
      return const Center(
        child: Text('No profiles available'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Flow progress indicator
        _buildFlowProgressCard(context.watch<CollectionFlowState>()),
        const SizedBox(height: 16),

        // Profile selection section header
        if (_selectedProfile == null)
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select a collection profile to continue',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_selectedProfile == null) const SizedBox(height: 16),

        // Profile cards
        ..._profiles!.map((profile) => _buildProfileCard(profile)),

        // Time selection section (always visible when profile is selected)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _selectedProfile != null
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _selectedProfile != null ? 1.0 : 0.0,
                      child: _buildTimeSelectionCard(),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // Other overrides section (collapsible, only shown when profile is selected)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _selectedProfile != null
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _selectedProfile != null ? 1.0 : 0.0,
                      child: _buildOverridesSection(),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // Review & Confirm section (shown when profile is selected)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _selectedProfile != null
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _selectedProfile != null ? 1.0 : 0.0,
                      child: _buildReviewConfirmSection(context.watch<CollectionFlowState>()),
                    ),
                    const SizedBox(height: 16), // Bottom padding
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildReviewConfirmSection(CollectionFlowState flowState) {
    final compress = _overrideCompress ?? _selectedProfile!.compress;
    final recurs = _overrideRecurs ?? _selectedProfile!.recurs;
    final match = _overrideMatch ?? _selectedProfile!.match;
    final isReadyToCollect = flowState.isReadyToCollect && _timeRangeError == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isReadyToCollect ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isReadyToCollect ? Icons.check_circle : Icons.summarize,
                    key: ValueKey(isReadyToCollect),
                    color: isReadyToCollect ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isReadyToCollect ? Colors.green.shade700 : Colors.blue.shade700,
                        ),
                    child: const Text('Review & Confirm'),
                  ),
                ),
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: isReadyToCollect ? 1.0 : 0.0,
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isReadyToCollect ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Ready',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Summary content
            Text(
              'Collection Summary',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),

            // Selected Nodes
            _buildSummaryItem(
              icon: Icons.devices,
              label: 'Target Nodes',
              value: '${widget.selectedNodeIps.length} node${widget.selectedNodeIps.length > 1 ? 's' : ''} selected',
              iconColor: Colors.blue.shade700,
            ),
            const SizedBox(height: 12),

            // Profile
            _buildSummaryItem(
              icon: Icons.description,
              label: 'Collection Profile',
              value: _selectedProfile!.name,
              iconColor: Colors.purple.shade700,
            ),
            const SizedBox(height: 12),

            // Time Range
            _buildSummaryItem(
              icon: _timeMode == 'relative' ? Icons.access_time : Icons.date_range,
              label: 'Time Range',
              value: _getTimeRangeSummary(),
              iconColor: Colors.orange.shade700,
            ),
            const SizedBox(height: 12),

            // Estimated Scope (optional details)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(left: 12, bottom: 12),
              title: Text(
                'Additional Options',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              children: [
                _buildSummaryItem(
                  icon: Icons.compress,
                  label: 'Compress',
                  value: compress ? 'Enabled' : 'Disabled',
                  iconColor: Colors.teal.shade700,
                  isCompact: true,
                ),
                const SizedBox(height: 8),
                _buildSummaryItem(
                  icon: Icons.repeat,
                  label: 'Recursive',
                  value: recurs ? 'Enabled' : 'Disabled',
                  iconColor: Colors.indigo.shade700,
                  isCompact: true,
                ),
                if (match.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildSummaryItem(
                    icon: Icons.filter_alt,
                    label: 'Match Pattern',
                    value: match,
                    iconColor: Colors.pink.shade700,
                    isCompact: true,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Start Collection Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading || !isReadyToCollect
                    ? null
                    : _showConfirmationDialog,
                icon: Icon(
                  _isLoading ? Icons.hourglass_empty : Icons.play_arrow,
                  size: 24,
                ),
                label: Text(
                  _isLoading
                      ? 'Starting Collection...'
                      : _timeRangeError != null
                          ? 'Fix time range errors to continue'
                          : isReadyToCollect
                              ? 'Start Collection'
                              : 'Complete time selection to continue',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isReadyToCollect ? Colors.green.shade600 : null,
                  foregroundColor: isReadyToCollect ? Colors.white : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Profile profile) {
    final isSelected = _selectedProfile == profile;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
            blurRadius: isSelected ? 8 : 4,
            offset: Offset(0, isSelected ? 3 : 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedProfile = profile;
            // Reset overrides when selecting a new profile
            _timeMode = 'relative';
            _overrideReltimeMinutes = null;
            _startTime = null;
            _endTime = null;
            _timeRangeError = null;
            _overrideCompress = null;
            _overrideRecurs = null;
            _overrideMatch = null;
            _showOverrides = false;
          });

          // Update flow state
          final flowState = context.read<CollectionFlowState>();
          flowState.setSelectedProfile(profile);
          flowState.setTimeMode(isRelative: true);
          flowState.setRelativeTime(null);
          flowState.setAbsoluteTime(startTime: null, endTime: null);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<Profile>(
                    value: profile,
                    groupValue: _selectedProfile,
                    onChanged: (Profile? value) {
                      setState(() {
                        _selectedProfile = value;
                        _timeMode = 'relative';
                        _overrideReltimeMinutes = null;
                        _startTime = null;
                        _endTime = null;
                        _timeRangeError = null;
                        _overrideCompress = null;
                        _overrideRecurs = null;
                        _overrideMatch = null;
                        _showOverrides = false;
                      });

                      // Update flow state
                      if (value != null) {
                        final flowState = context.read<CollectionFlowState>();
                        flowState.setSelectedProfile(value);
                        flowState.setTimeMode(isRelative: true);
                        flowState.setRelativeTime(null);
                        flowState.setAbsoluteTime(startTime: null, endTime: null);
                      }
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (profile.description.isNotEmpty)
                          Text(
                            profile.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildProfileDetail(
                    Icons.schedule,
                    'Time',
                    '${profile.reltimeMinutes} min',
                  ),
                  _buildProfileDetail(
                    Icons.compress,
                    'Compress',
                    profile.compress ? 'Yes' : 'No',
                  ),
                  _buildProfileDetail(
                    Icons.repeat,
                    'Recurs',
                    profile.recurs ? 'Yes' : 'No',
                  ),
                  if (profile.match.isNotEmpty)
                    _buildProfileDetail(
                      Icons.filter_alt,
                      'Match',
                      profile.match,
                    ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildProfileDetail(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelectionCard() {
    final flowState = context.watch<CollectionFlowState>();
    final isTimeValid = flowState.hasValidTimeConfig;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isTimeValid ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isTimeValid ? Icons.check_circle : Icons.schedule,
                    key: ValueKey(isTimeValid),
                    color: isTimeValid ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isTimeValid ? Colors.green.shade700 : Colors.blue.shade700,
                        ),
                    child: const Text('Collection Time Range'),
                  ),
                ),
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: isTimeValid ? 1.0 : 0.0,
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isTimeValid ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Ready',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time selection mode toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'relative',
                  label: Text('Last X minutes'),
                  icon: Icon(Icons.access_time),
                ),
                ButtonSegment(
                  value: 'absolute',
                  label: Text('Time range'),
                  icon: Icon(Icons.date_range),
                ),
              ],
              selected: {_timeMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _timeMode = newSelection.first;
                  _timeRangeError = null;
                  if (_timeMode == 'relative') {
                    _startTime = null;
                    _endTime = null;
                  } else {
                    _overrideReltimeMinutes = null;
                  }
                });

                // Update flow state
                final flowState = context.read<CollectionFlowState>();
                flowState.setTimeMode(isRelative: _timeMode == 'relative');
              },
            ),
            const SizedBox(height: 16),

            // Hint for absolute mode
            if (_timeMode == 'absolute' && (_startTime == null || _endTime == null) && _timeRangeError == null)
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select both start and end times to continue',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_timeMode == 'absolute' && (_startTime == null || _endTime == null) && _timeRangeError == null)
              const SizedBox(height: 12),

            // Relative time input (only show in relative mode)
            if (_timeMode == 'relative')
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Relative Time (minutes)',
                  hintText: 'Default: ${_selectedProfile!.reltimeMinutes}',
                  helperText: 'Number of minutes to look back from now',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _overrideReltimeMinutes = int.tryParse(value);
                  });

                  // Update flow state
                  context.read<CollectionFlowState>().setRelativeTime(int.tryParse(value));
                },
              ),

            // Time range pickers (only show in absolute mode)
            if (_timeMode == 'absolute') ...[
              _buildDateTimePicker(
                label: 'Start Time',
                value: _startTime,
                onSelected: (DateTime? dateTime) {
                  setState(() {
                    _startTime = dateTime;
                    _timeRangeError = null;
                  });

                  // Update flow state
                  context.read<CollectionFlowState>().setAbsoluteTime(
                    startTime: dateTime,
                    endTime: _endTime,
                  );

                  // Validate automatically if both dates are set
                  if (dateTime != null && _endTime != null) {
                    _validateTimeRange();
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildDateTimePicker(
                label: 'End Time',
                value: _endTime,
                onSelected: (DateTime? dateTime) {
                  setState(() {
                    _endTime = dateTime;
                    _timeRangeError = null;
                  });

                  // Update flow state
                  context.read<CollectionFlowState>().setAbsoluteTime(
                    startTime: _startTime,
                    endTime: dateTime,
                  );

                  // Validate automatically if both dates are set
                  if (dateTime != null && _startTime != null) {
                    _validateTimeRange();
                  }
                },
              ),
              if (_timeRangeError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _timeRangeError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverridesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Additional Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: Icon(
                    _showOverrides ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _showOverrides = !_showOverrides;
                    });
                  },
                ),
              ],
            ),
            if (_showOverrides) ...[
              const Divider(),
              const SizedBox(height: 8),

              // Compress toggle
              SwitchListTile(
                title: const Text('Compress'),
                subtitle: Text(
                  'Default: ${_selectedProfile!.compress ? "Enabled" : "Disabled"}',
                ),
                value: _overrideCompress ?? _selectedProfile!.compress,
                onChanged: (value) {
                  setState(() {
                    _overrideCompress = value;
                  });
                },
              ),

              // Recurs toggle
              SwitchListTile(
                title: const Text('Recurs'),
                subtitle: Text(
                  'Default: ${_selectedProfile!.recurs ? "Enabled" : "Disabled"}',
                ),
                value: _overrideRecurs ?? _selectedProfile!.recurs,
                onChanged: (value) {
                  setState(() {
                    _overrideRecurs = value;
                  });
                },
              ),

              // Match string
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Match Pattern',
                  hintText: _selectedProfile!.match.isNotEmpty
                      ? 'Default: ${_selectedProfile!.match}'
                      : 'No default pattern',
                ),
                onChanged: (value) {
                  setState(() {
                    _overrideMatch = value.isNotEmpty ? value : null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
