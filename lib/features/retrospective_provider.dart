import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'retrospective.dart';

final retrospectiveServiceProvider = Provider((ref) => RetrospectiveService());

/// 대시보드 진입 시마다 최신 회고록을 불러옵니다.
final retrospectiveListProvider =
    FutureProvider.autoDispose<List<RetrospectiveItem>>((ref) async {
  return ref.read(retrospectiveServiceProvider).loadRetrospectives();
});
