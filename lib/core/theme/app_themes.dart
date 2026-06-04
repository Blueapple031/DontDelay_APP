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
  static TextStyle _fix(TextStyle? s, FontWeight weight) =>
      (s ?? const TextStyle()).copyWith(
        fontFamily: 'NanumSquareNeo',
        fontWeight: weight,
        leadingDistribution: TextLeadingDistribution.even,
      );

  static TextTheme _fixedTextTheme(TextTheme base) => base.copyWith(
    // 큰 제목 계열 → ExtraBold (w800)
    displayLarge: _fix(base.displayLarge, FontWeight.w800),
    displayMedium: _fix(base.displayMedium, FontWeight.w800),
    displaySmall: _fix(base.displaySmall, FontWeight.w800),
    // 헤드라인 계열 → Bold (w700)
    headlineLarge: _fix(base.headlineLarge, FontWeight.w700),
    headlineMedium: _fix(base.headlineMedium, FontWeight.w700),
    headlineSmall: _fix(base.headlineSmall, FontWeight.w700),
    // 타이틀 계열 → w600 (500·600은 Flutter가 w700로 대체)
    titleLarge: _fix(base.titleLarge, FontWeight.w600),
    titleMedium: _fix(base.titleMedium, FontWeight.w600),
    titleSmall: _fix(base.titleSmall, FontWeight.w600),
    // 본문 계열 → Regular (w400)
    bodyLarge: _fix(base.bodyLarge, FontWeight.w400),
    bodyMedium: _fix(base.bodyMedium, FontWeight.w400),
    bodySmall: _fix(base.bodySmall, FontWeight.w400),
    // 레이블 계열 → w500·w600 (강조, Flutter가 가장 가까운 굵기로 대체)
    labelLarge: _fix(base.labelLarge, FontWeight.w600),
    labelMedium: _fix(base.labelMedium, FontWeight.w500),
    labelSmall: _fix(base.labelSmall, FontWeight.w500),
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

  // ─── 클래식 회색 테마 ─────────────────────────────────────────────────────
  // 변경 전 기본 테마입니다.
  static final ThemeData _classicGray = _base(
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
