class WSMessage {
  final String type;
  final dynamic payload;

  WSMessage({
    required this.type,
    required this.payload,
  });

  factory WSMessage.fromJson(Map<String, dynamic> json) {
    return WSMessage(
      type: json['type'],
      payload: json['payload'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': payload,
    };
  }
}

class PositionUpdate {
  final int position;
  final int totalInQueue;
  final String status;

  PositionUpdate({
    required this.position,
    required this.totalInQueue,
    required this.status,
  });

  factory PositionUpdate.fromJson(Map<String, dynamic> json) {
    return PositionUpdate(
      position: json['position'],
      totalInQueue: json['total_in_queue'],
      status: json['status'],
    );
  }
}

class YourTurnPayload {
  final int position;
  final DateTime timeoutAt;
  final int timeoutInSeconds;

  YourTurnPayload({
    required this.position,
    required this.timeoutAt,
    required this.timeoutInSeconds,
  });

  factory YourTurnPayload.fromJson(Map<String, dynamic> json) {
    return YourTurnPayload(
      position: json['position'],
      timeoutAt: DateTime.parse(json['timeout_at']),
      timeoutInSeconds: json['timeout_in_seconds'],
    );
  }
}

class TimeoutPayload {
  final String message;
  final String reason;

  TimeoutPayload({
    required this.message,
    required this.reason,
  });

  factory TimeoutPayload.fromJson(Map<String, dynamic> json) {
    return TimeoutPayload(
      message: json['message'],
      reason: json['reason'],
    );
  }
}

class QueueStatePayload {
  final List<dynamic> queue;
  final bool isPaused;
  final DateTime timestamp;

  QueueStatePayload({
    required this.queue,
    required this.isPaused,
    required this.timestamp,
  });

  factory QueueStatePayload.fromJson(Map<String, dynamic> json) {
    return QueueStatePayload(
      queue: (json['queue'] as List<dynamic>?) ?? [],
      isPaused: json['is_paused'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
