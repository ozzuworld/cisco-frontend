import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../models/collection_flow_state.dart';
import '../models/cucm_node.dart';
import '../models/profile.dart';
import '../models/api_error.dart';
import '../services/http_client.dart';
import '../ui/design_tokens.dart';
import '../ui/glass_card.dart';
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

  // Scroll controller for auto-scroll (FE-019.8)
  final ScrollController _scrollController = ScrollController();

  // Global keys for each step to track positions
  final List<GlobalKey> _stepKeys = List.generate(5, (_) => GlobalKey());

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
    _scrollController.dispose();
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

  /// Auto-scroll to a specific step (FE-019.8)
  void _scrollToStep(int stepIndex) {
    // Delay to ensure the expansion animation has started
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final key = _stepKeys[stepIndex];
      final context = key.currentContext;
      if (context == null) return;

      // Get the RenderBox and its position
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final scrollOffset = position.dy + _scrollController.offset - 100; // 100px padding from top

      // Animate to the step position
      _scrollController.animateTo(
        scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CollectionFlowState>(
      builder: (context, flowState, child) {
        final currentStepIndex = _getCurrentStepIndex(flowState);

        // Auto-expand and scroll to the current step when it changes (FE-019.8)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_expandedStepIndex != currentStepIndex) {
            setState(() {
              _expandedStepIndex = currentStepIndex;
            });

            // Auto-scroll to the newly unlocked step
            _scrollToStep(currentStepIndex);
          }
        });

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          appBar: AppBar(
            title: const Text('Collection Wizard', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Wizard',
                onPressed: () => _showResetDialog(flowState),
              ),
            ],
          ),
          // FE-UI-041: Dark background with subtle aurora glow
          body: Container(
            decoration: BoxDecoration(
              // Near-black base
              color: const Color(0xFF0A0A0F),
              // Layered aurora glow effect
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  Colors.blue.shade900.withOpacity(0.15),
                  Colors.purple.shade900.withOpacity(0.10),
                  const Color(0xFF0A0A0F),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Additional glow spots for aurora effect
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.teal.shade700.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  left: -150,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purple.shade800.withOpacity(0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Soft vignette on edges
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0A0A0F).withOpacity(0.6),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
                // Main content
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Center(
                    child: ConstrainedBox(
                      // FE-UI-043: Max width for desktop
                      constraints: const BoxConstraints(maxWidth: 950),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // FE-039: Floating timeline chips
                          _buildTimelineChips(flowState, currentStepIndex),
                          const SizedBox(height: 20),

                          // FE-038: Show completed steps as small chips
                          if (currentStepIndex > 0)
                            _buildCompletedStepsChips(flowState, currentStepIndex),

                          if (currentStepIndex > 0)
                            const SizedBox(height: 16),

                          // FE-038: Single focused card - only show current step
                          // FE-040: Animated transition between steps
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.05),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCurrentStepCard(flowState, currentStepIndex),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// FE-044: Breadcrumb-style timeline navigation (text-first, neutral)
  Widget _buildTimelineChips(CollectionFlowState flowState, int currentStepIndex) {
    final steps = [
      {'title': 'Discovery', 'icon': Icons.cloud_done},
      {'title': 'Nodes', 'icon': Icons.devices},
      {'title': 'Profile', 'icon': Icons.description},
      {'title': 'Time', 'icon': Icons.schedule},
      {'title': 'Start', 'icon': Icons.play_arrow},
    ];

    return Wrap(
      spacing: DesignTokens.spacingInline,
      runSpacing: DesignTokens.spacingInline,
      alignment: WrapAlignment.center,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index < currentStepIndex;
        final isCurrent = index == currentStepIndex;
        final isUnlocked = _isStepUnlocked(index, flowState);

        if (!isUnlocked && !isCurrent) {
          return const SizedBox.shrink();
        }

        return BreadcrumbChip(
          isSelected: isCurrent,
          isCompleted: isCompleted,
          onTap: isCompleted
              ? () {
                  setState(() {
                    _expandedStepIndex = index;
                  });
                  _scrollToStep(index);
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FE-UI-044: Checkmark for completed steps
              if (isCompleted)
                Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              if (isCompleted) const SizedBox(width: 6),
              // FE-UI-044: Text-first design with light colors for dark background
              Text(
                step['title'] as String,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                  color: isCurrent
                      ? Colors.white
                      : isCompleted
                          ? Colors.white.withOpacity(0.5)
                          : Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// FE-038: Completed steps shown as small chips
  Widget _buildCompletedStepsChips(CollectionFlowState flowState, int currentStepIndex) {
    final completedSteps = <Map<String, dynamic>>[];

    if (currentStepIndex > 0) {
      completedSteps.add({
        'title': 'Cluster Discovered',
        'icon': Icons.check_circle,
        'detail': _discoveryResult?.nodes.length.toString() ?? '0',
      });
    }
    if (currentStepIndex > 1) {
      completedSteps.add({
        'title': '${_selectedNodeIps.length} Nodes Selected',
        'icon': Icons.devices,
      });
    }
    if (currentStepIndex > 2) {
      completedSteps.add({
        'title': _selectedProfile?.name ?? 'Profile Selected',
        'icon': Icons.description,
      });
    }
    if (currentStepIndex > 3) {
      completedSteps.add({
        'title': 'Time Configured',
        'icon': Icons.schedule,
      });
    }

    if (completedSteps.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: DesignTokens.spacingInline,
      runSpacing: DesignTokens.spacingInline,
      children: completedSteps.map((step) {
        return Container(
          // FE-043: Compact padding
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            // FE-UI-044: Subtle background for dark theme
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                size: 12,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                step['title'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// FE-038: Single focused card showing only current step
  Widget _buildCurrentStepCard(CollectionFlowState flowState, int currentStepIndex) {
    final stepData = _getStepData(currentStepIndex);

    return GlassCard(
      key: ValueKey('step_$currentStepIndex'),
      // FE-043: Reduced header padding
      padding: const EdgeInsets.all(DesignTokens.paddingLarge),
      header: Row(
        children: [
          // FE-UI-042: Icon with subtle background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.accentColor.shade700.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DesignTokens.accentColor.shade500.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              stepData['icon'] as IconData,
              size: 20,
              color: DesignTokens.accentColor.shade300,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepData['title'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (stepData['subtitle'] != null)
                  Text(
                    stepData['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Text(
              'Step ${currentStepIndex + 1}/5',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
      body: _getStepContent(currentStepIndex, flowState),
    );
  }

  Map<String, dynamic> _getStepData(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return {
          'title': 'Cluster Discovery',
          'subtitle': 'Enter your CUCM Publisher credentials',
          'icon': Icons.cloud_done,
        };
      case 1:
        return {
          'title': 'Node Selection',
          'subtitle': 'Choose which nodes to collect from',
          'icon': Icons.devices,
        };
      case 2:
        return {
          'title': 'Profile Selection',
          'subtitle': 'Select a collection profile',
          'icon': Icons.description,
        };
      case 3:
        return {
          'title': 'Time Configuration',
          'subtitle': 'Configure time range for collection',
          'icon': Icons.schedule,
        };
      case 4:
        return {
          'title': 'Review & Start',
          'subtitle': 'Review configuration and start collection',
          'icon': Icons.play_arrow,
        };
      default:
        return {
          'title': 'Unknown Step',
          'icon': Icons.help,
        };
    }
  }

  Widget _getStepContent(int stepIndex, CollectionFlowState flowState) {
    switch (stepIndex) {
      case 0:
        return _buildClusterDiscoveryContent(flowState);
      case 1:
        return _buildNodeSelectionContent(flowState);
      case 2:
        return _buildProfileSelectionContent(flowState);
      case 3:
        return _buildTimeConfigurationContent(flowState);
      case 4:
        return _buildReviewStartContent(flowState);
      default:
        return const Text('Unknown step');
    }
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
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        // FE-032: Constrain form width for better readability
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DesignTokens.formMaxWidth),
            child: Form(
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
              const SizedBox(height: 20),
              // FE-045: Primary CTA with accent color
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
                  backgroundColor: DesignTokens.accentColor.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                  ),
                ),
              ),
            ],
          ),
            ),
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
      // FE-043: Compact padding
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        // FE-041: Neutral colors, no green
        color: DesignTokens.neutralColor.shade100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: DesignTokens.neutralColor.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: DesignTokens.neutralColor.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Discovery Successful!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Found ${result.nodes.length} node${result.nodes.length != 1 ? 's' : ''} in the cluster. Continue to Step 2 to select nodes.',
            style: TextStyle(
              fontSize: 12,
              color: DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: DesignTokens.spacingChip,
            runSpacing: DesignTokens.spacingInline,
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

    // Reset all downstream state when credentials change (FE-019.7)
    setState(() {
      _isDiscovering = true;
      _discoveryResult = null;
      _discoveryError = null;

      // Clear all downstream selections
      _selectedNodeIps.clear();
      _selectedProfile = null;
      _profiles = null;

      // Clear time configuration
      _timeMode = 'relative';
      _overrideReltimeMinutes = null;
      _startTime = null;
      _endTime = null;
      _timeRangeError = null;

      // Clear overrides
      _overrideCompress = null;
      _overrideRecurs = null;
      _overrideMatch = null;
      _showOverrides = false;
    });

    // Reset flow state to initial
    if (mounted) {
      context.read<CollectionFlowState>().reset();
    }

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

        // FE-033: Wrap layout for nodes (content-sized, not grid-based)
        Text(
          'Discovered ${_discoveryResult!.nodes.length} node(s)',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        // FE-033: Use Wrap for natural flow and content-based sizing
        Wrap(
          spacing: DesignTokens.spacingComponent,
          runSpacing: DesignTokens.spacingComponent,
          children: _discoveryResult!.nodes.map((node) {
            return _buildNodeChip(node);
          }).toList(),
        ),
      ],
    );
  }

  // FE-033: Compact node chip with Wrap layout (content-based width)
  Widget _buildNodeChip(CucmNode node) {
    final isSelected = _selectedNodeIps.contains(node.ip);
    final isPublisher = node.role?.toLowerCase() == 'publisher';

    return InkWell(
      onTap: () => _toggleNodeSelection(node.ip),
      borderRadius: DesignTokens.chipBorderRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPublisher ? Colors.blue.shade50 : Colors.grey.shade50)
              : Colors.white,
          borderRadius: DesignTokens.chipBorderRadius,
          border: Border.all(
            color: isSelected
                ? (isPublisher ? Colors.blue.shade400 : Colors.grey.shade400)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.06 : 0.03),
              blurRadius: isSelected ? 6 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.computer,
              size: 18,
              color: isPublisher ? Colors.blue.shade600 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            // Node name
            Text(
              node.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            // Role badge
            if (node.role != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPublisher ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  node.role!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 18,
                color: isPublisher ? Colors.blue.shade600 : Colors.grey.shade600,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // FE-027: Compact node card for grid layout (kept for reference, not currently used)
  Widget _buildNodeCard(CucmNode node) {
    final isSelected = _selectedNodeIps.contains(node.ip);
    final isPublisher = node.role?.toLowerCase() == 'publisher';

    return InkWell(
      onTap: () => _toggleNodeSelection(node.ip),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPublisher ? Colors.blue.shade50 : Colors.grey.shade50)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isPublisher ? Colors.blue.shade400 : Colors.grey.shade400)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header with icon and checkbox
            Row(
              children: [
                Icon(
                  Icons.computer,
                  size: 20,
                  color: isPublisher ? Colors.blue.shade600 : Colors.grey.shade600,
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: isPublisher ? Colors.blue.shade600 : Colors.grey.shade600,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Node name
            Text(
              node.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // IP address
            Text(
              node.ip,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Role badge
            if (node.role != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPublisher ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  node.role!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Old detailed node card method - remove or keep for reference
  Widget _buildNodeCardDetailed(CucmNode node) {
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
    // Load profiles on first display (FE-019.9 fix: use post-frame callback)
    if (_profiles == null && !_isLoadingProfiles && _profilesErrorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _profiles == null && !_isLoadingProfiles) {
          _loadProfiles();
        }
      });
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

    // FE-030: Show selected profile with "Change" button, or grid of profiles
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

        // Show selected profile with "Change" button
        if (_selectedProfile != null) ...[
          _buildSelectedProfileCard(_selectedProfile!),
          const SizedBox(height: 12),
        ] else ...[
          // Show grid of profiles for selection
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 800 ? 3 : (width > 500 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _profiles!.length,
                itemBuilder: (context, index) {
                  return _buildProfileCard(_profiles![index]);
                },
              );
            },
          ),
        ],
      ],
    );
  }

  // FE-030: Selected profile card with "Change" button
  Widget _buildSelectedProfileCard(Profile profile) {
    return Container(
      // FE-043: Compact padding
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // FE-041: Accent color instead of green
        color: DesignTokens.accentColor.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
        border: Border.all(color: DesignTokens.accentColor.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: DesignTokens.accentColor.shade600, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                    if (profile.description.isNotEmpty)
                      Text(
                        profile.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // FE-045: Secondary action as text button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedProfile = null;
                    // Clear time config when changing profile
                    _timeMode = 'relative';
                    _overrideReltimeMinutes = null;
                    _startTime = null;
                    _endTime = null;
                    _timeRangeError = null;
                  });
                  final flowState = context.read<CollectionFlowState>();
                  flowState.setSelectedProfile(null);
                  flowState.setTimeMode(isRelative: true);
                  flowState.setRelativeTime(null);
                  flowState.setAbsoluteTime(startTime: null, endTime: null);
                },
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Change', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: DesignTokens.accentColor.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: DesignTokens.paddingStandard,
            runSpacing: DesignTokens.spacingInline,
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
    );
  }

  Future<void> _loadProfiles() async {
    // FE-019.9: Enhanced error handling and logging
    if (!mounted) return;

    setState(() {
      _isLoadingProfiles = true;
      _profilesErrorMessage = null;
    });

    try {
      final httpClient = context.read<HttpClientService>();

      // Add debug logging
      debugPrint('[CollectionWizard] Loading profiles...');

      final profiles = await httpClient.getProfiles();

      debugPrint('[CollectionWizard] Loaded ${profiles.length} profiles');

      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _isLoadingProfiles = false;
      });
    } catch (e, stackTrace) {
      debugPrint('[CollectionWizard] Profile loading failed: $e');
      debugPrint('[CollectionWizard] Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _profilesErrorMessage = e.toString();
        _isLoadingProfiles = false;
      });

      // Show snackbar for user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profiles: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadProfiles,
            ),
          ),
        );
      }
    }
  }

  // FE-030: Compact profile card for grid layout
  Widget _buildProfileCard(Profile profile) {
    return InkWell(
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header with icon
            Row(
              children: [
                Icon(Icons.description, size: 20, color: Colors.purple.shade600),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            // Profile name
            Text(
              profile.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (profile.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                profile.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            // Icons row
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${profile.reltimeMinutes}m',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 12),
                if (profile.compress)
                  Icon(Icons.compress, size: 14, color: Colors.blue.shade600),
                if (profile.recurs)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.repeat, size: 14, color: Colors.orange.shade600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Old full profile card - keeping for reference
  Widget _buildProfileCardOld(Profile profile) {
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
                              // FE-041: Accent color for selected state
                              color: DesignTokens.accentColor.shade100,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                              border: Border.all(
                                color: DesignTokens.accentColor.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: DesignTokens.accentColor.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Selected',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: DesignTokens.accentColor.shade900,
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
                spacing: DesignTokens.paddingStandard,
                runSpacing: DesignTokens.spacingInline,
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

              // Validate before updating flow state
              if (dateTime != null && _endTime != null) {
                final isValid = _validateTimeRange();
                if (isValid) {
                  context.read<CollectionFlowState>().setAbsoluteTime(
                        startTime: dateTime,
                        endTime: _endTime,
                      );
                } else {
                  // Clear flow state if invalid
                  context.read<CollectionFlowState>().setAbsoluteTime(
                        startTime: null,
                        endTime: null,
                      );
                }
              } else {
                // Update flow state with partial selection
                context.read<CollectionFlowState>().setAbsoluteTime(
                      startTime: dateTime,
                      endTime: _endTime,
                    );
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

              // Validate before updating flow state
              if (dateTime != null && _startTime != null) {
                final isValid = _validateTimeRange();
                if (isValid) {
                  context.read<CollectionFlowState>().setAbsoluteTime(
                        startTime: _startTime,
                        endTime: dateTime,
                      );
                } else {
                  // Clear flow state if invalid
                  context.read<CollectionFlowState>().setAbsoluteTime(
                        startTime: null,
                        endTime: null,
                      );
                }
              } else {
                // Update flow state with partial selection
                context.read<CollectionFlowState>().setAbsoluteTime(
                      startTime: _startTime,
                      endTime: dateTime,
                    );
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
          iconColor: DesignTokens.accentColor.shade700,
        ),
        const SizedBox(height: 8),
        // Expandable node list
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
            childrenPadding: const EdgeInsets.only(left: 40, right: 8, bottom: 8),
            title: Text(
              'View selected nodes',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            children: _discoveryResult!.nodes
                .where((node) => _selectedNodeIps.contains(node.ip))
                .map((node) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.computer,
                            size: 14,
                            color: node.role?.toLowerCase() == 'publisher'
                                ? Colors.blue.shade600
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              node.displayName,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (node.role != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: node.role?.toLowerCase() == 'publisher'
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                node.role!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: node.role?.toLowerCase() == 'publisher'
                                      ? Colors.blue.shade800
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        // FE-041: All icons use neutral colors, no rainbow effect
        _buildSummaryItem(
          icon: Icons.description,
          label: 'Profile',
          value: _selectedProfile!.name,
          iconColor: DesignTokens.neutralColor.shade600,
        ),
        const SizedBox(height: 10),
        _buildSummaryItem(
          icon: _timeMode == 'relative' ? Icons.access_time : Icons.date_range,
          label: 'Time Range',
          value: _getTimeRangeSummary(),
          iconColor: DesignTokens.neutralColor.shade600,
        ),
        const SizedBox(height: 10),
        _buildSummaryItem(
          icon: Icons.compress,
          label: 'Compress',
          value: compress ? 'Enabled' : 'Disabled',
          iconColor: DesignTokens.neutralColor.shade600,
        ),
        const SizedBox(height: 10),
        _buildSummaryItem(
          icon: Icons.repeat,
          label: 'Recursive',
          value: recurs ? 'Enabled' : 'Disabled',
          iconColor: DesignTokens.neutralColor.shade600,
        ),
        if (match.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildSummaryItem(
            icon: Icons.filter_alt,
            label: 'Match Pattern',
            value: match,
            iconColor: DesignTokens.neutralColor.shade600,
          ),
        ],
        const SizedBox(height: 20),

        // FE-045: Primary CTA - Start Collection
        ElevatedButton.icon(
          onPressed: _isStartingCollection ? null : _startCollection,
          icon: Icon(
            _isStartingCollection ? Icons.hourglass_empty : Icons.play_arrow,
            size: 20,
          ),
          label: Text(
            _isStartingCollection ? 'Starting Collection...' : 'Start Collection',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            // FE-041: Accent color only, no green
            backgroundColor: DesignTokens.accentColor.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
            ),
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
