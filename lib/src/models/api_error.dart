/// Model for normalized API errors
class ApiError {
  final String error;
  final String message;
  final String? requestId;
  final int? statusCode;

  ApiError({
    required this.error,
    required this.message,
    this.requestId,
    this.statusCode,
  });

  factory ApiError.fromResponse(
    dynamic responseData,
    int? statusCode,
    String? requestIdHeader,
  ) {
    if (responseData is Map<String, dynamic>) {
      return ApiError(
        error: responseData['error'] as String? ?? 'Unknown Error',
        message: responseData['message'] as String? ?? 'An error occurred',
        requestId: responseData['request_id'] as String? ?? requestIdHeader,
        statusCode: statusCode,
      );
    }

    return ApiError(
      error: 'Unknown Error',
      message: responseData?.toString() ?? 'An error occurred',
      requestId: requestIdHeader,
      statusCode: statusCode,
    );
  }

  factory ApiError.fromException(dynamic error, int? statusCode) {
    return ApiError(
      error: 'Request Failed',
      message: error.toString(),
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('Error: $error\n');
    buffer.write('Message: $message');

    if (requestId != null) {
      buffer.write('\nRequest ID: $requestId');
    }

    if (statusCode != null) {
      buffer.write('\nStatus Code: $statusCode');
    }

    return buffer.toString();
  }
}
