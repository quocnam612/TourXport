import 'dart:async';
import 'dart:html' as html;
import 'dart:math';

Future<Map<String, String>?> signInWithDiscordWeb(String clientId) {
  if (clientId.trim().isEmpty) {
    throw StateError(
      'Missing DISCORD_CLIENT_ID. Run with --dart-define=DISCORD_CLIENT_ID=your_discord_client_id.',
    );
  }

  final state = _randomString(24);
  final redirectUri = '${html.window.location.origin}/oauth/discord_callback.html';
  final query = <String, String>{
    'client_id': clientId.trim(),
    'redirect_uri': redirectUri,
    'response_type': 'code',
    'scope': 'identify email',
    'state': state,
  };
  final authUrl = Uri.https(
    'discord.com',
    '/oauth2/authorize',
    query,
  ).toString();

  final popup = html.window.open(
    authUrl,
    'tourxport_discord_login',
    'width=520,height=720,menubar=no,toolbar=no,location=no,status=no',
  );

  if (popup.closed == true) {
    throw StateError('Discord popup was blocked by the browser.');
  }

  final completer = Completer<Map<String, String>?>();
  late StreamSubscription<html.MessageEvent> messageSub;
  Timer? closeTimer;

  void finish(Map<String, String>? result, [Object? error]) {
    if (completer.isCompleted) return;
    messageSub.cancel();
    closeTimer?.cancel();
    popup.close();

    if (error != null) {
      completer.completeError(error);
      return;
    }

    completer.complete(result);
  }

  messageSub = html.window.onMessage.listen((event) {
    if (event.origin != html.window.location.origin) return;

    final data = event.data;
    if (data is! Map) return;
    if (data['type'] != 'tourxport_discord_oauth') return;
    if (data['state'] != state) return;

    final error = data['error'];
    if (error is String && error.isNotEmpty) {
      finish(null, StateError('Discord OAuth failed: $error'));
      return;
    }

    final code = data['code'];
    if (code is String && code.isNotEmpty) {
      finish({
        'code': code,
        'redirectUri': redirectUri,
      });
      return;
    }

    finish(null, StateError('Discord did not return an authorization code.'));
  });

  closeTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
    if (popup.closed == true) {
      finish(null);
    }
  });

  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () {
      finish(null, StateError('Discord login timed out.'));
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
