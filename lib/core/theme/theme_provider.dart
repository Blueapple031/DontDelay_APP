import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType {
  grayscale,
  blue,
  greenTea,
}

extension AppThemeTypeLabel on AppThemeType {
  String get label => switch (this) {
        AppThemeType.grayscale => '무채색',
        AppThemeType.blue => '블루',
        AppThemeType.greenTea => '녹차',
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
    if (saved != null) {
      return AppThemeType.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppThemeType.grayscale,
      );
    }
    return AppThemeType.grayscale;
  }

  Future<void> setTheme(AppThemeType theme) async {
    state = AsyncData(theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }
}
