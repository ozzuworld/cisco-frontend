import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
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

  Future<void> _startCollection() async {
    if (_selectedProfile == null) return;

    // Validate time range if in absolute mode
    if (_timeMode == 'absolute') {
      if (!_validateTimeRange()) {
        return; // Error message already set by _validateTimeRange
      }
    }

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

        // Validate not in future
        if (selectedDateTime.isAfter(now)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label cannot be in the future'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildProfileList(),
      bottomNavigationBar: _selectedProfile != null
          ? Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startCollection,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'Start Collection (${widget.selectedNodeIps.length} node${widget.selectedNodeIps.length > 1 ? 's' : ''})',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
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

  Widget _buildProfileList() {
    if (_profiles == null || _profiles!.isEmpty) {
      return const Center(
        child: Text('No profiles available'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Header with node count
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selected ${widget.selectedNodeIps.length} node${widget.selectedNodeIps.length > 1 ? 's' : ''} for collection',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Profile cards
        ..._profiles!.map((profile) => _buildProfileCard(profile)),

        // Overrides section (only shown when profile is selected)
        if (_selectedProfile != null) ...[
          const SizedBox(height: 16),
          _buildOverridesSection(),
        ],
      ],
    );
  }

  Widget _buildProfileCard(Profile profile) {
    final isSelected = _selectedProfile == profile;

    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected ? Colors.blue.shade50 : null,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
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
                  'Override Settings',
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

              // Time selection mode toggle
              Text(
                'Time Selection Mode',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
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
                },
              ),
              const SizedBox(height: 16),

              // Relative time input (only show in relative mode)
              if (_timeMode == 'relative')
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Relative Time (minutes)',
                    hintText: 'Default: ${_selectedProfile!.reltimeMinutes}',
                    helperText: 'Number of minutes to look back from now',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _overrideReltimeMinutes = int.tryParse(value);
                    });
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
              const SizedBox(height: 16),

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
