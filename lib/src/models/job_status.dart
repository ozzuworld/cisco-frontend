/// Node status within a job
class NodeStatus {
  final String node;
  final String status;
  final String? error;

  NodeStatus({
    required this.node,
    required this.status,
    this.error,
  });

  factory NodeStatus.fromJson(Map<String, dynamic> json) {
    return NodeStatus(
      node: json['node'] as String,
      status: json['status'] as String,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node': node,
      'status': status,
      if (error != null) 'error': error,
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRunning => status == 'running';
  bool get isQueued => status == 'queued';
}

/// Job status response
class JobStatus {
  final String jobId;
  final String status;
  final String? startedAt;
  final String? completedAt;
  final int totalNodes;
  final int completedNodes;
  final List<NodeStatus> nodes;
  final List<String> artifacts;

  JobStatus({
    required this.jobId,
    required this.status,
    this.startedAt,
    this.completedAt,
    required this.totalNodes,
    required this.completedNodes,
    required this.nodes,
    required this.artifacts,
  });

  factory JobStatus.fromJson(Map<String, dynamic> json) {
    final nodesList = json['nodes'] as List<dynamic>? ?? [];
    final artifactsList = json['artifacts'] as List<dynamic>? ?? [];

    // Parse nodes list
    final parsedNodes = nodesList
        .map((node) => NodeStatus.fromJson(node as Map<String, dynamic>))
        .toList();

    // Get total_nodes from backend, fallback to nodes list length
    final totalNodes = json['total_nodes'] as int? ?? parsedNodes.length;

    // Get completed_nodes from backend, fallback to counting completed nodes in list
    final completedNodes = json['completed_nodes'] as int? ??
        parsedNodes.where((node) => node.isCompleted).length;

    return JobStatus(
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      totalNodes: totalNodes,
      completedNodes: completedNodes,
      nodes: parsedNodes,
      artifacts: artifactsList.map((a) => a.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      'total_nodes': totalNodes,
      'completed_nodes': completedNodes,
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'artifacts': artifacts,
    };
  }

  // Terminal statuses (stop polling)
  bool get isTerminal =>
      status == 'succeeded' ||
      status == 'failed' ||
      status == 'partial' ||
      status == 'cancelled';

  // Cancellable statuses
  bool get isCancellable => status == 'queued' || status == 'running';

  // Progress percentage
  double get progress =>
      totalNodes > 0 ? completedNodes / totalNodes : 0.0;

  bool get hasArtifacts => artifacts.isNotEmpty;
}
