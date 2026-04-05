import 'package:flutter/material.dart';
import 'screens/welcome.dart'; // Đảm bảo đúng đường dẫn file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins', // Đảm bảo đã khai báo trong pubspec.yaml
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}