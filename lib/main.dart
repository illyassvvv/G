import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.darkBg,
  ));
  runApp(const IlyassTvApp());
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _isDark ? AppTheme.darkBg : AppTheme.lightBg,
    ));
    notifyListeners();
  }
}

final themeNotifier = ThemeNotifier();

class IlyassTvApp extends StatefulWidget {
  const IlyassTvApp({super.key});
  @override
  State<IlyassTvApp> createState() => _IlyassTvAppState();
}

class _IlyassTvAppState extends State<IlyassTvApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ilyass tv',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.isDark ? AppTheme.dark : AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
