/// Base exception class for QueueFlow app
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final int? statusCode;

  AppException(this.message, {this.details, this.statusCode});

  @override
  String toString() => message;

  /// User-friendly error message
  String get userMessage => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException(super.message, {super.details, super.statusCode});

  @override
  String get userMessage {
    if (statusCode == 401 || message.toLowerCase().contains('invalid')) {
      return 'Invalid username or password';
    }
    if (statusCode == 403 || message.toLowerCase().contains('unauthorized')) {
      return 'Access denied. Please check your credentials.';
    }
    return 'Authentication failed. Please try again.';
  }
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.details, super.statusCode});

  @override
  String get userMessage =>
      'Unable to connect to server. Please check your internet connection.';
}

/// Server error exceptions
class ServerException extends AppException {
  ServerException(super.message, {super.details, super.statusCode});

  @override
  String get userMessage => 'Server error. Please try again later.';
}

/// Queue related exceptions
class QueueException extends AppException {
  QueueException(super.message, {super.details, super.statusCode});

  @override
  String get userMessage {
    final messageLower = message.toLowerCase();

    if (messageLower.contains('already in queue')) {
      return 'You are already in the queue';
    }
    if (messageLower.contains('not in queue')) {
      return 'You are not in the queue';
    }
    if (messageLower.contains('paused')) {
      return 'Queue is currently paused. Please try again later.';
    }
    if (messageLower.contains('no users') || messageLower.contains('empty')) {
      return 'No users in queue to call';
    }
    return 'Queue operation failed. Please try again.';
  }
}

/// Admin operation exceptions
class AdminException extends AppException {
  AdminException(super.message, {super.details, super.statusCode});

  @override
  String get userMessage => 'Admin operation failed. Please try again.';
}

/// Validation exceptions
class ValidationException extends AppException {
  ValidationException(super.message, {super.details});

  @override
  String get userMessage => message;
}

/// Timeout exceptions
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.details});

  @override
  String get userMessage => 'Operation timed out. Please try again.';
}

/// Unknown/Generic exceptions
class UnknownException extends AppException {
  UnknownException(super.message, {super.details, super.statusCode});

  @override
  String get userMessage => 'An unexpected error occurred. Please try again.';
}
