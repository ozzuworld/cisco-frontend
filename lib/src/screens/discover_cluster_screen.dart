import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/http_client.dart';
import '../services/background_service.dart';
import '../models/cucm_node.dart';
import '../models/api_error.dart';
import '../models/collection_flow_state.dart';
import '../models/background_preset_registry.dart';
import '../ui/background_renderer.dart';
import '../ui/design_tokens.dart';
import 'settings_screen.dart';
import 'profile_selection_screen.dart';

class DiscoverClusterScreen extends StatefulWidget {
  const DiscoverClusterScreen({super.key});

  @override
  State<DiscoverClusterScreen> createState() => _DiscoverClusterScreenState();
}

class _DiscoverClusterScreenState extends State<DiscoverClusterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publisherHostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isDiscovering = false;
  DiscoveryResponse? _discoveryResult;
  ApiError? _discoveryError;

  // Node selection state
  final Set<String> _selectedNodeIps = {};

  @override
  void dispose() {
    _publisherHostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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

      // No SnackBar needed - inline message is shown in the UI
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
            // Show backend error details
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                Navigator.pop(context); // Close dialog
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

  void _clearSelection() {
    setState(() {
      _selectedNodeIps.clear();
    });

    // Update flow state
    context.read<CollectionFlowState>().setSelectedNodes(_selectedNodeIps.toList());
  }

  void _proceedToNextScreen() {
    if (_selectedNodeIps.isEmpty) return;

    // Navigate to profile selection screen with selected node IPs and CUCM credentials
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSelectionScreen(
          selectedNodeIps: _selectedNodeIps.toList(),
          publisherHost: _publisherHostController.text,
          port: int.parse(_portController.text),
          username: _usernameController.text,
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundBase,
      appBar: AppBar(
        title: Text('Discover Cluster', style: TextStyle(color: DesignTokens.textPrimary)),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.textPrimary),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                // Blue gradient background - using NIGHT preset for true blue colors
                Positioned.fill(
                  child: BackgroundRenderer(
                    preset: BackgroundPresetRegistry.night,
                    enabled: true,
                  ),
                ),
                // Main content
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: 16.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 100.0, // Extra padding for bottom button overlay
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Discovery Form
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Publisher Credentials',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                      const SizedBox(height: 16),
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
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                            _isDiscovering ? 'Discovering...' : 'Discover'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Discovery Results
            if (_discoveryResult != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Discovered ${_discoveryResult!.nodes.length} Node(s)',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (_discoveryResult!.hasNodes) ...[
                            TextButton.icon(
                              onPressed: _selectAllNodes,
                              icon: const Icon(Icons.select_all, size: 18),
                              label: const Text('All'),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: _clearSelection,
                              icon: const Icon(Icons.clear, size: 18),
                              label: const Text('Clear'),
                            ),
                          ],
                        ],
                      ),
                      if (_discoveryResult!.hasNodes) ...[
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedNodeIps.isEmpty
                                ? Colors.red.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: _selectedNodeIps.isEmpty
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
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
                                  _selectedNodeIps.isEmpty
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  key: ValueKey(_selectedNodeIps.isEmpty),
                                  size: 18,
                                  color: _selectedNodeIps.isEmpty
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(
                                    _selectedNodeIps.isEmpty
                                        ? 'Select at least one node to proceed'
                                        : '${_selectedNodeIps.length} node(s) selected',
                                    key: ValueKey('${_selectedNodeIps.length}-${_selectedNodeIps.isEmpty}'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: _selectedNodeIps.isEmpty
                                          ? Colors.red.shade200
                                          : Colors.blue.shade200,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_discoveryResult!.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'No nodes discovered',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check your credentials and try again.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              if (_discoveryResult!.rawOutput != null) ...[
                                const SizedBox(height: 8),
                                const Text('Raw output:'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    _discoveryResult!.rawOutput!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (_discoveryResult!.rawOutputTruncated)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '(Output truncated)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ] else
                        ..._discoveryResult!.nodes.map((node) => _buildNodeCard(node)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
                // Bottom navigation bar as positioned overlay
                if (_discoveryResult != null && _discoveryResult!.hasNodes)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: DesignTokens.backgroundBase.withOpacity(0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: ElevatedButton.icon(
                          onPressed:
                              _selectedNodeIps.isEmpty ? null : _proceedToNextScreen,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            'Continue with ${_selectedNodeIps.length} node${_selectedNodeIps.length != 1 ? 's' : ''}',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNodeCard(CucmNode node) {
    final isSelected = _selectedNodeIps.contains(node.ip);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
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
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.computer,
                      color: node.role?.toLowerCase() == 'publisher'
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.displayName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (node.fqdn != null)
                          Text(
                            node.fqdn!,
                            style: Theme.of(context).textTheme.bodySmall,
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
                            ? Colors.blue.withOpacity(0.8)
                            : Colors.grey.withOpacity(0.6),
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
}
