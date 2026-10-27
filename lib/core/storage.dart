import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUsername = 'username';
  static const String _keyRole = 'user_role';
  static const String _keyVehicle = 'last_vehicle_number';

  static Future<void> saveUser(UserSession user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, user.token);
    await prefs.setString(_keyUsername, user.name);
    await prefs.setString(_keyRole, user.role);
  }

  static Future<UserSession?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.isEmpty) return null;

    final name = prefs.getString(_keyUsername) ?? 'Driver';
    final role = prefs.getString(_keyRole) ?? 'seeker';
    return UserSession(token: token, name: name, role: role);
  }

  static Future<String?> getToken() async {
    final user = await getUser();
    return user?.token;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
  }

  static Future<void> saveLastVehicle(String vehicleNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVehicle, vehicleNumber.trim().toUpperCase());
  }

  static Future<String> getLastVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVehicle) ?? 'TN 09 AB 1234';
  }
}
