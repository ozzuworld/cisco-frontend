/// Artifact metadata
class Artifact {
  final String artifactId;
  final String node;
  final String path;
  final String filename;
  final int sizeBytes;
  final String createdAt;

  Artifact({
    required this.artifactId,
    required this.node,
    required this.path,
    required this.filename,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) {
    try {
      return Artifact(
        artifactId: json['artifact_id'] as String? ?? '',
        node: json['node'] as String? ?? '',
        path: json['path'] as String? ?? '',
        filename: json['filename'] as String? ?? '',
        sizeBytes: json['size_bytes'] as int? ?? 0,
        createdAt: json['created_at'] as String? ?? '',
      );
    } catch (e) {
      // Log the problematic JSON for debugging
      // ignore: avoid_print
      print('Error parsing artifact JSON: $e');
      // ignore: avoid_print
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'artifact_id': artifactId,
      'node': node,
      'path': path,
      'filename': filename,
      'size_bytes': sizeBytes,
      'created_at': createdAt,
    };
  }

  /// Format file size in human-readable format
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Backward compatibility getters
  String get id => artifactId;
  String get nodeIp => node;
  int get size => sizeBytes;
  String get timestamp => createdAt;
}

