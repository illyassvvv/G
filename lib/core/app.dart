import 'package:flutter/material.dart';
import '../screens/root_shell.dart';
import 'theme.dart';

class StreamGoApp extends StatelessWidget {
  const StreamGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StreamGo',
      theme: AppTheme.dark, // FIX: was using inline ThemeData, ignoring AppTheme
      home: const RootShell(),
    );
  }
}
