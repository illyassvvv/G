import 'package:flutter/material.dart';
import '../screens/root_shell.dart';
import 'theme.dart';
import 'theme_notifier.dart';

class StreamGoApp extends StatelessWidget {
  const StreamGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp whenever dark mode is toggled
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StreamGo',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const RootShell(),
        );
      },
    );
  }
}
