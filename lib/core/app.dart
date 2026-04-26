import 'package:flutter/material.dart';
import '../screens/root_shell.dart';
import 'motion.dart';
import 'theme.dart';
import 'theme_notifier.dart';

class StreamGoApp extends StatelessWidget {
  const StreamGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StreamGo',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          themeAnimationDuration: Motion.normal,
          themeAnimationCurve: Motion.emphasized,
          home: const RootShell(),
        );
      },
    );
  }
}
