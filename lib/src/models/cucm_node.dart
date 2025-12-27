/// Model for a CUCM cluster node
class CucmNode {
  final String ip;
  final String? fqdn;
  final String? host;
  final String? role;
  final String? product;
  final String? dbrole;
  final String? raw;

  CucmNode({
    required this.ip,
    this.fqdn,
    this.host,
    this.role,
    this.product,
    this.dbrole,
    this.raw,
  });

  factory CucmNode.fromJson(Map<String, dynamic> json) {
    return CucmNode(
      ip: json['ip'] as String,
      fqdn: json['fqdn'] as String?,
      host: json['host'] as String?,
      role: json['role'] as String?,
      product: json['product'] as String?,
      dbrole: json['dbrole'] as String?,
      raw: json['raw'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      if (fqdn != null) 'fqdn': fqdn,
      if (host != null) 'host': host,
      if (role != null) 'role': role,
      if (product != null) 'product': product,
      if (dbrole != null) 'dbrole': dbrole,
      if (raw != null) 'raw': raw,
    };
  }

  String get displayName => host ?? fqdn ?? ip;
}

/// Request model for cluster discovery
class DiscoveryRequest {
  final String publisherHost;
  final int port;
  final String username;
  final String password;
  final int? connectTimeoutSec;
  final int? commandTimeoutSec;

  DiscoveryRequest({
    required this.publisherHost,
    this.port = 22,
    required this.username,
    required this.password,
    this.connectTimeoutSec = 30,
    this.commandTimeoutSec = 120,
  });

  Map<String, dynamic> toJson() {
    return {
      'publisher_host': publisherHost,
      'port': port,
      'username': username,
      'password': password,
      if (connectTimeoutSec != null) 'connect_timeout_sec': connectTimeoutSec,
      if (commandTimeoutSec != null) 'command_timeout_sec': commandTimeoutSec,
    };
  }
}

/// Response model for cluster discovery
class DiscoveryResponse {
  final List<CucmNode> nodes;
  final String? rawOutput;
  final bool rawOutputTruncated;

  DiscoveryResponse({
    required this.nodes,
    this.rawOutput,
    this.rawOutputTruncated = false,
  });

  factory DiscoveryResponse.fromJson(Map<String, dynamic> json) {
    final nodesList = json['nodes'] as List<dynamic>? ?? [];

    return DiscoveryResponse(
      nodes: nodesList
          .map((node) => CucmNode.fromJson(node as Map<String, dynamic>))
          .toList(),
      rawOutput: json['raw_output'] as String?,
      rawOutputTruncated: json['raw_output_truncated'] as bool? ?? false,
    );
  }

  bool get hasNodes => nodes.isNotEmpty;
  bool get isEmpty => nodes.isEmpty;
}
