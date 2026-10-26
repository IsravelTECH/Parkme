class UserSession {
  final String token;
  final String name;
  final String role; // 'seeker' or 'owner'

  UserSession({
    required this.token,
    required this.name,
    required this.role,
  });

  bool get isOwner => role.toLowerCase() == 'owner';

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token'] ?? '',
      name: json['name'] ?? 'Driver',
      role: json['role'] ?? 'seeker',
    );
  }
}
