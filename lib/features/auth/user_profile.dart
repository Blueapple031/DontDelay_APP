class UserProfile {
  const UserProfile({
    required this.username,
    required this.realName,
    required this.email,
    required this.department,
  });

  final String username;
  final String realName;
  final String email;
  final String department;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String? ?? '',
      realName: json['realName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      department: json['department'] as String? ?? '',
    );
  }
}
