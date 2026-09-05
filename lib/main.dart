import 'package:flutter/material.dart';
import 'theme/cyber_theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const NeuroAIDashboardApp());
}

class NeuroAIDashboardApp extends StatelessWidget {
  const NeuroAIDashboardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neuro AI Synthesis Engine',
      debugShowCheckedModeBanner: false,
      theme: CyberTheme.themeData,
      home: const DashboardScreen(),
    );
  }
}
