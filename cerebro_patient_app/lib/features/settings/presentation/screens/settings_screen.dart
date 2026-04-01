import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_themes.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/animated_list_item.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AnimatedListItem(
            index: 0,
            child: Text('Appearance',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          ...AppThemeType.values.asMap().entries.map((entry) {
            final i = entry.key;
            final type = entry.value;
            final isSelected = type == currentTheme;

            return AnimatedListItem(
              index: i + 1,
              child: _ThemeOption(
                type: type,
                isSelected: isSelected,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(type),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppThemeType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected
            ? primary.withValues(alpha: 0.08)
            : theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? primary
                    : theme.dividerTheme.color ?? Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _gradientForType(type),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconForType(type),
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameForType(type),
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _descForType(type),
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _nameForType(AppThemeType t) {
    switch (t) {
      case AppThemeType.light:
        return 'Light';
      case AppThemeType.dark:
        return 'Dark';
      case AppThemeType.system:
        return 'System';
      case AppThemeType.neon:
        return 'Neon';
      case AppThemeType.glass:
        return 'Glassmorphism';
    }
  }

  static String _descForType(AppThemeType t) {
    switch (t) {
      case AppThemeType.light:
        return 'Clean and bright — classic look';
      case AppThemeType.dark:
        return 'Easy on the eyes — navy palette';
      case AppThemeType.system:
        return 'Follows your device settings';
      case AppThemeType.neon:
        return 'Vibrant neon accents on dark';
      case AppThemeType.glass:
        return 'Translucent frosted glass aesthetic';
    }
  }

  static IconData _iconForType(AppThemeType t) {
    switch (t) {
      case AppThemeType.light:
        return Icons.light_mode_rounded;
      case AppThemeType.dark:
        return Icons.dark_mode_rounded;
      case AppThemeType.system:
        return Icons.settings_brightness_rounded;
      case AppThemeType.neon:
        return Icons.flash_on_rounded;
      case AppThemeType.glass:
        return Icons.blur_on_rounded;
    }
  }

  static List<Color> _gradientForType(AppThemeType t) {
    switch (t) {
      case AppThemeType.light:
        return const [Color(0xFF14919B), Color(0xFF45D97B)];
      case AppThemeType.dark:
        return const [Color(0xFF0D2137), Color(0xFF14919B)];
      case AppThemeType.system:
        return const [Color(0xFF6366F1), Color(0xFF8B5CF6)];
      case AppThemeType.neon:
        return const [Color(0xFFFF2D95), Color(0xFF00F0FF)];
      case AppThemeType.glass:
        return const [Color(0xFF94A3B8), Color(0xFFCBD5E1)];
    }
  }
}
