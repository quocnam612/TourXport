import 'dart:async';
import 'dart:math';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

const String _discordCallbackScheme = 'tourxport';
const String _discordRedirectUri = 'https://tourxport.netlify.app/oauth/discord_callback.html';

Future<Map<String, String>?> signInWithDiscordWeb(String clientId) async {
  if (clientId.trim().isEmpty) {
    throw StateError(
      'Missing DISCORD_CLIENT_ID. Run with --dart-define=DISCORD_CLIENT_ID=your_discord_client_id.',
    );
  }

  final state = _randomString(24);
  final authUrl = Uri.https(
    'discord.com',
    '/oauth2/authorize',
    <String, String>{
      'client_id': clientId.trim(),
      'redirect_uri': _discordRedirectUri,
      'response_type': 'code',
      'scope': 'identify email',
      'state': state,
    },
  ).toString();

  final result = await FlutterWebAuth2.authenticate(
    url: authUrl,
    callbackUrlScheme: _discordCallbackScheme,
  ).timeout(const Duration(minutes: 2));

  final resultUri = Uri.parse(result);
  final returnedState = resultUri.queryParameters['state'];
  if (returnedState != state) {
    throw StateError('Discord OAuth state mismatch.');
  }

  final error = resultUri.queryParameters['error'];
  if (error != null && error.isNotEmpty) {
    throw StateError('Discord OAuth failed: $error');
  }

  final code = resultUri.queryParameters['code'];
  if (code == null || code.isEmpty) {
    throw StateError('Discord did not return an authorization code.');
  }

  return {
    'code': code,
    'redirectUri': _discordRedirectUri,
  };
}

String _randomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}
