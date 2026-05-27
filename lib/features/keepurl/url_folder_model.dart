import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 기본 생성 폴더 (도메인 자동 분류와 매칭)
const kDefaultFolderNames = [
  '미분류',
  'YouTube',
  'Instagram',
  '개발',
  '전공',
  '학습법',
  '자기계발',
];

class UrlFolder {
  final String id;
  final String name;
  final int sortOrder;

  const UrlFolder({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  static const defaultFolderName = '미분류';

  UrlFolder copyWith({String? name, int? sortOrder}) {
    return UrlFolder(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sortOrder': sortOrder,
      };

  factory UrlFolder.fromJson(Map<String, dynamic> json) {
    return UrlFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  static List<UrlFolder> createDefaults() {
    return List.generate(
      kDefaultFolderNames.length,
      (i) => UrlFolder(
        id: _uuid.v4(),
        name: kDefaultFolderNames[i],
        sortOrder: i,
      ),
    );
  }
}
