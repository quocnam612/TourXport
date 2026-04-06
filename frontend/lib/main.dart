// import 'package:flutter/material.dart';
// import 'screens/welcome.dart'; // Đảm bảo đúng đường dẫn file

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         fontFamily: 'Poppins', // Đảm bảo đã khai báo trong pubspec.yaml
//         useMaterial3: true,
//       ),
//       home: const WelcomeScreen(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'screens/landing_page.dart';

void main() {
  runApp(const TourXportApp());
}

class TourXportApp extends StatelessWidget {
  const TourXportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TourXport',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Be Vietnam Pro',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}