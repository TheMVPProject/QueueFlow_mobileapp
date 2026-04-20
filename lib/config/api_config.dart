class ApiConfig {
  // Change this to your backend URL
  // For local development: http://localhost:8080 or http://10.0.2.2:8080 (Android emulator)
  // For production: https://your-railway-app.railway.app
  static const String baseUrl = 'https://d97lb9sr-8081.inc1.devtunnels.ms';
  static const String wsUrl = 'wss://d97lb9sr-8081.inc1.devtunnels.ms/ws';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String joinQueueEndpoint = '/queue/join';
  static const String leaveQueueEndpoint = '/queue/leave';
  static const String confirmTurnEndpoint = '/queue/confirm';
  static const String queueStatusEndpoint = '/queue/status';
  static const String queueListEndpoint = '/queue/list';

  // Admin endpoints
  static const String adminNextEndpoint = '/admin/next';
  static const String adminRemoveUserEndpoint = '/admin/remove-user';
  static const String adminPauseEndpoint = '/admin/pause';
  static const String adminResumeEndpoint = '/admin/resume';

  // Timeout settings
  static const Duration confirmationTimeout = Duration(minutes: 3);
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const int maxReconnectAttempts = 5;
}
