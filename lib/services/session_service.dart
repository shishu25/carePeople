import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // ── Patient session keys ───────────────────────────────────────────────────
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyPhoneNumber = 'phoneNumber';
  static const String _keyLoginTimestamp = 'loginTimestamp';

  // ── Doctor session keys ───────────────────────────────────────────────────
  static const String _keyDoctorIsLoggedIn = 'doctorIsLoggedIn';
  static const String _keyDoctorId = 'doctorId';
  static const String _keyDoctorData = 'doctorData';
  static const String _keyDoctorLoginTimestamp = 'doctorLoginTimestamp';

  // ── Shared constant ───────────────────────────────────────────────────────
  static const int _sessionDurationDays = 2;

  // ══════════════════════════════════════════════════════════════════════════
  //  PATIENT SESSION
  // ══════════════════════════════════════════════════════════════════════════

  /// Save patient login session
  static Future<void> saveSession(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyPhoneNumber, phoneNumber);
    await prefs.setInt(_keyLoginTimestamp, now);
  }

  /// Check if there's an active patient session (not expired)
  static Future<bool> isSessionActive() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (!isLoggedIn) return false;

    final loginTimestamp = prefs.getInt(_keyLoginTimestamp);
    if (loginTimestamp == null) return false;

    final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
    final difference = DateTime.now().difference(loginDate);

    if (difference.inDays >= _sessionDurationDays) {
      await clearSession();
      return false;
    }

    return true;
  }

  /// Get the saved phone number from patient session
  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoneNumber);
  }

  /// Clear the patient session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyPhoneNumber);
    await prefs.remove(_keyLoginTimestamp);
  }

  /// Get patient session info for debugging
  static Future<Map<String, dynamic>> getSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final phoneNumber = prefs.getString(_keyPhoneNumber);
    final loginTimestamp = prefs.getInt(_keyLoginTimestamp);

    DateTime? loginDate;
    int? daysRemaining;

    if (loginTimestamp != null) {
      loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      final difference = DateTime.now().difference(loginDate);
      daysRemaining = _sessionDurationDays - difference.inDays;
    }

    return {
      'isLoggedIn': isLoggedIn,
      'phoneNumber': phoneNumber,
      'loginDate': loginDate?.toString(),
      'daysRemaining': daysRemaining,
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DOCTOR SESSION
  // ══════════════════════════════════════════════════════════════════════════

  /// Save doctor login session (stores the full doctor data map as JSON)
  static Future<void> saveDoctorSession(Map<String, dynamic> doctorData) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setBool(_keyDoctorIsLoggedIn, true);
    await prefs.setString(_keyDoctorId, doctorData['id']?.toString() ?? '');
    await prefs.setString(_keyDoctorData, json.encode(doctorData));
    await prefs.setInt(_keyDoctorLoginTimestamp, now);
  }

  /// Check if there's an active doctor session (not expired after 2 days)
  static Future<bool> isDoctorSessionActive() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyDoctorIsLoggedIn) ?? false;

    if (!isLoggedIn) return false;

    final loginTimestamp = prefs.getInt(_keyDoctorLoginTimestamp);
    if (loginTimestamp == null) return false;

    final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
    final difference = DateTime.now().difference(loginDate);

    if (difference.inDays >= _sessionDurationDays) {
      await clearDoctorSession();
      return false;
    }

    return true;
  }

  /// Get the stored doctor data map from the session
  static Future<Map<String, dynamic>?> getDoctorData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDoctorData);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Clear the doctor session (logout)
  static Future<void> clearDoctorSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDoctorIsLoggedIn);
    await prefs.remove(_keyDoctorId);
    await prefs.remove(_keyDoctorData);
    await prefs.remove(_keyDoctorLoginTimestamp);
  }
}
