import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'screens/landing_page.dart';
import 'screens/dashboard.dart';

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
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // home: const LandingPage(),

      home: const HomeScreen(
        userName: "Khách",
        authToken: null
      ) // dashboard first
      
    );
  }
}