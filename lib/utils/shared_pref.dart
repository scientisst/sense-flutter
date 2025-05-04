import "package:shared_preferences/shared_preferences.dart";
import "dart:convert";

class SharedPref {
  static Future<dynamic> read(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      final String? string = prefs.getString(key);
      if (string != null) return json.decode(string);
    }
    return null;
  }

  static Future<void> write(String key, value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(value));
  }

  static Future<void> remove(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
