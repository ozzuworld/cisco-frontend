/// Application configuration model
class AppConfig {
  static const String defaultBaseUrl = 'http://192.168.1.201:8000';

  final String baseUrl;
  final String? apiKey;
  final bool rememberApiKey;

  AppConfig({
    required this.baseUrl,
    this.apiKey,
    this.rememberApiKey = false,
  });

  AppConfig copyWith({
    String? baseUrl,
    String? apiKey,
    bool? rememberApiKey,
  }) {
    return AppConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      rememberApiKey: rememberApiKey ?? this.rememberApiKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'rememberApiKey': rememberApiKey,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      baseUrl: json['baseUrl'] as String? ?? defaultBaseUrl,
      apiKey: json['apiKey'] as String?,
      rememberApiKey: json['rememberApiKey'] as bool? ?? false,
    );
  }

  factory AppConfig.defaults() {
    return AppConfig(
      baseUrl: defaultBaseUrl,
      rememberApiKey: false,
    );
  }

  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;
}
