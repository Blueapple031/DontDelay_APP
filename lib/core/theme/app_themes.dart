import 'package:flutter/material.dart';
import 'theme_provider.dart';

/// 추후 테마 추가 시: AppThemeType 에 enum 값 추가 → 여기에 static 필드 추가 →
/// getTheme() switch 에 case 추가하면 됩니다.
class AppThemes {
  AppThemes._();

  static ThemeData getTheme(AppThemeType type) {
    return switch (type) {
      AppThemeType.classicGray => _classicGray,
      AppThemeType.limeCoral => _limeCoral,
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

  // ─── 클래식 흑백 테마 ─────────────────────────────────────────────────────
  // 높은 대비의 뉴트럴 팔레트로 정보 구조가 또렷하게 보이도록 구성합니다.
  static final ThemeData _classicGray = _base(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF111827),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE5E7EB),
      onPrimaryContainer: Color(0xFF111827),
      secondary: Color(0xFF4B5563),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF3F4F6),
      onSecondaryContainer: Color(0xFF1F2937),
      error: Color(0xFFB42318),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFEE4E2),
      onErrorContainer: Color(0xFF7A271A),
      surface: Color(0xFFF7F8FA),
      onSurface: Color(0xFF111827),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFF4B5563),
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF111827),
      onInverseSurface: Color(0xFFF9FAFB),
      inversePrimary: Color(0xFFE5E7EB),
    ),
  );

  // ─── 라임 코랄 테마 ────────────────────────────────────────────────────────
  // 라임과 살구빛 코랄을 중심으로 따뜻하지만 산만하지 않게 구성합니다.
  static final ThemeData _limeCoral = _base(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF7D8F24),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFC3DC68),
      onPrimaryContainer: Color(0xFF303A05),
      secondary: Color(0xFFC87432),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF7D3B8),
      onSecondaryContainer: Color(0xFF4E2507),
      error: Color(0xFFC2410C),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFE4D1),
      onErrorContainer: Color(0xFF7C2D12),
      surface: Color(0xFFFAFBF2),
      onSurface: Color(0xFF232619),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFF6F735F),
      outline: Color(0xFFD6DDBE),
      outlineVariant: Color(0xFFE9EED6),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF303324),
      onInverseSurface: Color(0xFFFAFBF2),
      inversePrimary: Color(0xFFDCEB94),
    ),
  );
}
