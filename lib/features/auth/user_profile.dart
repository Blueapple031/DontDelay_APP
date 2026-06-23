class UserProfile {
  const UserProfile({
    required this.username,
    required this.realName,
    required this.email,
    required this.department,
    required this.major,
  });

  final String username;
  final String realName;
  final String email;
  final String department;
  final String major;

  static UserProfile? tryParse(dynamic raw) {
    final map = _unwrapUserMap(raw);
    if (map == null) return null;

    return UserProfile(
      username: _string(map, const ['username']),
      realName: _string(map, const ['realName', 'real_name']),
      email: _string(map, const ['email']),
      department: _string(map, const ['department', 'dept']),
      major: _string(map, const ['major']),
    );
  }

  static Map<String, dynamic>? _unwrapUserMap(dynamic raw) {
    if (raw is! Map) return null;

    var map = _toStringKeyMap(raw);
    for (final key in ['data', 'user', 'profile', 'result']) {
      final nested = map[key];
      if (nested is Map) {
        map = _toStringKeyMap(nested);
        break;
      }
    }
    return map;
  }

  static Map<String, dynamic> _toStringKeyMap(Map raw) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
