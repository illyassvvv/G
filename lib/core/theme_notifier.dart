import 'package:flutter/material.dart';

/// Global theme notifier — toggle dark mode from anywhere.
/// Listen with ValueListenableBuilder in app.dart.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

void setDarkMode(bool dark) {
  themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
}

bool get isDarkMode => themeNotifier.value == ThemeMode.dark;
