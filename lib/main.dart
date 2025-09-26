import 'package:flutter/material.dart';
import 'screen/home_screen.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Timer',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
