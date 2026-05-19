import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.activityRecognition,
    Permission.sensors,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4ECDC4),
          secondary: Color(0xFFFF6B35),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}