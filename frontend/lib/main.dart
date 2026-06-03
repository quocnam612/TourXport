import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'utils/locale_manager.dart';
import 'screens/landing_page.dart';
import 'screens/dashboard.dart';
import 'screens/legal/contact_support_screen.dart';
import 'screens/legal/data_deletion_screen.dart';
import 'screens/legal/instruction_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleManager.init();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runApp(const TourXportApp());
}

class TourXportApp extends StatelessWidget {
  const TourXportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleManager.localeNotifier,
      builder: (context, currentLocale, _) {
        return MaterialApp(
          title: 'TourXport',
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
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
          onGenerateRoute: (settings) {
            final routeName = Uri.parse(settings.name ?? '/').path;

            if (routeName == '/privacy') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const PrivacyPolicyScreen(),
              );
            }

            if (routeName == '/data-deletion') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const DataDeletionScreen(),
              );
            }

            if (routeName == '/intruction') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const InstructionScreen(),
              );
            }

            if (routeName == '/contact') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const ContactSupportScreen(),
              );
            }

            return null;
          },
          // home: const HomeScreen(userName: 'User', authToken: '123'),
        );
      },
    );
  }
}
