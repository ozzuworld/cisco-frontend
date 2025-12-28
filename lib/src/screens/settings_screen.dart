import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/config_service.dart';
import '../services/http_client.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _rememberApiKey = false;
  bool _obscureApiKey = true;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final config = context.read<ConfigService>().config;
    _baseUrlController.text = config.baseUrl;
    _apiKeyController.text = config.apiKey ?? '';
    _rememberApiKey = config.rememberApiKey;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final configService = context.read<ConfigService>();

    final newConfig = AppConfig(
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim().isEmpty
          ? null
          : _apiKeyController.text.trim(),
      rememberApiKey: _rememberApiKey,
    );

    await configService.updateConfig(newConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final httpClient = context.read<HttpClientService>();

    final result = await httpClient.testConnection();

    setState(() {
      _isTesting = false;
      _testSuccess = result['success'] as bool;

      if (_testSuccess!) {
        _testResult = result['message'] as String;
      } else {
        final error = result['error'] as String?;
        final message = result['message'] as String?;
        final requestId = result['requestId'] as String?;
        final status = result['status'] as int?;

        final buffer = StringBuffer();

        if (status == 401) {
          buffer.write('API key required (401)');
        } else {
          buffer.write('${error ?? "Error"}: $message');
        }

        if (requestId != null) {
          buffer.write('\nRequest ID: $requestId');
        }

        if (status != null && status != 401) {
          buffer.write('\nStatus: $status');
        }

        _testResult = buffer.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Base URL Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'http://192.168.1.201:8000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Base URL is required';
                        }
                        if (!value.startsWith('http://') &&
                            !value.startsWith('https://')) {
                          return 'URL must start with http:// or https://';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: 'Enter your API key',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKey
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureApiKey = !_obscureApiKey;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureApiKey,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Remember API Key'),
                      subtitle: Text(
                        context.read<ConfigService>().config.rememberApiKey
                            ? 'Stored securely on device'
                            : 'Stored in memory only',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: _rememberApiKey,
                      onChanged: (value) {
                        setState(() {
                          _rememberApiKey = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Connection Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Connection Test',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.network_check),
                      label: Text(_isTesting
                          ? 'Testing Connection...'
                          : 'Test Connection'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16.0),
                      ),
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: _testSuccess!
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          border: Border.all(
                            color: _testSuccess!
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _testSuccess!
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _testSuccess!
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _testResult!,
                                style: TextStyle(
                                  color: _testSuccess!
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Storage Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Consumer<ConfigService>(
                      builder: (context, configService, child) {
                        return Text(
                          'Platform: ${_getPlatformInfo()}\n'
                          'Current Storage: ${configService.config.rememberApiKey ? "Secure Storage" : "Memory Only"}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlatformInfo() {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return 'Android (Secure Storage Available)';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      return 'iOS (Secure Storage Available)';
    } else {
      return 'Web/Desktop (Memory Storage Only)';
    }
  }
}
