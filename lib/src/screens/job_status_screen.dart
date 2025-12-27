import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/job_status.dart';
import '../services/http_client.dart';
import 'artifacts_screen.dart';

class JobStatusScreen extends StatefulWidget {
  final String jobId;

  const JobStatusScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobStatusScreen> createState() => _JobStatusScreenState();
}

class _JobStatusScreenState extends State<JobStatusScreen> {
  JobStatus? _jobStatus;
  String? _errorMessage;
  Timer? _pollingTimer;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _startPolling() {
    // Fetch immediately
    _fetchJobStatus();

    // Poll every 2 seconds
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchJobStatus(),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchJobStatus() async {
    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      final status = await httpClient.getJobStatus(widget.jobId);

      if (!mounted) return;

      setState(() {
        _jobStatus = status;
        _errorMessage = null;
      });

      // Stop polling if terminal status
      if (status.isTerminal) {
        _stopPolling();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });

      // Don't stop polling on error, retry will happen on next tick
    }
  }

  Future<void> _cancelJob() async {
    if (_jobStatus == null || !_jobStatus!.isCancellable) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      await httpClient.cancelJob(widget.jobId);

      if (!mounted) return;

      // Fetch updated status immediately
      await _fetchJobStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job cancellation requested'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel job: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  void _copyJobId() {
    Clipboard.setData(ClipboardData(text: widget.jobId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'partial':
        return Colors.orange;
      case 'running':
        return Colors.blue;
      case 'queued':
        return Colors.grey;
      case 'cancelled':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'partial':
        return Icons.warning;
      case 'running':
        return Icons.refresh;
      case 'queued':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchJobStatus,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Home',
          ),
        ],
      ),
      body: _jobStatus == null
          ? _buildLoadingView()
          : _buildJobStatusView(),
    );
  }

  Widget _buildLoadingView() {
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
                'Failed to load job status',
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
                onPressed: _fetchJobStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading job status...'),
        ],
      ),
    );
  }

  Widget _buildJobStatusView() {
    final status = _jobStatus!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Status Card
          _buildOverallStatusCard(status),
          const SizedBox(height: 16),

          // Progress Card
          _buildProgressCard(status),
          const SizedBox(height: 16),

          // Timestamps Card
          _buildTimestampsCard(status),
          const SizedBox(height: 16),

          // Time Range Card (if time range is specified)
          if (status.startTime != null || status.endTime != null || status.reltimeMinutes != null) ...[
            _buildTimeRangeCard(status),
            const SizedBox(height: 16),
          ],

          // Per-Node Status List
          _buildNodeStatusList(status),
          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(status),
        ],
      ),
    );
  }

  Widget _buildOverallStatusCard(JobStatus status) {
    final statusColor = _getStatusColor(status.status);
    final statusIcon = _getStatusIcon(status.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${status.status.toUpperCase()}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Job ID: ${status.jobId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: _copyJobId,
                  tooltip: 'Copy Job ID',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(JobStatus status) {
    final hasNodes = status.totalNodes > 0;
    final progressPercent = (status.progress * 100).toStringAsFixed(0);

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
                  'Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  hasNodes
                      ? '${status.completedNodes} / ${status.totalNodes} nodes'
                      : 'No nodes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasNodes) ...[
              LinearProgressIndicator(
                value: status.progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 8),
              Text(
                '$progressPercent% complete',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else
              Text(
                'This job has no nodes to process',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampsCard(JobStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timestamps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildTimestampRow(
              'Started',
              status.startedAt ?? 'Not started',
              Icons.play_arrow,
            ),
            if (status.completedAt != null) ...[
              const SizedBox(height: 8),
              _buildTimestampRow(
                'Completed',
                status.completedAt!,
                Icons.check_circle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeCard(JobStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Collection Time Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (status.reltimeMinutes != null) ...[
              Row(
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Last ${status.reltimeMinutes} minutes',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else if (status.startTime != null && status.endTime != null) ...[
              Row(
                children: [
                  Icon(Icons.date_range, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Text(
                          'Absolute time range',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTimestampRow(
                'Start Time',
                _formatIso8601DateTime(status.startTime!),
                Icons.play_arrow,
              ),
              const SizedBox(height: 8),
              _buildTimestampRow(
                'End Time',
                _formatIso8601DateTime(status.endTime!),
                Icons.stop,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatIso8601DateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final date = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
      return '$date $time';
    } catch (e) {
      return isoString; // Return original if parsing fails
    }
  }

  Widget _buildNodeStatusList(JobStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Node Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...status.nodes.map((node) => _buildNodeStatusItem(node)),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeStatusItem(NodeStatus node) {
    final statusColor = _getStatusColor(node.status);
    final statusIcon = _getStatusIcon(node.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: node.isFailed ? Colors.red.shade50 : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.node,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  node.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (node.error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(JobStatus status) {
    return Column(
      children: [
        if (status.isCancellable)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCancelling ? null : _cancelJob,
              icon: _isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel),
              label: Text(_isCancelling ? 'Cancelling...' : 'Cancel Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        if (status.hasArtifacts) ...[
          if (status.isCancellable) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ArtifactsScreen(jobId: status.jobId),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: Text('View Artifacts (${status.totalArtifactCount})'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text('Return to Home'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
