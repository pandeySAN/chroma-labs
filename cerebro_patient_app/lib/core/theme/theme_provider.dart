import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_themes.dart';

const _themeKey = 'cerebro_theme_pref';

class ThemeNotifier extends Notifier<AppThemeType> {
  @override
  AppThemeType build() {
    _loadFromStorage();
    return AppThemeType.system;
  }

  Future<void> _loadFromStorage() async {
    try {
      const storage = FlutterSecureStorage();
      final stored = await storage.read(key: _themeKey);
      if (stored != null) {
        final type = AppThemeType.values.firstWhere(
          (e) => e.name == stored,
          orElse: () => AppThemeType.system,
        );
        state = type;
      }
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeType type) async {
    state = type;
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: _themeKey, value: type.name);
    } catch (_) {}
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeType>(
  ThemeNotifier.new,
);
