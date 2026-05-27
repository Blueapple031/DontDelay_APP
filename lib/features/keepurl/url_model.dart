import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum UrlAddResult { saved, duplicate, invalid }

class UrlItem {
  final String id;
  final String url;
  final String title;
  final String? _folderId;
  final String? _memo;
  final bool watchLater;
  final String? _source;
  final DateTime savedAt;
  final String? _iconType;

  /// Hot reload로 구 인스턴스가 남아도 null 접근 시 크래시 방지
  String get folderId => _folderId ?? '';
  String get memo => _memo ?? '';
  String get source => _source ?? 'manual';
  String get iconType => _iconType ?? inferIconType(url);

  UrlItem({
    String? id,
    required String url,
    required this.title,
    required String folderId,
    String memo = '',
    this.watchLater = false,
    String source = 'manual',
    DateTime? savedAt,
    String? iconType,
  })  : id = id ?? _uuid.v4(),
        savedAt = savedAt ?? DateTime.now(),
        url = normalizeUrl(url),
        _folderId = folderId,
        _memo = memo,
        _source = source,
        _iconType = iconType;

  static String normalizeUrl(String raw) {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return trimmed;
    if (!uri.hasAuthority) return trimmed;

    var path = uri.path;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    return uri.replace(path: path.isEmpty ? '/' : path).toString();
  }

  /// http(s)뿐 아니라 chrome://, edge://, about:, file: 등도 보관 가능
  static bool isValidSavableUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return false;
    const blocked = {'javascript', 'data', 'blob', 'vbscript'};
    if (blocked.contains(uri.scheme.toLowerCase())) return false;
    return true;
  }

  static String _host(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static bool _hostMatches(String host, String pattern) {
    return host == pattern || host.endsWith('.$pattern');
  }

  /// 도메인 기반 폴더 이름 추론
  static String inferFolderNameFromUrl(String url) {
    final host = _host(url);
    final lower = url.toLowerCase();

    if (_hostMatches(host, 'youtube.com') ||
        _hostMatches(host, 'youtu.be') ||
        _hostMatches(host, 'vimeo.com')) {
      return 'YouTube';
    }
    if (_hostMatches(host, 'instagram.com')) return 'Instagram';
    if (_hostMatches(host, 'github.com') ||
        _hostMatches(host, 'gitlab.com') ||
        _hostMatches(host, 'stackoverflow.com') ||
        _hostMatches(host, 'velog.io') ||
        _hostMatches(host, 'tistory.com') ||
        _hostMatches(host, 'nomadcoders.co')) {
      return '개발';
    }
    if (_hostMatches(host, 'notion.so') ||
        _hostMatches(host, 'notion.site')) {
      return '학습법';
    }
    if (_hostMatches(host, 'arxiv.org') ||
        _hostMatches(host, 'semanticscholar.org') ||
        _hostMatches(host, 'scholar.google.com')) {
      return '전공';
    }
    if (_hostMatches(host, 'inflearn.com') ||
        _hostMatches(host, 'coursera.org') ||
        _hostMatches(host, 'udemy.com') ||
        _hostMatches(host, 'fastcampus.co.kr')) {
      return '학습법';
    }
    if (_hostMatches(host, 'twitter.com') ||
        _hostMatches(host, 'x.com') ||
        _hostMatches(host, 'tiktok.com')) {
      return '자기계발';
    }
    if (_hostMatches(host, 'naver.com') && lower.contains('blog')) {
      return '학습법';
    }
    if (RegExp(r'\.(pdf|doc|docx|ppt|pptx|xls|xlsx)(\?|$)', caseSensitive: false)
        .hasMatch(lower)) {
      return '전공';
    }
    return '미분류';
  }

  static String inferIconType(String url) {
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase() ?? '';
    if (scheme == 'chrome' || scheme == 'edge' || scheme == 'about') {
      return 'internal';
    }

    final host = _host(url);
    final lower = url.toLowerCase();
    if (_hostMatches(host, 'youtube.com') ||
        _hostMatches(host, 'youtu.be') ||
        _hostMatches(host, 'vimeo.com')) {
      return 'youtube';
    }
    if (_hostMatches(host, 'instagram.com') ||
        _hostMatches(host, 'twitter.com') ||
        _hostMatches(host, 'x.com') ||
        _hostMatches(host, 'tiktok.com')) {
      return 'social';
    }
    if (RegExp(r'\.(pdf|doc|docx|ppt|pptx|xls|xlsx)(\?|$)', caseSensitive: false)
        .hasMatch(lower)) {
      return 'document';
    }
    return 'web';
  }

  IconData get icon {
    switch (iconType) {
      case 'youtube':
        return Icons.play_circle_outline;
      case 'document':
        return Icons.description_outlined;
      case 'social':
        return Icons.photo_camera_outlined;
      case 'internal':
        return Icons.extension_outlined;
      default:
        return Icons.language;
    }
  }

  String get savedDateLabel {
    final d = savedAt;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  UrlItem copyWith({
    String? url,
    String? title,
    String? folderId,
    String? memo,
    bool? watchLater,
    String? source,
  }) {
    final nextUrl = url ?? this.url;
    return UrlItem(
      id: id,
      url: nextUrl,
      title: title ?? this.title,
      folderId: folderId ?? this.folderId,
      memo: memo ?? this.memo,
      watchLater: watchLater ?? this.watchLater,
      source: source ?? this.source,
      savedAt: savedAt,
      iconType: url != null ? inferIconType(nextUrl) : iconType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'folderId': folderId,
      'memo': memo,
      'watchLater': watchLater,
      'source': source,
      'savedAt': savedAt.toIso8601String(),
      'iconType': iconType,
    };
  }

  factory UrlItem.fromJson(Map<String, dynamic> json) {
    final rawSaved = json['savedAt'];
    final url = json['url'] as String;
    return UrlItem(
      id: json['id'] as String,
      url: url,
      title: json['title'] as String,
      folderId: json['folderId'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      watchLater: json['watchLater'] as bool? ?? false,
      source: json['source'] as String? ?? 'manual',
      savedAt: rawSaved is String ? DateTime.parse(rawSaved) : DateTime.now(),
      iconType: json['iconType'] as String?,
    );
  }
}
