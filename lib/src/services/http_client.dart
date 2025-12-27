import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/config_service.dart';
import '../models/api_error.dart';
import '../models/cucm_node.dart';
import '../models/profile.dart';

/// HTTP client service with global interceptor for auth and error handling
class HttpClientService {
  final ConfigService _configService;
  late final Dio _dio;

  HttpClientService(this._configService) {
    _dio = Dio();
    _setupInterceptors();
  }

  Dio get client => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Update base URL from config
          options.baseUrl = _configService.config.baseUrl;

          // Attach Authorization header if API key exists
          if (_configService.config.hasApiKey) {
            options.headers['Authorization'] =
                'Bearer ${_configService.config.apiKey}';
          }

          // Add standard headers
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';

          // Log request details (for debugging)
          _logRequest(options);

          return handler.next(options);
        },
        onError: (error, handler) {
          final normalizedError = _normalizeError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: normalizedError,
              response: error.response,
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  ApiError _normalizeError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final requestId = response?.headers.value('X-Request-ID');

    // If we have a response body, try to parse it
    if (response?.data != null) {
      return ApiError.fromResponse(
        response!.data,
        statusCode,
        requestId,
      );
    }

    // Fallback for network or other errors
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your network.';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection failed. Please check your network.';
        break;
      case DioExceptionType.badResponse:
        message = 'Server error. Please try again later.';
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      default:
        message = error.message ?? 'An unknown error occurred.';
    }

    return ApiError(
      error: 'Request Failed',
      message: message,
      requestId: requestId,
      statusCode: statusCode,
    );
  }

  /// Test connection to the API
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await _dio.get('/health');

      return {
        'success': true,
        'status': response.statusCode,
        'message': 'Connection successful',
        'data': response.data,
      };
    } on DioException catch (e) {
      final apiError = e.error as ApiError;

      return {
        'success': false,
        'status': apiError.statusCode,
        'error': apiError.error,
        'message': apiError.message,
        'requestId': apiError.requestId,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unknown Error',
        'message': e.toString(),
      };
    }
  }

  /// Update base URL (used when config changes)
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Discover CUCM cluster nodes
  /// Throws DioException on error with normalized ApiError
  Future<DiscoveryResponse> discoverNodes(DiscoveryRequest request) async {
    final response = await _dio.post(
      '/discover-nodes',
      data: request.toJson(),
    );

    // Log response details (but not the password from request)
    _logDiscoveryResponse(response);

    return DiscoveryResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get available collection profiles
  /// Throws DioException on error with normalized ApiError
  Future<List<Profile>> getProfiles() async {
    final response = await _dio.get('/profiles');

    // Log response
    _logResponse('GET /profiles', response);

    final profilesList = response.data as List<dynamic>? ?? [];
    return profilesList
        .map((profile) => Profile.fromJson(profile as Map<String, dynamic>))
        .toList();
  }

  /// Create a new collection job
  /// Throws DioException on error with normalized ApiError
  Future<CreateJobResponse> createJob(CreateJobRequest request) async {
    final response = await _dio.post(
      '/jobs',
      data: request.toJson(),
    );

    // Log response
    _logResponse('POST /jobs', response);

    return CreateJobResponse.fromJson(response.data as Map<String, dynamic>);
  }

  void _logRequest(RequestOptions options) {
    final url = '${options.baseUrl}${options.path}';
    final hasAuth = options.headers.containsKey('Authorization');
    final authHeader = hasAuth
        ? 'Bearer ***${options.headers['Authorization'].toString().substring(options.headers['Authorization'].toString().length - 8)}'
        : 'NONE';

    // Log request body with password length instead of actual password
    String requestBodyLog = '';
    if (options.data != null && options.data is Map) {
      final dataMap = Map<String, dynamic>.from(options.data as Map);
      if (dataMap.containsKey('password')) {
        final passwordLength = (dataMap['password'] as String?)?.length ?? 0;
        dataMap['password'] = '***<$passwordLength chars>***';
      }
      try {
        requestBodyLog = jsonEncode(dataMap);
      } catch (e) {
        requestBodyLog = 'Error encoding request: $e';
      }
    }

    // ignore: avoid_print
    print('=== Discovery Request ===');
    // ignore: avoid_print
    print('URL: $url');
    // ignore: avoid_print
    print('Method: ${options.method}');
    // ignore: avoid_print
    print('Authorization: $authHeader');
    // ignore: avoid_print
    print('Has API Key in Config: ${_configService.config.hasApiKey}');
    if (requestBodyLog.isNotEmpty) {
      // ignore: avoid_print
      print('Request Body (password redacted):');
      // ignore: avoid_print
      print(requestBodyLog);
    }
    // ignore: avoid_print
    print('========================');
  }

  void _logDiscoveryResponse(Response response) {
    final statusCode = response.statusCode;
    final requestId = response.headers.value('X-Request-ID') ?? 'none';

    // Parse response.data as Map (Dio already parses JSON)
    // Use jsonEncode to get proper JSON string representation
    String bodyString;
    try {
      if (response.data is Map || response.data is List) {
        bodyString = jsonEncode(response.data);
      } else {
        bodyString = response.data.toString();
      }
    } catch (e) {
      bodyString = 'Error encoding response: $e';
    }

    final bodyPreview = bodyString.length > 1024
        ? '${bodyString.substring(0, 1024)}... (truncated)'
        : bodyString;

    // ignore: avoid_print
    print('=== Discovery Response ===');
    // ignore: avoid_print
    print('Status Code: $statusCode');
    // ignore: avoid_print
    print('X-Request-ID: $requestId');
    // ignore: avoid_print
    print('Response Body (first 1KB - REAL JSON):');
    // ignore: avoid_print
    print(bodyPreview);
    // ignore: avoid_print
    print('========================');
  }

  void _logResponse(String endpoint, Response response) {
    final statusCode = response.statusCode;
    final requestId = response.headers.value('X-Request-ID') ?? 'none';

    // Use jsonEncode to get proper JSON string representation
    String bodyString;
    try {
      if (response.data is Map || response.data is List) {
        bodyString = jsonEncode(response.data);
      } else {
        bodyString = response.data.toString();
      }
    } catch (e) {
      bodyString = 'Error encoding response: $e';
    }

    final bodyPreview = bodyString.length > 1024
        ? '${bodyString.substring(0, 1024)}... (truncated)'
        : bodyString;

    // ignore: avoid_print
    print('=== $endpoint Response ===');
    // ignore: avoid_print
    print('Status Code: $statusCode');
    // ignore: avoid_print
    print('X-Request-ID: $requestId');
    // ignore: avoid_print
    print('Response Body (first 1KB):');
    // ignore: avoid_print
    print(bodyPreview);
    // ignore: avoid_print
    print('========================');
  }
}
