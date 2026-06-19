import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/safety/screens/main_shell.dart';

void main() {
  runApp(const CivicPulseApp());
}

class CivicPulseApp extends StatelessWidget {
  const CivicPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GBV Safe Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
