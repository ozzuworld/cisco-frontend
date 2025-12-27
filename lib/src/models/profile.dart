/// Model for a collection profile
class Profile {
  final String name;
  final String description;
  final int reltimeMinutes;
  final bool compress;
  final bool recurs;
  final String match;

  Profile({
    required this.name,
    required this.description,
    required this.reltimeMinutes,
    required this.compress,
    required this.recurs,
    required this.match,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String,
      description: json['description'] as String,
      reltimeMinutes: json['reltime_minutes'] as int,
      compress: json['compress'] as bool? ?? false,
      recurs: json['recurs'] as bool? ?? false,
      match: json['match'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'reltime_minutes': reltimeMinutes,
      'compress': compress,
      'recurs': recurs,
      'match': match,
    };
  }
}

/// Request model for creating a collection job
class CreateJobRequest {
  final List<String> nodeIps;
  final String profileName;
  final int? reltimeMinutes;
  final bool? compress;
  final bool? recurs;
  final String? match;

  CreateJobRequest({
    required this.nodeIps,
    required this.profileName,
    this.reltimeMinutes,
    this.compress,
    this.recurs,
    this.match,
  });

  Map<String, dynamic> toJson() {
    return {
      'node_ips': nodeIps,
      'profile_name': profileName,
      if (reltimeMinutes != null) 'reltime_minutes': reltimeMinutes,
      if (compress != null) 'compress': compress,
      if (recurs != null) 'recurs': recurs,
      if (match != null) 'match': match,
    };
  }
}

/// Response model for job creation
class CreateJobResponse {
  final String jobId;

  CreateJobResponse({
    required this.jobId,
  });

  factory CreateJobResponse.fromJson(Map<String, dynamic> json) {
    return CreateJobResponse(
      jobId: json['job_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
    };
  }
}
