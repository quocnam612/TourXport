import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'utils/locale_manager.dart';
import 'utils/auth_storage.dart';
import 'screens/landing_page.dart';
import 'screens/dashboard.dart';
import 'screens/legal/contact_support_screen.dart';
import 'screens/legal/data_deletion_screen.dart';
import 'screens/legal/instruction_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/app_reviews_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'widgets/app_lock_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleManager.init();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  final token = await AuthStorage.getToken();
  final userName = await AuthStorage.getUserName();

  runApp(TourXportApp(
    initialToken: token,
    initialUserName: userName,
  ));
}

class TourXportApp extends StatefulWidget {
  final String? initialToken;
  final String? initialUserName;

  const TourXportApp({
    super.key,
    this.initialToken,
    this.initialUserName,
  });

  @override
  State<TourXportApp> createState() => _TourXportAppState();
}

class _TourXportAppState extends State<TourXportApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleManager.localeNotifier,
      builder: (context, currentLocale, _) {
        return AppLockWrapper(
          navigatorKey: navigatorKey,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'TourXport',
            debugShowCheckedModeBanner: false,
            locale: currentLocale,
            localizationsDelegates: const [
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

              if (routeName == '/app-reviews') {
                final authToken = settings.arguments as String?;
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => AppReviewsScreen(authToken: authToken),
                );
              }

              return null;
            },
          ),
        );
      },
    );
  }
}
