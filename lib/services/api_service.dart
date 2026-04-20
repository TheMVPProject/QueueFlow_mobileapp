import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:queueflow_mobileapp/config/api_config.dart';
import 'package:queueflow_mobileapp/models/user.dart';
import 'package:queueflow_mobileapp/models/queue_entry.dart';
import 'package:queueflow_mobileapp/utils/exceptions.dart';
import 'package:queueflow_mobileapp/utils/logger.dart';

class ApiService {
  /// Handle HTTP exceptions and convert to custom exceptions
  AppException _handleError(Object error, int? statusCode, String operation) {
    if (error is SocketException) {
      AppLogger.error('Network error during $operation', error);
      return NetworkException(
        'Network connection failed',
        details: error.message,
      );
    }

    if (error is TimeoutException) {
      AppLogger.error('Timeout during $operation', error);
      return TimeoutException(
        'Operation timed out',
        details: error.toString(),
      );
    }

    if (statusCode != null) {
      if (statusCode >= 500) {
        return ServerException(
          'Server error',
          statusCode: statusCode,
        );
      }

      if (statusCode == 401 || statusCode == 403) {
        return AuthException(
          error.toString(),
          statusCode: statusCode,
        );
      }

      if (statusCode >= 400) {
        return UnknownException(
          error.toString(),
          statusCode: statusCode,
        );
      }
    }

    AppLogger.error('Unknown error during $operation', error);
    return UnknownException(error.toString());
  }

  Future<User> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.success('Login successful', 'API');
        return User.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Login failed';
        throw AuthException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'login');
    }
  }

  Future<User> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.success('Registration successful', 'API');
        return User.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Registration failed';
        throw AuthException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'register');
    }
  }

  Future<void> updateFCMToken(String token, String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to update FCM token';
        throw UnknownException(errorMsg, statusCode: response.statusCode);
      }
      AppLogger.success('FCM token updated', 'API');
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'update FCM token');
    }
  }

  Future<Map<String, dynamic>> joinQueue(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.joinQueueEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.success('Joined queue successfully', 'API');
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to join queue';
        throw QueueException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'join queue');
    }
  }

  Future<void> leaveQueue(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.leaveQueueEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to leave queue';
        throw QueueException(errorMsg, statusCode: response.statusCode);
      }
      AppLogger.success('Left queue successfully', 'API');
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'leave queue');
    }
  }

  Future<void> confirmTurn(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.confirmTurnEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to confirm turn';
        throw QueueException(errorMsg, statusCode: response.statusCode);
      }
      AppLogger.success('Confirmed turn successfully', 'API');
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'confirm turn');
    }
  }

  Future<QueueStatus?> getQueueStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.queueStatusEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['in_queue'] == true) {
          return QueueStatus.fromJson(data['status']);
        }
        return null;
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to get queue status';
        throw QueueException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'get queue status');
    }
  }

  Future<List<QueueEntry>> getQueueList(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.queueListEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final queue = data['queue'] as List<dynamic>?;

        // Handle null or empty queue
        if (queue == null || queue.isEmpty) {
          return [];
        }

        return queue
            .map((e) => QueueEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to get queue list';
        throw QueueException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'get queue list');
    }
  }

  // Admin endpoints
  Future<void> callNext(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminNextEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to call next user';
        throw AdminException(errorMsg, statusCode: response.statusCode);
      }
      AppLogger.success('Called next user successfully', 'API');
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'call next user');
    }
  }

  Future<void> removeUser(String token, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminRemoveUserEndpoint}/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to remove user';
        throw AdminException(errorMsg, statusCode: response.statusCode);
      }
      AppLogger.success('Removed user successfully', 'API');
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'remove user');
    }
  }

  Future<void> pauseQueue(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminPauseEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to pause queue';
        throw AdminException(errorMsg, statusCode: response.statusCode);
      }
      AppLogger.success('Paused queue successfully', 'API');
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'pause queue');
    }
  }

  Future<void> resumeQueue(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminResumeEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        final errorMsg = error['error'] ?? 'Failed to resume queue';
        throw AdminException(errorMsg, statusCode: response.statusCode);
      }
      AppLogger.success('Resumed queue successfully', 'API');
    } catch (e) {
      if (e is AppException) rethrow;
      throw _handleError(e, null, 'resume queue');
    }
  }
}
