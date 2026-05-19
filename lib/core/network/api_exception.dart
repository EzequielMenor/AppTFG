sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => '$runtimeType(statusCode: $statusCode, message: $message)';
}

/// Generic API error for uncategorized status codes.
class GenericApiException extends ApiException {
  const GenericApiException(super.message, {super.statusCode});
}

class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Resource not found'])
      : super(message, statusCode: 404);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([String message = 'Forbidden'])
      : super(message, statusCode: 403);
}

class ServerErrorException extends ApiException {
  const ServerErrorException([int statusCode = 500, String message = 'Server error'])
      : super(message, statusCode: statusCode);
}

class NetworkException extends ApiException {
  const NetworkException([String message = 'Network error']) : super(message);
}

class ApiTimeoutException extends ApiException {
  const ApiTimeoutException([String message = 'Request timeout']) : super(message);
}
