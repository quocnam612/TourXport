import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'screens/landing_page.dart';

const String _facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');
const String _facebookGraphVersion = String.fromEnvironment(
  'FACEBOOK_GRAPH_VERSION',
  defaultValue: 'v20.0',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb && _facebookAppId.isNotEmpty) {
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: _facebookAppId,
      cookie: true,
      xfbml: true,
      version: _facebookGraphVersion,
    );
  }

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
      home: const LandingPage(),
    );
  }
}
