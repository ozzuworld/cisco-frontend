import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job_status.dart';
import '../services/http_client.dart';
import 'job_status_screen.dart';

class JobHistoryScreen extends StatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  State<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen> {
  List<JobStatus> _jobs = [];
  List<JobStatus> _filteredJobs = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  Set<String> _statusFilters = {};

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _searchController.addListener(_filterJobs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      final jobs = await httpClient.listJobs();

      // Sort by most recent first (assumes jobId or startedAt ordering)
      jobs.sort((a, b) {
        if (a.startedAt != null && b.startedAt != null) {
          return b.startedAt!.compareTo(a.startedAt!);
        }
        return b.jobId.compareTo(a.jobId);
      });

      if (!mounted) return;

      setState(() {
        _jobs = jobs;
        _filteredJobs = jobs;
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

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredJobs = _jobs.where((job) {
        // Apply status filter
        if (_statusFilters.isNotEmpty && !_statusFilters.contains(job.status.toLowerCase())) {
          return false;
        }

        // Apply search filter
        if (query.isEmpty) return true;

        // Search by job ID
        if (job.jobId.toLowerCase().contains(query)) return true;

        // Search by node IP
        if (job.nodes.any((node) => node.node.toLowerCase().contains(query))) {
          return true;
        }

        return false;
      }).toList();
    });
  }

  void _toggleStatusFilter(String status) {
    setState(() {
      if (_statusFilters.contains(status)) {
        _statusFilters.remove(status);
      } else {
        _statusFilters.add(status);
      }
      _filterJobs();
    });
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
        return Colors.grey;
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
      default:
        return Icons.help;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  String _getTimeRangeDisplay(JobStatus job) {
    if (job.reltimeMinutes != null) {
      return 'Last ${job.reltimeMinutes}m';
    } else if (job.startTime != null && job.endTime != null) {
      return 'Custom range';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by job ID or node IP...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // Status filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                _buildFilterChip('succeeded', Colors.green),
                _buildFilterChip('failed', Colors.red),
                _buildFilterChip('partial', Colors.orange),
                _buildFilterChip('running', Colors.blue),
                _buildFilterChip('queued', Colors.grey),
                _buildFilterChip('cancelled', Colors.grey),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Job list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _filteredJobs.isEmpty
                        ? _buildEmptyView()
                        : _buildJobList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, Color color) {
    final isSelected = _statusFilters.contains(status);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(status.toUpperCase()),
        selected: isSelected,
        onSelected: (_) => _toggleStatusFilter(status),
        selectedColor: color.withOpacity(0.3),
        checkmarkColor: color,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildJobList() {
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _filteredJobs.length,
        itemBuilder: (context, index) {
          final job = _filteredJobs[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  Widget _buildJobCard(JobStatus job) {
    final statusColor = _getStatusColor(job.status);
    final statusIcon = _getStatusIcon(job.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => JobStatusScreen(jobId: job.jobId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status and timestamp
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTimestamp(job.startedAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Job details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.fingerprint,
                      'Job ID',
                      job.jobId.length > 12
                          ? '${job.jobId.substring(0, 12)}...'
                          : job.jobId,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.devices,
                      'Nodes',
                      '${job.completedNodes}/${job.totalNodes}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.schedule,
                      'Time Range',
                      _getTimeRangeDisplay(job),
                    ),
                  ),
                  if (job.hasArtifacts)
                    Expanded(
                      child: _buildDetailItem(
                        Icons.download,
                        'Artifacts',
                        job.totalArtifactCount.toString(),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty || _statusFilters.isNotEmpty
                ? 'No jobs match your filters'
                : 'No jobs yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _statusFilters.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Start a collection to see it here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load jobs',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadJobs,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
