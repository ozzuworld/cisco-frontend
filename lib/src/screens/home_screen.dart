import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/config_service.dart';
import 'settings_screen.dart';
import 'collection_wizard_screen.dart';
import 'job_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cisco Frontend'),
        actions: [
          Consumer<ConfigService>(
            builder: (context, configService, child) {
              if (!configService.config.hasApiKey) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JobHistoryScreen(),
                    ),
                  );
                },
                tooltip: 'Job History',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<ConfigService>(
            builder: (context, configService, child) {
              final config = configService.config;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    config.hasApiKey
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 80,
                    color: config.hasApiKey ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    config.hasApiKey
                        ? 'API Configured'
                        : 'API Not Configured',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            context,
                            'Base URL',
                            config.baseUrl,
                            Icons.link,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'API Key',
                            config.hasApiKey ? '********' : 'Not set',
                            Icons.key,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Remember',
                            config.rememberApiKey ? 'Enabled' : 'Disabled',
                            Icons.memory,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!config.hasApiKey)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Configure API'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  if (config.hasApiKey) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CollectionWizardScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Start Collection Wizard'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const JobHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View Job History'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: Consumer<ConfigService>(
        builder: (context, configService, child) {
          if (!configService.config.hasApiKey) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectionWizardScreen(),
                ),
              );
            },
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Wizard'),
            tooltip: 'Start Collection Wizard',
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
