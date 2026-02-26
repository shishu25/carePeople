import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service to manage user data storage in a local JSON file
class UserStorageService {
  static const String _fileName = 'users.json';

  /// Get the path to the JSON file
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get the JSON file
  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  /// Read all users from JSON file
  static Future<Map<String, dynamic>> _readUsers() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error reading users: $e');
      return {};
    }
  }

  /// Write users to JSON file
  static Future<void> _writeUsers(Map<String, dynamic> users) async {
    try {
      final file = await _localFile;
      await file.writeAsString(jsonEncode(users));
    } catch (e) {
      print('Error writing users: $e');
    }
  }

  /// Check if user exists by phone number
  static Future<bool> userExists(String phoneNumber) async {
    final users = await _readUsers();
    return users.containsKey(phoneNumber);
  }

  /// Get user data by phone number
  static Future<Map<String, dynamic>?> getUserData(String phoneNumber) async {
    final users = await _readUsers();
    if (users.containsKey(phoneNumber)) {
      return users[phoneNumber] as Map<String, dynamic>;
    }
    return null;
  }

  /// Save new user data
  static Future<bool> saveUser({
    required String phoneNumber,
    required String name,
    required String dateOfBirth,
    required String address,
    required String gender,
  }) async {
    try {
      final users = await _readUsers();
      
      users[phoneNumber] = {
        'name': name,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'gender': gender,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _writeUsers(users);
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  /// Update existing user data
  static Future<bool> updateUser({
    required String phoneNumber,
    required String name,
    required String dateOfBirth,
    required String address,
    required String gender,
  }) async {
    try {
      final users = await _readUsers();
      
      if (!users.containsKey(phoneNumber)) {
        return false;
      }

      users[phoneNumber] = {
        'name': name,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'gender': gender,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _writeUsers(users);
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Delete user data
  static Future<bool> deleteUser(String phoneNumber) async {
    try {
      final users = await _readUsers();
      users.remove(phoneNumber);
      await _writeUsers(users);
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// Get all users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final users = await _readUsers();
    return users.values.map((user) => user as Map<String, dynamic>).toList();
  }
}
