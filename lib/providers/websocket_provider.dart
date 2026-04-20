import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/services/websocket_service.dart';

// Export ConnectionStatus for use in other files
export 'package:queueflow_mobileapp/services/websocket_service.dart'
    show ConnectionStatus;

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final websocketStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.status;
});
