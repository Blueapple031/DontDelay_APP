import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType { classicGray, limeCoral }

extension AppThemeTypeLabel on AppThemeType {
  String get label => switch (this) {
    AppThemeType.classicGray => '클래식',
    AppThemeType.limeCoral => '라임코랄',
  };
}

final themeProvider = AsyncNotifierProvider<ThemeNotifier, AppThemeType>(
  ThemeNotifier.new,
);

class ThemeNotifier extends AsyncNotifier<AppThemeType> {
  static const _key = 'app_theme';

  @override
  Future<AppThemeType> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    return switch (saved) {
      'classicGray' => AppThemeType.classicGray,
      'limeCoral' => AppThemeType.limeCoral,
      'grayscale' => AppThemeType.limeCoral,
      'blue' || 'greenTea' => AppThemeType.classicGray,
      _ => AppThemeType.classicGray,
    };
  }

  Future<void> setTheme(AppThemeType theme) async {
    state = AsyncData(theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }
}
