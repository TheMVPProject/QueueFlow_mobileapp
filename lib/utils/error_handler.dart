/// Centralized error message handler for user-friendly error messages
String getErrorMessage(String error, {String? context}) {
  final errorLower = error.toLowerCase();

  // Authentication errors
  if (errorLower.contains('invalid') ||
      errorLower.contains('incorrect') ||
      errorLower.contains('not found') ||
      errorLower.contains('wrong') ||
      errorLower.contains('401')) {
    return 'Invalid username or password';
  }

  if (errorLower.contains('unauthorized') || errorLower.contains('403')) {
    return 'Access denied. Please check your credentials.';
  }

  // Queue-specific errors
  if (errorLower.contains('already in queue')) {
    return 'You are already in the queue';
  }

  if (errorLower.contains('queue') && errorLower.contains('paused')) {
    return 'Queue is currently paused. Please try again later.';
  }

  if (errorLower.contains('no users') || errorLower.contains('empty')) {
    return 'No users in queue to call';
  }

  // Network errors
  if (errorLower.contains('network') ||
      errorLower.contains('connection') ||
      errorLower.contains('timeout') ||
      errorLower.contains('failed to connect') ||
      errorLower.contains('socketexception') ||
      errorLower.contains('failed host lookup')) {
    return 'Unable to connect to server. Please check your internet connection.';
  }

  // Server errors
  if (errorLower.contains('server') ||
      errorLower.contains('500') ||
      errorLower.contains('502') ||
      errorLower.contains('503')) {
    return 'Server error. Please try again later.';
  }

  // Generic fallback with context
  if (context == 'login') {
    return 'Login failed. Please try again.';
  } else if (context == 'queue') {
    return 'Failed to join queue. Please try again.';
  } else {
    return 'Operation failed. Please try again.';
  }
}
