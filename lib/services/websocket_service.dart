import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:queueflow_mobileapp/config/api_config.dart';
import 'package:queueflow_mobileapp/models/ws_message.dart';
import 'package:queueflow_mobileapp/utils/logger.dart';

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
  Timer? _pingTimer;
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

      // Start ping timer to keep connection alive
      _startPingTimer();

      AppLogger.success('WebSocket connected', 'WebSocket');
    } catch (e) {
      AppLogger.error('WebSocket connection error', e, null, 'WebSocket');
      _handleError(e);
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentStatus == ConnectionStatus.connected) {
        sendMessage(WSMessage(type: 'ping', payload: {}));
      }
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final wsMessage = WSMessage.fromJson(data);
      _messageController.add(wsMessage);

      AppLogger.debug('WebSocket message received: ${wsMessage.type}', 'WebSocket');
    } catch (e) {
      AppLogger.error('Error parsing WebSocket message', e, null, 'WebSocket');
    }
  }

  void _handleError(dynamic error) {
    AppLogger.error('WebSocket error', error, null, 'WebSocket');

    if (!_intentionalDisconnect) {
      _attemptReconnect();
    }
  }

  void _handleClose() {
    AppLogger.info('WebSocket closed', 'WebSocket');

    _pingTimer?.cancel();
    _updateStatus(ConnectionStatus.disconnected);

    if (!_intentionalDisconnect) {
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= ApiConfig.maxReconnectAttempts) {
      _updateStatus(ConnectionStatus.failed);
      AppLogger.warning('Max reconnect attempts reached', 'WebSocket');
      return;
    }

    _reconnectAttempts++;
    _updateStatus(ConnectionStatus.reconnecting);

    AppLogger.info('Reconnecting... Attempt $_reconnectAttempts', 'WebSocket');

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
      AppLogger.warning('Cannot send message: WebSocket not connected', 'WebSocket');
    }
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _updateStatus(ConnectionStatus.disconnected);

    AppLogger.info('WebSocket disconnected intentionally', 'WebSocket');
  }

  void _updateStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _statusController.close();
  }
}
