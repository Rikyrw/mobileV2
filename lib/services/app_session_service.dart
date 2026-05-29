import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  const AppSession({
    required this.email,
    required this.accessToken,
    required this.lastOpenedAt,
  });

  final String email;
  final String? accessToken;
  final DateTime lastOpenedAt;
}

class AppSessionService {
  AppSessionService._();

  static const Duration sessionTtl = Duration(days: 3);
  static const String _emailKey = 'greenpoint.session.email';
  static const String _accessTokenKey = 'greenpoint.session.access_token';
  static const String _lastOpenedAtKey = 'greenpoint.session.last_opened_at';

  static Future<void> remember({
    required String? email,
    String? accessToken,
  }) async {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, normalizedEmail);

    final cleanToken = accessToken?.trim();
    if (cleanToken == null || cleanToken.isEmpty) {
      await prefs.remove(_accessTokenKey);
    } else {
      await prefs.setString(_accessTokenKey, cleanToken);
    }

    await prefs.setInt(_lastOpenedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<AppSession?> restoreValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey)?.trim().toLowerCase();
    final lastOpenedMillis = prefs.getInt(_lastOpenedAtKey);

    if (email == null || email.isEmpty || lastOpenedMillis == null) {
      await clear();
      return null;
    }

    final lastOpenedAt = DateTime.fromMillisecondsSinceEpoch(lastOpenedMillis);
    if (DateTime.now().difference(lastOpenedAt) >= sessionTtl) {
      await clear();
      return null;
    }

    await prefs.setInt(_lastOpenedAtKey, DateTime.now().millisecondsSinceEpoch);

    return AppSession(
      email: email,
      accessToken: prefs.getString(_accessTokenKey)?.trim(),
      lastOpenedAt: lastOpenedAt,
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_lastOpenedAtKey);
  }
}
