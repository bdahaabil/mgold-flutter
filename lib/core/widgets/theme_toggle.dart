import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      icon: Icon(switch (mode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      }),
      onSelected: (m) => ref.read(themeModeProvider.notifier).setMode(m),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: ThemeMode.system,
          checked: mode == ThemeMode.system,
          child: const Text('System'),
        ),
        CheckedPopupMenuItem(
          value: ThemeMode.light,
          checked: mode == ThemeMode.light,
          child: const Text('Light'),
        ),
        CheckedPopupMenuItem(
          value: ThemeMode.dark,
          checked: mode == ThemeMode.dark,
          child: const Text('Dark'),
        ),
      ],
    );
  }
}
