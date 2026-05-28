import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

const String _facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');

class FacebookAuthService {
  static Future<String?> signInAndGetAccessToken() async {
    if (kIsWeb && _facebookAppId.isEmpty) {
      throw StateError(
        'Missing FACEBOOK_APP_ID. Run with --dart-define=FACEBOOK_APP_ID=your_app_id.',
      );
    }

    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.cancelled) {
      return null;
    }

    if (result.status != LoginStatus.success) {
      throw StateError(result.message ?? 'Facebook login failed.');
    }

    final token = result.accessToken?.tokenString;
    if (token == null || token.isEmpty) {
      throw StateError('Facebook did not return an access token.');
    }

    return token;
  }
}
