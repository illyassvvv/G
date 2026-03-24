import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/theme.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final appProvider = AppProvider();
  await appProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const VarGasTvApp(),
    ),
  );
}

class VarGasTvApp extends StatelessWidget {
  const VarGasTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return MaterialApp(
      title: 'VarGasTv',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  prov.themeMode,
      home: const HomeScreen(),
    );
  }
}
