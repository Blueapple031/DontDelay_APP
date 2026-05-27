import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

const kUrlFilterCategories = ['전체', '개발', '전공', '학습법', '자기계발'];
const kUrlSaveCategories = ['미분류', '개발', '전공', '학습법', '자기계발'];

enum UrlAddResult { saved, duplicate, invalid }

class UrlClassification {
  final String category;
  final List<String> tags;
  final String iconType;

  const UrlClassification({
    required this.category,
    required this.tags,
    required this.iconType,
  });
}

class UrlItem {
  final String id;
  final String url;
  final String title;
  final String category;
  final List<String> tags;
  final bool watchLater;
  final String source;
  final DateTime savedAt;
  final String iconType;

  UrlItem({
    String? id,
    required String url,
    required this.title,
    String category = '미분류',
    List<String>? tags,
    this.watchLater = false,
    this.source = 'manual',
    DateTime? savedAt,
    String? iconType,
  })  : id = id ?? _uuid.v4(),
        savedAt = savedAt ?? DateTime.now(),
        url = normalizeUrl(url),
        category = _resolveMetadata(
          url,
          category: category,
          tags: tags,
          iconType: iconType,
        ).category,
        tags = _resolveMetadata(
          url,
          category: category,
          tags: tags,
          iconType: iconType,
        ).tags,
        iconType = _resolveMetadata(
          url,
          category: category,
          tags: tags,
          iconType: iconType,
        ).iconType;

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

  static bool isValidHttpUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  static String _host(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static bool _hostMatches(String host, String pattern) {
    return host == pattern || host.endsWith('.$pattern');
  }

  static UrlClassification classifyFromUrl(String url) {
    final host = _host(url);
    final lower = url.toLowerCase();

    if (_hostMatches(host, 'youtube.com') ||
        _hostMatches(host, 'youtu.be') ||
        _hostMatches(host, 'vimeo.com')) {
      return const UrlClassification(
        category: '학습법',
        tags: ['YouTube'],
        iconType: 'youtube',
      );
    }

    if (_hostMatches(host, 'instagram.com')) {
      return const UrlClassification(
        category: '자기계발',
        tags: ['Instagram'],
        iconType: 'social',
      );
    }

    if (_hostMatches(host, 'github.com') ||
        _hostMatches(host, 'gitlab.com') ||
        _hostMatches(host, 'stackoverflow.com') ||
        _hostMatches(host, 'velog.io') ||
        _hostMatches(host, 'tistory.com') ||
        _hostMatches(host, 'nomadcoders.co')) {
      return UrlClassification(
        category: '개발',
        tags: [_platformTag(host)],
        iconType: 'web',
      );
    }

    if (_hostMatches(host, 'notion.so') ||
        _hostMatches(host, 'notion.site')) {
      return const UrlClassification(
        category: '학습법',
        tags: ['Notion'],
        iconType: 'web',
      );
    }

    if (_hostMatches(host, 'arxiv.org') ||
        _hostMatches(host, 'semanticscholar.org') ||
        _hostMatches(host, 'scholar.google.com')) {
      return const UrlClassification(
        category: '전공',
        tags: ['논문'],
        iconType: 'document',
      );
    }

    if (_hostMatches(host, 'inflearn.com') ||
        _hostMatches(host, 'coursera.org') ||
        _hostMatches(host, 'udemy.com') ||
        _hostMatches(host, 'fastcampus.co.kr')) {
      return UrlClassification(
        category: '학습법',
        tags: [_platformTag(host)],
        iconType: 'web',
      );
    }

    if (_hostMatches(host, 'twitter.com') ||
        _hostMatches(host, 'x.com') ||
        _hostMatches(host, 'tiktok.com')) {
      return UrlClassification(
        category: '자기계발',
        tags: [_platformTag(host)],
        iconType: 'social',
      );
    }

    if (_hostMatches(host, 'naver.com') && lower.contains('blog')) {
      return const UrlClassification(
        category: '학습법',
        tags: ['Naver Blog'],
        iconType: 'web',
      );
    }

    if (RegExp(r'\.(pdf|doc|docx|ppt|pptx|xls|xlsx)(\?|$)', caseSensitive: false)
        .hasMatch(lower)) {
      return const UrlClassification(
        category: '전공',
        tags: ['문서'],
        iconType: 'document',
      );
    }

    return const UrlClassification(
      category: '미분류',
      tags: [],
      iconType: 'web',
    );
  }

  static String _platformTag(String host) {
    if (host.contains('github')) return 'GitHub';
    if (host.contains('gitlab')) return 'GitLab';
    if (host.contains('stackoverflow')) return 'Stack Overflow';
    if (host.contains('velog')) return 'Velog';
    if (host.contains('tistory')) return 'Tistory';
    if (host.contains('inflearn')) return 'Inflearn';
    if (host.contains('coursera')) return 'Coursera';
    if (host.contains('udemy')) return 'Udemy';
    if (host.contains('fastcampus')) return 'Fastcampus';
    if (host.contains('twitter') || host == 'x.com') return 'X';
    if (host.contains('tiktok')) return 'TikTok';
    if (host.contains('nomadcoders')) return 'Nomad Coders';
    return host.split('.').first;
  }

  static UrlClassification _resolveMetadata(
    String rawUrl, {
    required String category,
    List<String>? tags,
    String? iconType,
  }) {
    final normalized = normalizeUrl(rawUrl);
    final userTags = tags ?? const [];

    if (category != '미분류' || userTags.isNotEmpty) {
      return UrlClassification(
        category: category,
        tags: userTags,
        iconType: iconType ?? inferIconType(normalized),
      );
    }

    final auto = classifyFromUrl(normalized);
    if (auto.category != '미분류') {
      return UrlClassification(
        category: auto.category,
        tags: auto.tags,
        iconType: iconType ?? auto.iconType,
      );
    }

    return UrlClassification(
      category: category,
      tags: userTags,
      iconType: iconType ?? inferIconType(normalized),
    );
  }

  static String inferIconType(String url) {
    return classifyFromUrl(url).iconType;
  }

  IconData get icon {
    switch (iconType) {
      case 'youtube':
        return Icons.play_circle_outline;
      case 'document':
        return Icons.description_outlined;
      case 'social':
        return Icons.photo_camera_outlined;
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
    String? category,
    List<String>? tags,
    bool? watchLater,
    String? source,
  }) {
    final nextUrl = url ?? this.url;
    return UrlItem(
      id: id,
      url: nextUrl,
      title: title ?? this.title,
      category: category ?? this.category,
      tags: tags ?? this.tags,
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
      'category': category,
      'tags': tags,
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
      category: json['category'] as String? ?? '미분류',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      watchLater: json['watchLater'] as bool? ?? false,
      source: json['source'] as String? ?? 'manual',
      savedAt: rawSaved is String ? DateTime.parse(rawSaved) : DateTime.now(),
      iconType: json['iconType'] as String?,
    );
  }
}
