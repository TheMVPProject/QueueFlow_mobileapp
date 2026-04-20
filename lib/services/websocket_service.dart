import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:queueflow_mobileapp/config/api_config.dart';
import 'package:queueflow_mobileapp/models/ws_message.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<WSMessage>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  String? _token;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _intentionalDisconnect = false;

  Stream<WSMessage> get messages => _messageController.stream;
  Stream<ConnectionStatus> get status => _statusController.stream;

  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  ConnectionStatus get currentStatus => _currentStatus;

  void connect(String token) {
    _token = token;
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    _connect();
  }

  void _connect() {
    if (_token == null) return;

    _updateStatus(ConnectionStatus.connecting);

    try {
      // Connect to WebSocket with authentication header
      final wsUri = Uri.parse(ApiConfig.wsUrl);
      _channel = IOWebSocketChannel.connect(
        wsUri,
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleClose,
      );

      _updateStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;

      if (kDebugMode) {
        print('WebSocket connected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket connection error: $e');
      }
      _handleError(e);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final wsMessage = WSMessage.fromJson(data);
      _messageController.add(wsMessage);

      if (kDebugMode) {
        print('WebSocket message received: ${wsMessage.type}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing WebSocket message: $e');
      }
    }
  }

  void _handleError(dynamic error) {
    if (kDebugMode) {
      print('WebSocket error: $error');
    }

    if (!_intentionalDisconnect) {
      _attemptReconnect();
    }
  }

  void _handleClose() {
    if (kDebugMode) {
      print('WebSocket closed');
    }

    _updateStatus(ConnectionStatus.disconnected);

    if (!_intentionalDisconnect) {
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= ApiConfig.maxReconnectAttempts) {
      _updateStatus(ConnectionStatus.failed);
      if (kDebugMode) {
        print('Max reconnect attempts reached');
      }
      return;
    }

    _reconnectAttempts++;
    _updateStatus(ConnectionStatus.reconnecting);

    if (kDebugMode) {
      print('Reconnecting... Attempt $_reconnectAttempts');
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      ApiConfig.reconnectDelay * _reconnectAttempts,
      _connect,
    );
  }

  void sendMessage(WSMessage message) {
    if (_channel != null && _currentStatus == ConnectionStatus.connected) {
      _channel!.sink.add(jsonEncode(message.toJson()));
    } else {
      if (kDebugMode) {
        print('Cannot send message: WebSocket not connected');
      }
    }
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _updateStatus(ConnectionStatus.disconnected);

    if (kDebugMode) {
      print('WebSocket disconnected intentionally');
    }
  }

  void _updateStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _statusController.close();
  }
}
