import 'package:google_sign_in/google_sign_in.dart';

const String _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
const String _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

class GoogleAuthService {
  static bool _initialized = false;

  static Future<void> _initialize() async {
    if (_initialized) return;

    await GoogleSignIn.instance.initialize(
      clientId: _googleClientId.isEmpty ? null : _googleClientId,
      serverClientId: _googleServerClientId.isEmpty
          ? (_googleClientId.isEmpty ? null : _googleClientId)
          : _googleServerClientId,
    );

    _initialized = true;
  }

  static Future<String?> signInAndGetIdToken() async {
    await _initialize();

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
