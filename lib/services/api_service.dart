import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:queueflow_mobileapp/config/api_config.dart';
import 'package:queueflow_mobileapp/models/user.dart';
import 'package:queueflow_mobileapp/models/queue_entry.dart';

class ApiService {
  Future<User> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> joinQueue(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.joinQueueEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to join queue');
    }
  }

  Future<void> leaveQueue(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.leaveQueueEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to leave queue');
    }
  }

  Future<void> confirmTurn(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.confirmTurnEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to confirm turn');
    }
  }

  Future<QueueStatus?> getQueueStatus(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.queueStatusEndpoint}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['in_queue'] == true) {
        return QueueStatus.fromJson(data['status']);
      }
      return null;
    } else {
      throw Exception('Failed to get queue status');
    }
  }

  Future<List<QueueEntry>> getQueueList(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.queueListEndpoint}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final queue = data['queue'] as List<dynamic>;
      return queue.map((e) => QueueEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to get queue list');
    }
  }

  // Admin endpoints
  Future<void> callNext(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminNextEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to call next user');
    }
  }

  Future<void> removeUser(String token, int userId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminRemoveUserEndpoint}/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to remove user');
    }
  }

  Future<void> pauseQueue(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminPauseEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to pause queue');
    }
  }

  Future<void> resumeQueue(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminResumeEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to resume queue');
    }
  }
}
