import 'discord_oauth_stub.dart'
    if (dart.library.html) 'discord_oauth_web.dart';

const String _discordClientId = String.fromEnvironment('DISCORD_CLIENT_ID');

class DiscordAuthService {
  static Future<Map<String, String>?> signInAndGetAuthorizationCode() {
    return signInWithDiscordWeb(_discordClientId);
  }
}
