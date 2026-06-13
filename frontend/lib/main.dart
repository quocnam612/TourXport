import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'api/api.dart';
import 'utils/locale_manager.dart';
import 'utils/auth_storage.dart';
import 'screens/landing_page.dart';
import 'screens/sign_in.dart';
import 'screens/sign_up.dart';
import 'screens/dashboard.dart';
import 'screens/legal/contact_support_screen.dart';
import 'screens/legal/instruction_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/shared_handler_screen.dart';
import 'screens/legal/terms_of_service_screen.dart';
import 'screens/app_reviews_screen.dart';
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

  setUnauthorizedHandler((_) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  });

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
  MaterialPageRoute _homeRoute(
    RouteSettings settings,
    int initialTabIndex, {
    String? initialScheduleMode,
  }) {
    final args = settings.arguments;
    String? authToken = widget.initialToken;
    String? userName = widget.initialUserName;

    if (args is Map) {
      authToken = args['authToken'] as String? ?? authToken;
      userName = args['userName'] as String? ?? userName;
    } else if (args is String) {
      authToken = args;
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => HomeScreen(
        userName: userName ?? 'bạn',
        authToken: authToken,
        initialTabIndex: initialTabIndex,
        initialScheduleMode: initialScheduleMode,
      ),
    );
  }

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
              final uri = Uri.parse(settings.name ?? '/');
              final routeName = uri.path;

              if (routeName == '/home') {
                return _homeRoute(settings, 0);
              }

              if (routeName == '/login') {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const SignInScreen(),
                );
              }

              if (routeName == '/signup') {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const SignUpScreen(),
                );
              }

              if (routeName == '/search') {
                return _homeRoute(settings, 1);
              }

              if (routeName == '/saved') {
                return _homeRoute(settings, 2);
              }

              if (routeName == '/tours' || routeName == '/generate') {
                return _homeRoute(settings, 3);
              }

              if (routeName == '/tours/generate') {
                return _homeRoute(
                  settings,
                  3,
                  initialScheduleMode: 'ai',
                );
              }

              if (routeName == '/tours/manual') {
                return _homeRoute(
                  settings,
                  3,
                  initialScheduleMode: 'manual',
                );
              }

              if (routeName == '/tours/history') {
                return _homeRoute(
                  settings,
                  3,
                  initialScheduleMode: 'history',
                );
              }

              if (routeName == '/account') {
                return _homeRoute(settings, 4);
              }

              if (routeName == '/location' || routeName == '/place') {
                final id = uri.queryParameters['id'] ?? '';
                final type = uri.queryParameters['type'] ?? 'place';
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => SharedHandlerScreen(id: id, type: type),
                );
              }

              if (routeName == '/tour') {
                final id = uri.queryParameters['id'] ?? '';
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => SharedHandlerScreen(id: id, type: 'tour'),
                );
              }

              if (routeName.startsWith('/tours/')) {
                final id = uri.pathSegments.length >= 2 ? uri.pathSegments[1] : '';
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => SharedHandlerScreen(id: id, type: 'tour'),
                );
              }

              if (routeName == '/privacy') {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const PrivacyPolicyScreen(),
                );
              }

              if (routeName == '/terms') {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const TermsOfServiceScreen(),
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

              if (routeName == '/report') {
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
