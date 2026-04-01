import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final globalLoadingProvider = NotifierProvider<GlobalLoadingNotifier, bool>(
  GlobalLoadingNotifier.new,
);

class GlobalLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;
  void hide() => state = false;
}

class GlobalProgressBar extends ConsumerWidget {
  const GlobalProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(globalLoadingProvider);
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? LinearProgressIndicator(
              key: const ValueKey('loading'),
              minHeight: 2.5,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            )
          : const SizedBox.shrink(key: ValueKey('idle')),
    );
  }
}
