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
      if (_overrideReltimeMinutes != null ||
          _overrideCompress != null ||
          _overrideRecurs != null ||
          _overrideMatch != null) {
        options = {};
        if (_overrideReltimeMinutes != null) {
          options['reltime_minutes'] = _overrideReltimeMinutes;
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
            _overrideReltimeMinutes = null;
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
                        _overrideReltimeMinutes = null;
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

              // Reltime Minutes
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Relative Time (minutes)',
                  hintText: 'Default: ${_selectedProfile!.reltimeMinutes}',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _overrideReltimeMinutes = int.tryParse(value);
                  });
                },
              ),
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
