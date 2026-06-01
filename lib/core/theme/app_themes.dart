import 'package:flutter/material.dart';
import 'theme_provider.dart';

/// 추후 테마 추가 시: AppThemeType 에 enum 값 추가 → 여기에 static 필드 추가 →
/// getTheme() switch 에 case 추가하면 됩니다.
class AppThemes {
  AppThemes._();

  static ThemeData getTheme(AppThemeType type) {
    return switch (type) {
      AppThemeType.grayscale => _grayscale,
      AppThemeType.blue => _blue,
      AppThemeType.greenTea => _greenTea,
    };
  }

  // ─── 공통 설정 헬퍼 ────────────────────────────────────────────────────────

  /// BusanBada 폰트의 ascender 값이 커서 텍스트가 위로 뜨는 문제를
  /// leadingDistribution.even 으로 수직 여백을 균등 배분해 교정합니다.
  static TextStyle _fix(TextStyle? s) => (s ?? const TextStyle()).copyWith(
    fontFamily: 'NanumSquareNeo',
    leadingDistribution: TextLeadingDistribution.even,
  );

  static TextTheme _fixedTextTheme(TextTheme base) => base.copyWith(
    displayLarge: _fix(base.displayLarge),
    displayMedium: _fix(base.displayMedium),
    displaySmall: _fix(base.displaySmall),
    headlineLarge: _fix(base.headlineLarge),
    headlineMedium: _fix(base.headlineMedium),
    headlineSmall: _fix(base.headlineSmall),
    titleLarge: _fix(base.titleLarge),
    titleMedium: _fix(base.titleMedium),
    titleSmall: _fix(base.titleSmall),
    bodyLarge: _fix(base.bodyLarge),
    bodyMedium: _fix(base.bodyMedium),
    bodySmall: _fix(base.bodySmall),
    labelLarge: _fix(base.labelLarge),
    labelMedium: _fix(base.labelMedium),
    labelSmall: _fix(base.labelSmall),
  );

  static ThemeData _base({required ColorScheme colorScheme}) {
    final raw = ThemeData(
      useMaterial3: true,
      fontFamily: 'NanumSquareNeo',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      dividerColor: colorScheme.outlineVariant,
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
    return raw.copyWith(
      textTheme: _fixedTextTheme(raw.textTheme),
      primaryTextTheme: _fixedTextTheme(raw.primaryTextTheme),
    );
  }

  // ─── 무채색 테마 (기본) ────────────────────────────────────────────────────
  // 연한 회색빛, 뽀얗고 경계가 흐릿한 느낌
  static final ThemeData _grayscale = _base(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF8E8E8E),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFEBEBEB),
      onPrimaryContainer: Color(0xFF5A5A5A),
      secondary: Color(0xFFAAAAAA),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF2F2F2),
      onSecondaryContainer: Color(0xFF6A6A6A),
      error: Color(0xFFB08A8A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF5EAEA),
      onErrorContainer: Color(0xFF7A5050),
      surface: Color(0xFFF8F8F8),
      onSurface: Color(0xFF4A4A4A),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFF7A7A7A),
      outline: Color(0xFFD8D8D8),
      outlineVariant: Color(0xFFECECEC),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF4A4A4A),
      onInverseSurface: Color(0xFFF8F8F8),
      inversePrimary: Color(0xFFCCCCCC),
    ),
  );

  // ─── 푸른 계열 테마 ────────────────────────────────────────────────────────
  // 연한 안개빛 슬레이트 블루, 차분하고 미지근한 느낌
  static final ThemeData _blue = _base(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF7A9AB8),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFD8E6F0),
      onPrimaryContainer: Color(0xFF486880),
      secondary: Color(0xFF9AAEC2),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE4EEF7),
      onSecondaryContainer: Color(0xFF5A7890),
      error: Color(0xFFB09090),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF0E8E8),
      onErrorContainer: Color(0xFF786060),
      surface: Color(0xFFF3F7FB),
      onSurface: Color(0xFF3A4A58),
      surfaceContainerLowest: Color(0xFFF9FBFE),
      onSurfaceVariant: Color(0xFF607080),
      outline: Color(0xFFC2D2E0),
      outlineVariant: Color(0xFFDDE8F2),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF3A4A58),
      onInverseSurface: Color(0xFFF3F7FB),
      inversePrimary: Color(0xFFACC8DC),
    ),
  );

  // ─── 녹차색 계열 테마 ─────────────────────────────────────────────────────
  // 연한 안개빛 세이지 그린, 따뜻하고 밋밋한 느낌
  static final ThemeData _greenTea = _base(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF7A9E80),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFD5EAD8),
      onPrimaryContainer: Color(0xFF486850),
      secondary: Color(0xFF96B09A),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE2F0E5),
      onSecondaryContainer: Color(0xFF587060),
      error: Color(0xFFB09080),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF0EAE4),
      onErrorContainer: Color(0xFF786050),
      surface: Color(0xFFF3F8F4),
      onSurface: Color(0xFF384840),
      surfaceContainerLowest: Color(0xFFF8FCF9),
      onSurfaceVariant: Color(0xFF587860),
      outline: Color(0xFFBDD0C0),
      outlineVariant: Color(0xFFDBEEDE),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF384840),
      onInverseSurface: Color(0xFFF3F8F4),
      inversePrimary: Color(0xFFAAC8AE),
    ),
  );
}
