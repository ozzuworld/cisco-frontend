import 'package:dio/dio.dart';
import '../config/config_service.dart';
import '../models/api_error.dart';
import '../models/cucm_node.dart';

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

    return DiscoveryResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
