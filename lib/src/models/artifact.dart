/// Artifact metadata
class Artifact {
  final String id;
  final String filename;
  final int size;
  final String timestamp;
  final String nodeIp;

  Artifact({
    required this.id,
    required this.filename,
    required this.size,
    required this.timestamp,
    required this.nodeIp,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      id: json['id'] as String,
      filename: json['filename'] as String,
      size: json['size'] as int,
      timestamp: json['timestamp'] as String,
      nodeIp: json['node_ip'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'size': size,
      'timestamp': timestamp,
      'node_ip': nodeIp,
    };
  }

  /// Format file size in human-readable format
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
