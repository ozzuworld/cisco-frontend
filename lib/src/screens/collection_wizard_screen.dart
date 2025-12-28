import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../models/collection_flow_state.dart';
import '../models/cucm_node.dart';
import '../models/profile.dart';
import '../models/api_error.dart';
import '../services/http_client.dart';
import 'job_status_screen.dart';
import 'settings_screen.dart';

/// Single-page guided collection wizard with accordion/stepper UI
class CollectionWizardScreen extends StatefulWidget {
  const CollectionWizardScreen({super.key});

  @override
  State<CollectionWizardScreen> createState() => _CollectionWizardScreenState();
}

class _CollectionWizardScreenState extends State<CollectionWizardScreen> {
  // Step 1: Cluster Discovery
  final _formKey = GlobalKey<FormState>();
  final _publisherHostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isDiscovering = false;
  DiscoveryResponse? _discoveryResult;
  ApiError? _discoveryError;
  final Set<String> _selectedNodeIps = {};

  // Step 3: Profile Selection
  List<Profile>? _profiles;
  Profile? _selectedProfile;
  bool _isLoadingProfiles = false;
  String? _profilesErrorMessage;

  // Step 4: Time Configuration
  String _timeMode = 'relative';
  int? _overrideReltimeMinutes;
  DateTime? _startTime;
  DateTime? _endTime;
  String? _timeRangeError;
  bool? _overrideCompress;
  bool? _overrideRecurs;
  String? _overrideMatch;
  bool _showOverrides = false;

  // Step 5: Review & Start
  bool _isStartingCollection = false;

  // Expansion state for accordion
  int? _expandedStepIndex;

  @override
  void initState() {
    super.initState();
    // Start with first step expanded
    _expandedStepIndex = 0;
  }

  @override
  void dispose() {
    _publisherHostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Determine which step index is currently active based on flow state
  int _getCurrentStepIndex(CollectionFlowState flowState) {
    switch (flowState.currentStep) {
      case CollectionStep.initial:
        return 0; // Cluster Discovery
      case CollectionStep.clusterDiscovered:
        return 1; // Node Selection
      case CollectionStep.nodesSelected:
        return 2; // Profile Selection
      case CollectionStep.profileSelected:
      case CollectionStep.timeConfigured:
        return 3; // Time Configuration
      case CollectionStep.ready:
        return 4; // Review & Start
    }
  }

  /// Check if a step is unlocked (can be interacted with)
  bool _isStepUnlocked(int stepIndex, CollectionFlowState flowState) {
    final currentStepIndex = _getCurrentStepIndex(flowState);
    // A step is unlocked if it's the current step or any earlier completed step
    return stepIndex <= currentStepIndex;
  }

  /// Check if a step is completed
  bool _isStepCompleted(int stepIndex, CollectionFlowState flowState) {
    final currentStepIndex = _getCurrentStepIndex(flowState);
    return stepIndex < currentStepIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CollectionFlowState>(
      builder: (context, flowState, child) {
        final currentStepIndex = _getCurrentStepIndex(flowState);

        // Auto-expand the current step when it changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_expandedStepIndex != currentStepIndex) {
            setState(() {
              _expandedStepIndex = currentStepIndex;
            });
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Collection Wizard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Wizard',
                onPressed: () => _showResetDialog(flowState),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress indicator
                _buildProgressIndicator(flowState),
                const SizedBox(height: 24),

                // Step 1: Cluster Discovery
                _buildWizardStep(
                  stepIndex: 0,
                  title: 'Cluster Discovery',
                  icon: Icons.cloud_done,
                  flowState: flowState,
                  content: _buildClusterDiscoveryContent(flowState),
                ),
                const SizedBox(height: 12),

                // Step 2: Node Selection
                _buildWizardStep(
                  stepIndex: 1,
                  title: 'Node Selection',
                  icon: Icons.devices,
                  flowState: flowState,
                  content: _buildNodeSelectionContent(flowState),
                ),
                const SizedBox(height: 12),

                // Step 3: Profile Selection
                _buildWizardStep(
                  stepIndex: 2,
                  title: 'Profile Selection',
                  icon: Icons.description,
                  flowState: flowState,
                  content: _buildProfileSelectionContent(flowState),
                ),
                const SizedBox(height: 12),

                // Step 4: Time Configuration
                _buildWizardStep(
                  stepIndex: 3,
                  title: 'Time Configuration',
                  icon: Icons.schedule,
                  flowState: flowState,
                  content: _buildTimeConfigurationContent(flowState),
                ),
                const SizedBox(height: 12),

                // Step 5: Review & Start
                _buildWizardStep(
                  stepIndex: 4,
                  title: 'Review & Start',
                  icon: Icons.play_arrow,
                  flowState: flowState,
                  content: _buildReviewStartContent(flowState),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(CollectionFlowState flowState) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Collection Setup Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: flowState.progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              '${(flowState.progress * 100).toInt()}% Complete - ${flowState.stepName}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardStep({
    required int stepIndex,
    required String title,
    required IconData icon,
    required CollectionFlowState flowState,
    required Widget content,
  }) {
    final isUnlocked = _isStepUnlocked(stepIndex, flowState);
    final isCompleted = _isStepCompleted(stepIndex, flowState);
    final isExpanded = _expandedStepIndex == stepIndex;
    final currentStepIndex = _getCurrentStepIndex(flowState);
    final isCurrent = stepIndex == currentStepIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.shade50
            : isCurrent
                ? Colors.blue.shade50
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.shade300
              : isCurrent
                  ? Colors.blue.shade300
                  : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: isUnlocked ? null : Colors.transparent,
          highlightColor: isUnlocked ? null : Colors.transparent,
        ),
        child: ExpansionTile(
          key: ValueKey('step_$stepIndex'),
          initiallyExpanded: isExpanded,
          maintainState: true,
          onExpansionChanged: isUnlocked
              ? (expanded) {
                  setState(() {
                    _expandedStepIndex = expanded ? stepIndex : null;
                  });
                }
              : null,
          leading: _buildStepIcon(stepIndex, icon, isCompleted, isUnlocked, isCurrent),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isUnlocked
                        ? (isCompleted ? Colors.green.shade700 : Colors.black87)
                        : Colors.grey.shade400,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Complete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (!isUnlocked)
                Icon(Icons.lock, size: 20, color: Colors.grey.shade400),
            ],
          ),
          children: [
            if (isUnlocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: content,
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.grey.shade400),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete previous steps to unlock',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIcon(
    int stepIndex,
    IconData icon,
    bool isCompleted,
    bool isUnlocked,
    bool isCurrent,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.shade100
            : isCurrent
                ? Colors.blue.shade100
                : isUnlocked
                    ? Colors.grey.shade100
                    : Colors.grey.shade50,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted
              ? Colors.green.shade700
              : isCurrent
                  ? Colors.blue.shade700
                  : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Icon(
        isCompleted ? Icons.check : icon,
        color: isCompleted
            ? Colors.green.shade700
            : isCurrent
                ? Colors.blue.shade700
                : isUnlocked
                    ? Colors.grey.shade700
                    : Colors.grey.shade400,
        size: 24,
      ),
    );
  }

  // Step 1: Cluster Discovery Content
  Widget _buildClusterDiscoveryContent(CollectionFlowState flowState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your CUCM Publisher credentials to discover cluster nodes',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _publisherHostController,
                decoration: const InputDecoration(
                  labelText: 'Publisher Host',
                  hintText: 'IP address or FQDN',
                  prefixIcon: Icon(Icons.dns),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Publisher host is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '22',
                  prefixIcon: Icon(Icons.settings_ethernet),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Port is required';
                  }
                  final port = int.tryParse(value.trim());
                  if (port == null || port < 1 || port > 65535) {
                    return 'Port must be between 1 and 65535';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'administrator',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isDiscovering ? null : _discoverCluster,
                icon: _isDiscovering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isDiscovering ? 'Discovering...' : 'Discover Cluster'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16.0),
                ),
              ),
            ],
          ),
        ),
        if (_discoveryError != null) ...[
          const SizedBox(height: 16),
          _buildErrorCard(_discoveryError!),
        ],
        if (_discoveryResult != null && _discoveryResult!.hasNodes) ...[
          const SizedBox(height: 16),
          _buildSuccessCard(_discoveryResult!),
        ],
      ],
    );
  }

  Widget _buildSuccessCard(DiscoveryResponse result) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Discovery Successful!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Found ${result.nodes.length} node${result.nodes.length != 1 ? 's' : ''} in the cluster. Continue to Step 2 to select nodes.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: result.nodes.map((node) {
              final isPublisher = node.role?.toLowerCase() == 'publisher';
              return Chip(
                avatar: Icon(
                  Icons.computer,
                  size: 16,
                  color: isPublisher ? Colors.blue.shade700 : Colors.grey.shade700,
                ),
                label: Text(
                  node.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: isPublisher ? Colors.blue.shade50 : Colors.grey.shade100,
                side: BorderSide(
                  color: isPublisher ? Colors.blue.shade300 : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _discoverCluster() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isDiscovering = true;
      _discoveryResult = null;
      _discoveryError = null;
    });

    final httpClient = context.read<HttpClientService>();

    final request = DiscoveryRequest(
      publisherHost: _publisherHostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      connectTimeoutSec: 30,
      commandTimeoutSec: 120,
    );

    try {
      final result = await httpClient.discoverNodes(request);

      setState(() {
        _discoveryResult = result;
        _isDiscovering = false;

        // Auto-select Publisher nodes by default
        _selectedNodeIps.clear();
        for (final node in result.nodes) {
          if (node.role?.toLowerCase() == 'publisher') {
            _selectedNodeIps.add(node.ip);
          }
        }
      });

      // Update flow state with cluster info
      if (mounted) {
        final flowState = context.read<CollectionFlowState>();
        flowState.setClusterInfo(
          publisherHost: request.publisherHost,
          port: request.port,
          username: request.username,
          password: request.password,
        );
        // Update selected nodes (Publisher nodes auto-selected)
        flowState.setSelectedNodes(_selectedNodeIps.toList());
      }
    } on DioException catch (e) {
      final apiError = e.error as ApiError;

      setState(() {
        _discoveryError = apiError;
        _isDiscovering = false;
      });

      if (mounted) {
        _showErrorDialog(apiError);
      }
    } catch (e) {
      setState(() {
        _discoveryError = ApiError(
          error: 'Unknown Error',
          message: e.toString(),
        );
        _isDiscovering = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildErrorCard(ApiError error) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Discovery Failed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error.message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.red.shade900,
            ),
          ),
          if (error.requestId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Request ID: ${error.requestId}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showErrorDialog(ApiError error) {
    String title;
    String message;
    final bool is401 = error.statusCode == 401;

    switch (error.statusCode) {
      case 401:
        title = 'Authentication Failed';
        message = 'Invalid API key or CUCM credentials.';
        break;
      case 502:
      case 504:
        title = 'Network Error';
        message = 'Connection timeout or gateway error.';
        break;
      default:
        title = 'Discovery Failed';
        message = error.message;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error.error.isNotEmpty) ...[
                    Text(
                      'Error: ${error.error}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Message: ${error.message}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (error.requestId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Request ID: ${error.requestId}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  if (error.statusCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${error.statusCode}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (is401)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Reconfigure API Key'),
            ),
        ],
      ),
    );
  }

  // Step 2: Node Selection Content
  Widget _buildNodeSelectionContent(CollectionFlowState flowState) {
    if (_discoveryResult == null || _discoveryResult!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Discover a cluster first to select nodes',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selection status
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: _selectedNodeIps.isEmpty ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _selectedNodeIps.isEmpty
                  ? Colors.red.shade300
                  : Colors.blue.shade300,
            ),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  _selectedNodeIps.isEmpty
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  key: ValueKey(_selectedNodeIps.isEmpty),
                  size: 18,
                  color: _selectedNodeIps.isEmpty
                      ? Colors.red.shade700
                      : Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedNodeIps.isEmpty
                      ? 'Select at least one node to proceed'
                      : '${_selectedNodeIps.length} node(s) selected',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _selectedNodeIps.isEmpty
                        ? Colors.red.shade900
                        : Colors.blue.shade900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _selectAllNodes,
                icon: const Icon(Icons.select_all, size: 18),
                label: const Text('All'),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _clearNodeSelection,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Node list
        Text(
          'Discovered ${_discoveryResult!.nodes.length} node(s)',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ..._discoveryResult!.nodes.map((node) => _buildNodeCard(node)),
      ],
    );
  }

  Widget _buildNodeCard(CucmNode node) {
    final isSelected = _selectedNodeIps.contains(node.ip);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      child: InkWell(
        onTap: () => _toggleNodeSelection(node.ip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleNodeSelection(node.ip),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: node.role?.toLowerCase() == 'publisher'
                          ? Colors.blue.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.computer,
                      color: node.role?.toLowerCase() == 'publisher'
                          ? Colors.blue.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (node.fqdn != null)
                          Text(
                            node.fqdn!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (node.role != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: node.role?.toLowerCase() == 'publisher'
                            ? Colors.blue
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        node.role!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow('IP Address', node.ip, Icons.location_on),
              if (node.host != null)
                _buildInfoRow('Hostname', node.host!, Icons.dns),
              if (node.product != null)
                _buildInfoRow('Product', node.product!, Icons.apps),
              if (node.dbrole != null)
                _buildInfoRow('DB Role', node.dbrole!, Icons.storage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleNodeSelection(String nodeIp) {
    setState(() {
      if (_selectedNodeIps.contains(nodeIp)) {
        _selectedNodeIps.remove(nodeIp);
      } else {
        _selectedNodeIps.add(nodeIp);
      }
    });

    // Update flow state
    context.read<CollectionFlowState>().setSelectedNodes(_selectedNodeIps.toList());
  }

  void _selectAllNodes() {
    if (_discoveryResult == null) return;
    setState(() {
      _selectedNodeIps.clear();
      _selectedNodeIps.addAll(_discoveryResult!.nodes.map((n) => n.ip));
    });

    // Update flow state
    context.read<CollectionFlowState>().setSelectedNodes(_selectedNodeIps.toList());
  }

  void _clearNodeSelection() {
    setState(() {
      _selectedNodeIps.clear();
    });

    // Update flow state
    context.read<CollectionFlowState>().setSelectedNodes(_selectedNodeIps.toList());
  }

  // Step 3: Profile Selection Content
  Widget _buildProfileSelectionContent(CollectionFlowState flowState) {
    // Load profiles on first display
    if (_profiles == null && !_isLoadingProfiles && _profilesErrorMessage == null) {
      _loadProfiles();
    }

    if (_isLoadingProfiles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_profilesErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failed to load profiles',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_profilesErrorMessage!),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadProfiles,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_profiles == null || _profiles!.isEmpty) {
      return const Text('No profiles available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedProfile == null)
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Select a collection profile to continue',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        if (_selectedProfile == null) const SizedBox(height: 16),
        ..._profiles!.map((profile) => _buildProfileCard(profile)),
      ],
    );
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoadingProfiles = true;
      _profilesErrorMessage = null;
    });

    try {
      final httpClient = context.read<HttpClientService>();
      final profiles = await httpClient.getProfiles();

      setState(() {
        _profiles = profiles;
        _isLoadingProfiles = false;
      });
    } catch (e) {
      setState(() {
        _profilesErrorMessage = e.toString();
        _isLoadingProfiles = false;
      });
    }
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
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedProfile = profile;
            // Reset time config when selecting a new profile
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
                      if (value != null) {
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (profile.description.isNotEmpty)
                          Text(
                            profile.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: isSelected
                        ? Container(
                            key: const ValueKey('selected'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Selected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(key: ValueKey('not-selected')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildProfileDetail(Icons.schedule, 'Time', '${profile.reltimeMinutes} min'),
                  _buildProfileDetail(Icons.compress, 'Compress', profile.compress ? 'Yes' : 'No'),
                  _buildProfileDetail(Icons.repeat, 'Recurs', profile.recurs ? 'Yes' : 'No'),
                  if (profile.match.isNotEmpty)
                    _buildProfileDetail(Icons.filter_alt, 'Match', profile.match),
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Step 4: Time Configuration Content
  Widget _buildTimeConfigurationContent(CollectionFlowState flowState) {
    if (_selectedProfile == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Select a profile first to configure time',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Time mode toggle
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

        // Relative time input
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
              context.read<CollectionFlowState>().setRelativeTime(int.tryParse(value));
            },
          ),

        // Absolute time pickers
        if (_timeMode == 'absolute') ...[
          if (_startTime == null || _endTime == null)
            Container(
              padding: const EdgeInsets.all(10.0),
              margin: const EdgeInsets.only(bottom: 12),
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
          _buildDateTimePicker(
            label: 'Start Time',
            value: _startTime,
            onSelected: (DateTime? dateTime) {
              setState(() {
                _startTime = dateTime;
                _timeRangeError = null;
              });
              context.read<CollectionFlowState>().setAbsoluteTime(
                    startTime: dateTime,
                    endTime: _endTime,
                  );
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
              context.read<CollectionFlowState>().setAbsoluteTime(
                    startTime: _startTime,
                    endTime: dateTime,
                  );
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
                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onSelected,
  }) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();

        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2020),
          lastDate: now,
          helpText: 'Select $label Date',
        );

        if (pickedDate == null) return;
        if (!mounted) return;

        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: value != null ? TimeOfDay.fromDateTime(value) : TimeOfDay.now(),
          helpText: 'Select $label Time',
        );

        if (pickedTime == null) return;

        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

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
          value != null ? _formatDateTime(value) : 'Tap to select date and time',
          style: TextStyle(color: value != null ? null : Colors.grey),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
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

    if (_startTime!.isAfter(_endTime!) || _startTime!.isAtSameMomentAs(_endTime!)) {
      setState(() {
        _timeRangeError = 'Start time must be before end time';
      });
      return false;
    }

    return true;
  }

  // Step 5: Review & Start Content
  Widget _buildReviewStartContent(CollectionFlowState flowState) {
    if (!flowState.isReadyToCollect || _timeRangeError != null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Complete all previous steps to start collection',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    final compress = _overrideCompress ?? _selectedProfile!.compress;
    final recurs = _overrideRecurs ?? _selectedProfile!.recurs;
    final match = _overrideMatch ?? _selectedProfile!.match;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Please review your configuration before starting:',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),

        // Summary
        _buildSummaryItem(
          icon: Icons.devices,
          label: 'Target Nodes',
          value: '${_selectedNodeIps.length} node${_selectedNodeIps.length > 1 ? 's' : ''} selected',
          iconColor: Colors.blue.shade700,
        ),
        const SizedBox(height: 12),
        _buildSummaryItem(
          icon: Icons.description,
          label: 'Profile',
          value: _selectedProfile!.name,
          iconColor: Colors.purple.shade700,
        ),
        const SizedBox(height: 12),
        _buildSummaryItem(
          icon: _timeMode == 'relative' ? Icons.access_time : Icons.date_range,
          label: 'Time Range',
          value: _getTimeRangeSummary(),
          iconColor: Colors.orange.shade700,
        ),
        const SizedBox(height: 12),
        _buildSummaryItem(
          icon: Icons.compress,
          label: 'Compress',
          value: compress ? 'Enabled' : 'Disabled',
          iconColor: Colors.teal.shade700,
        ),
        const SizedBox(height: 12),
        _buildSummaryItem(
          icon: Icons.repeat,
          label: 'Recursive',
          value: recurs ? 'Enabled' : 'Disabled',
          iconColor: Colors.indigo.shade700,
        ),
        if (match.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSummaryItem(
            icon: Icons.filter_alt,
            label: 'Match Pattern',
            value: match,
            iconColor: Colors.pink.shade700,
          ),
        ],
        const SizedBox(height: 24),

        // Start button
        ElevatedButton.icon(
          onPressed: _isStartingCollection ? null : _startCollection,
          icon: Icon(
            _isStartingCollection ? Icons.hourglass_empty : Icons.play_arrow,
            size: 24,
          ),
          label: Text(
            _isStartingCollection ? 'Starting Collection...' : 'Start Collection',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTimeRangeSummary() {
    if (_timeMode == 'relative') {
      final minutes = _overrideReltimeMinutes ?? _selectedProfile!.reltimeMinutes;
      return 'Last $minutes minutes';
    } else {
      if (_startTime != null && _endTime != null) {
        return '${_formatDateTime(_startTime!)} to ${_formatDateTime(_endTime!)}';
      }
      return 'Time range not set';
    }
  }

  Future<void> _startCollection() async {
    if (_selectedProfile == null) return;

    setState(() {
      _isStartingCollection = true;
    });

    try {
      final httpClient = context.read<HttpClientService>();

      // Build options map
      Map<String, dynamic>? options;
      if (_timeMode == 'absolute' ||
          _overrideReltimeMinutes != null ||
          _overrideCompress != null ||
          _overrideRecurs != null ||
          _overrideMatch != null) {
        options = {};

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

      final flowState = context.read<CollectionFlowState>();
      final request = CreateJobRequest(
        publisherHost: flowState.publisherHost!,
        port: flowState.port!,
        username: flowState.username!,
        password: flowState.password!,
        nodes: _selectedNodeIps.toList(),
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
        _isStartingCollection = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start collection: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetDialog(CollectionFlowState flowState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Text('Reset Wizard?'),
          ],
        ),
        content: const Text(
          'This will clear all your selections and start over from the beginning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              flowState.reset();
              setState(() {
                _publisherHostController.clear();
                _portController.text = '22';
                _usernameController.clear();
                _passwordController.clear();
                _obscurePassword = true;
                _isDiscovering = false;
                _discoveryResult = null;
                _discoveryError = null;
                _selectedNodeIps.clear();
                _profiles = null;
                _selectedProfile = null;
                _isLoadingProfiles = false;
                _profilesErrorMessage = null;
                _timeMode = 'relative';
                _overrideReltimeMinutes = null;
                _startTime = null;
                _endTime = null;
                _timeRangeError = null;
                _overrideCompress = null;
                _overrideRecurs = null;
                _overrideMatch = null;
                _showOverrides = false;
                _isStartingCollection = false;
                _expandedStepIndex = 0;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
