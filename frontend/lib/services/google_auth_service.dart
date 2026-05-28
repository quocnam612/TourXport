import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'google_oauth_stub.dart'
    if (dart.library.html) 'google_oauth_web.dart';

const String _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

class GoogleAuthService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (defaultTargetPlatform == TargetPlatform.android &&
        _googleClientId.isEmpty) {
      throw StateError(
        'Missing GOOGLE_CLIENT_ID. Use the Web OAuth client ID here; Android OAuth client is configured only in Google Cloud.',
      );
    }

    await GoogleSignIn.instance.initialize(
      clientId: _googleClientId.isEmpty ? null : _googleClientId,
      serverClientId: _googleClientId.isEmpty ? null : _googleClientId,
    );

    _initialized = true;
  }

  static bool supportsInteractiveAuthentication() {
    return GoogleSignIn.instance.supportsAuthenticate();
  }

  static Stream<String> get idTokenEvents async* {
    await for (final event in GoogleSignIn.instance.authenticationEvents) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        final idToken = event.user.authentication.idToken;
        if (idToken != null && idToken.isNotEmpty) {
          yield idToken;
        }
      }
    }
  }

  static Future<String?> signInAndGetIdToken() async {
    if (kIsWeb) {
      return signInWithGoogleWeb(_googleClientId);
    }

    await initialize();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google Sign-In on web needs the Google-rendered sign-in button.',
      );
    }

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google did not return an ID token.');
      }

      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }
}
