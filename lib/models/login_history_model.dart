class LoginHistory {
  final int id;
  final int userId;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final String? location;
  final DateTime loginAt;

  LoginHistory({
    required this.id,
    required this.userId,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.location,
    required this.loginAt,
  });

  factory LoginHistory.fromJson(Map<String, dynamic> json) {
    return LoginHistory(
      id: json['id'],
      userId: json['user_id'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      deviceId: json['device_id'],
      location: json['location'],
      loginAt: DateTime.parse(json['login_at']),
    );
  }
}
