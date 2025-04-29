class User {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? role;
  final bool emailVerified;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.role,
    required this.emailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      emailVerified: json['emailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
      'emailVerified': emailVerified,
    };
  }
}
