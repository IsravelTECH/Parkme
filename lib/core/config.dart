import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String defaultCloudUrl = 'https://parkme-backend.onrender.com';
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:8000';
  static const String defaultLocalhostUrl = 'http://127.0.0.1:8000';

  static String _customApiUrl = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customApiUrl = prefs.getString('custom_api_url') ?? '';
  }

  static String get apiBaseUrl {
    if (_customApiUrl.isNotEmpty) {
      return _customApiUrl.replaceAll(RegExp(r'/+$'), '');
    }

    // Default to official production Render cloud backend across all platforms
    return defaultCloudUrl.replaceAll(RegExp(r'/+$'), '');
  }

  static Future<void> setCustomApiUrl(String url) async {
    _customApiUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    if (_customApiUrl.isEmpty) {
      await prefs.remove('custom_api_url');
    } else {
      await prefs.setString('custom_api_url', _customApiUrl);
    }
  }

  static String get customApiUrl => _customApiUrl;
}
