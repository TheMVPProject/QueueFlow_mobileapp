class User {
  final int userId;
  final String username;
  final String role;
  final String token;

  User({
    required this.userId,
    required this.username,
    required this.role,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['username'],
      role: json['role'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'role': role,
      'token': token,
    };
  }

  bool get isAdmin => role == 'admin';
}
