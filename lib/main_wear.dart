import 'package:flutter/material.dart';
import 'package:wear/wear.dart';
import 'core/theme/theme.dart';
import 'screens/wear/wear_home_screen.dart';

@pragma('vm:entry-point')
void main() => runApp(const WearApp());

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Oustad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: WatchShape(
        builder: (context, shape, _) => WearHomeScreen(shape: shape),
      ),
    );
  }
}
