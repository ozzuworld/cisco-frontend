import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/artifact.dart';
import '../services/http_client.dart';

class ArtifactsScreen extends StatefulWidget {
  final String jobId;

  const ArtifactsScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<ArtifactsScreen> createState() => _ArtifactsScreenState();
}

class _ArtifactsScreenState extends State<ArtifactsScreen> {
  List<Artifact>? _artifacts;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArtifacts();
  }

  Future<void> _fetchArtifacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      final artifacts = await httpClient.getJobArtifacts(widget.jobId);

      if (!mounted) return;

      setState(() {
        _artifacts = artifacts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadArtifact(String artifactId, String filename) async {
    final httpClient = Provider.of<HttpClientService>(context, listen: false);
    final url = httpClient.getArtifactDownloadUrl(widget.jobId, artifactId);

    await _launchDownload(url, filename);
  }

  Future<void> _downloadNodeArtifacts(String nodeIp) async {
    final httpClient = Provider.of<HttpClientService>(context, listen: false);
    final url = httpClient.getNodeArtifactsDownloadUrl(widget.jobId, nodeIp);

    await _launchDownload(url, 'node-$nodeIp-artifacts.zip');
  }

  Future<void> _downloadJobArtifacts() async {
    final httpClient = Provider.of<HttpClientService>(context, listen: false);
    final url = httpClient.getJobDownloadUrl(widget.jobId);

    await _launchDownload(url, 'job-${widget.jobId}-artifacts.zip');
  }

  Future<void> _launchDownload(String url, String filename) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not download $filename'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, List<Artifact>> _groupArtifactsByNode() {
    if (_artifacts == null) return {};

    final grouped = <String, List<Artifact>>{};
    for (final artifact in _artifacts!) {
      if (!grouped.containsKey(artifact.nodeIp)) {
        grouped[artifact.nodeIp] = [];
      }
      grouped[artifact.nodeIp]!.add(artifact);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Artifacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchArtifacts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading artifacts...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
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
                'Failed to load artifacts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchArtifacts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_artifacts == null || _artifacts!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No artifacts available',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'This job has not produced any artifacts yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildArtifactsList();
  }

  Widget _buildArtifactsList() {
    final groupedArtifacts = _groupArtifactsByNode();
    final nodeIps = groupedArtifacts.keys.toList()..sort();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                _buildSummaryCard(),
                const SizedBox(height: 16),

                // Per-node artifact lists
                ...nodeIps.map((nodeIp) {
                  final nodeArtifacts = groupedArtifacts[nodeIp]!;
                  return Column(
                    children: [
                      _buildNodeArtifactsCard(nodeIp, nodeArtifacts),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),

        // Bottom action buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalArtifacts = _artifacts!.length;
    final totalSize = _artifacts!.fold<int>(
      0,
      (sum, artifact) => sum + artifact.size,
    );
    final formattedTotalSize = _formatBytes(totalSize);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              Icons.description,
              'Total Artifacts',
              '$totalArtifacts',
              Colors.blue,
            ),
            _buildSummaryItem(
              Icons.storage,
              'Total Size',
              formattedTotalSize,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildNodeArtifactsCard(String nodeIp, List<Artifact> artifacts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Node: $nodeIp',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${artifacts.length} artifact(s)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _downloadNodeArtifacts(nodeIp),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download All'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...artifacts.map((artifact) => _buildArtifactItem(artifact)),
          ],
        ),
      ),
    );
  }

  Widget _buildArtifactItem(Artifact artifact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file,
            color: Colors.blue.shade300,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artifact.filename,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      artifact.timestamp,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.data_usage,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      artifact.formattedSize,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadArtifact(artifact.id, artifact.filename),
            tooltip: 'Download',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloadJobArtifacts,
              icon: const Icon(Icons.download),
              label: const Text('Download All Job Artifacts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
