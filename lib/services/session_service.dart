import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // Keys for storing session data
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyPhoneNumber = 'phoneNumber';
  static const String _keyLoginTimestamp = 'loginTimestamp';
  static const int _sessionDurationDays = 2;

  /// Save login session
  static Future<void> saveSession(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyPhoneNumber, phoneNumber);
    await prefs.setInt(_keyLoginTimestamp, now);
  }

  /// Check if there's an active session (not expired)
  static Future<bool> isSessionActive() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (!isLoggedIn) {
      return false;
    }

    final loginTimestamp = prefs.getInt(_keyLoginTimestamp);
    if (loginTimestamp == null) {
      return false;
    }

    // Check if session has expired (2 days)
    final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
    final now = DateTime.now();
    final difference = now.difference(loginDate);

    if (difference.inDays >= _sessionDurationDays) {
      // Session expired, clear it
      await clearSession();
      return false;
    }

    return true;
  }

  /// Get the saved phone number from session
  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoneNumber);
  }

  /// Clear the session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyPhoneNumber);
    await prefs.remove(_keyLoginTimestamp);
  }

  /// Get session info for debugging
  static Future<Map<String, dynamic>> getSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final phoneNumber = prefs.getString(_keyPhoneNumber);
    final loginTimestamp = prefs.getInt(_keyLoginTimestamp);

    DateTime? loginDate;
    int? daysRemaining;

    if (loginTimestamp != null) {
      loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      final now = DateTime.now();
      final difference = now.difference(loginDate);
      daysRemaining = _sessionDurationDays - difference.inDays;
    }

    return {
      'isLoggedIn': isLoggedIn,
      'phoneNumber': phoneNumber,
      'loginDate': loginDate?.toString(),
      'daysRemaining': daysRemaining,
    };
  }
}
