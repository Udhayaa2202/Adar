import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class UserData {
  static const String _idKey = "anon_id";
  static const String _scoreKey = "trust_score";

  // Generate a random ID like your mockup: ABX7K5F2
  static String _generateRandomID() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
    return List.generate(8, (i) => chars[Random().nextInt(chars.length)]).join();
  }

  static Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();

    String? id = prefs.getString(_idKey);
    double? score = prefs.getDouble(_scoreKey);

    if (id == null) {
      id = _generateRandomID();
      score = 4.0; // Starting score for new reporters
      await prefs.setString(_idKey, id);
      await prefs.setDouble(_scoreKey, score);
    }

    return {
      "id": id,
      "score": score?.toStringAsFixed(1) ?? "4.0",
    };
  }
}