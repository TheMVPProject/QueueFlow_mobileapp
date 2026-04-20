class QueueEntry {
  final int id;
  final int userId;
  final String? username;
  final int position;
  final String status;
  final DateTime joinedAt;
  final DateTime? calledAt;
  final DateTime? confirmedAt;
  final DateTime? timeoutAt;

  QueueEntry({
    required this.id,
    required this.userId,
    this.username,
    required this.position,
    required this.status,
    required this.joinedAt,
    this.calledAt,
    this.confirmedAt,
    this.timeoutAt,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      position: json['position'],
      status: json['status'],
      joinedAt: DateTime.parse(json['joined_at']),
      calledAt:
          json['called_at'] != null ? DateTime.parse(json['called_at']) : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      timeoutAt: json['timeout_at'] != null
          ? DateTime.parse(json['timeout_at'])
          : null,
    );
  }
}

class QueueStatus {
  final int position;
  final String status;
  final int totalInQueue;
  final DateTime? calledAt;
  final DateTime? timeoutAt;

  QueueStatus({
    required this.position,
    required this.status,
    required this.totalInQueue,
    this.calledAt,
    this.timeoutAt,
  });

  factory QueueStatus.fromJson(Map<String, dynamic> json) {
    return QueueStatus(
      position: json['position'],
      status: json['status'],
      totalInQueue: json['total_in_queue'],
      calledAt:
          json['called_at'] != null ? DateTime.parse(json['called_at']) : null,
      timeoutAt: json['timeout_at'] != null
          ? DateTime.parse(json['timeout_at'])
          : null,
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isCalled => status == 'called';
  bool get isConfirmed => status == 'confirmed';
}
