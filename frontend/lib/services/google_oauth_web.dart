import 'dart:async';
import 'dart:html' as html;
import 'dart:math';

Future<String?> signInWithGoogleWeb(String clientId) {
  if (clientId.trim().isEmpty) {
    throw StateError(
      'Missing GOOGLE_CLIENT_ID. Run with --dart-define=GOOGLE_CLIENT_ID=your_web_client_id.apps.googleusercontent.com.',
    );
  }

  final state = _randomString(24);
  final nonce = _randomString(24);
  final redirectUri = '${html.window.location.origin}/oauth/google_callback.html';
  final query = <String, String>{
    'client_id': clientId.trim(),
    'redirect_uri': redirectUri,
    'response_type': 'id_token',
    'scope': 'openid email profile',
    'nonce': nonce,
    'state': state,
    'prompt': 'select_account',
  };
  final authUrl = Uri.https(
    'accounts.google.com',
    '/o/oauth2/v2/auth',
    query,
  ).toString();

  final popup = html.window.open(
    authUrl,
    'tourxport_google_login',
    'width=520,height=720,menubar=no,toolbar=no,location=no,status=no',
  );

  if (popup.closed == true) {
    throw StateError('Google popup was blocked by the browser.');
  }

  final completer = Completer<String?>();
  late StreamSubscription<html.MessageEvent> messageSub;
  Timer? closeTimer;

  void finish(String? idToken, [Object? error]) {
    if (completer.isCompleted) return;
    messageSub.cancel();
    closeTimer?.cancel();
    popup.close();

    if (error != null) {
      completer.completeError(error);
      return;
    }

    completer.complete(idToken);
  }

  messageSub = html.window.onMessage.listen((event) {
    if (event.origin != html.window.location.origin) return;

    final data = event.data;
    if (data is! Map) return;
    if (data['type'] != 'tourxport_google_oauth') return;
    if (data['state'] != state) return;

    final error = data['error'];
    if (error is String && error.isNotEmpty) {
      finish(null, StateError('Google OAuth failed: $error'));
      return;
    }

    final idToken = data['idToken'];
    if (idToken is String && idToken.isNotEmpty) {
      finish(idToken);
      return;
    }

    finish(null, StateError('Google did not return an ID token.'));
  });

  closeTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
    if (popup.closed == true) {
      finish(null);
    }
  });

  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () {
      finish(null, StateError('Google login timed out.'));
      return null;
    },
  );
}

String _randomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}
