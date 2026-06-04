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

  String get displayName {
    if (realName.trim().isNotEmpty) return realName.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return '사용자';
  }

  /// API 응답(camelCase / snake_case / 래핑 객체)을 프로필로 변환. 실패 시 null.
  static UserProfile? tryParse(dynamic raw) {
    final map = _unwrapUserMap(raw);
    if (map == null) return null;

    return UserProfile(
      username: _string(map, const ['username', 'userName', 'user_name']),
      realName: _string(map, const [
        'realName',
        'real_name',
        'name',
        'fullName',
        'full_name',
        'nickname',
        'nick_name',
      ]),
      email: _string(map, const ['email']),
      department: _string(map, const [
        'department',
        'major',
        'dept',
      ]),
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
