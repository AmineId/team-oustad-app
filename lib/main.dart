import 'package:flutter/material.dart';
import 'screens/connection_test_screen.dart';

void main() {
  runApp(const TeamFitnessApp());
}

class TeamFitnessApp extends StatelessWidget {
  const TeamFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Fitness',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ConnectionTestScreen(),
    );
  }
}
