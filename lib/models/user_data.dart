import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents the local anonymous profile of the reporter.
class UserProfile {
  final String id;
  final double trustScore;

  UserProfile({required this.id, required this.trustScore});
}

/// Manages local storage and generation of anonymous user credentials.
class UserData {
  static const String _idKey = "anon_id";
  static const String _scoreKey = "trust_score";

  /// Generates a unique 8-character Alphanumeric ID (e.g., ABX7K5F2).
  /// Excludes confusing characters like '0', 'O', and 'I'.
  static String _generateRandomID() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
    final random = Random();
    return List.generate(8, (i) => chars[random.nextInt(chars.length)]).join();
  }

  /// Retrieves the existing profile or initializes a new one if not found.
  static Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();

    String? id = prefs.getString(_idKey);
    double? score = prefs.getDouble(_scoreKey);

    // Initialize profile if it doesn't exist
    if (id == null) {
      id = _generateRandomID();
      score = 4.0; // Standard starting trust score
      await prefs.setString(_idKey, id);
      await prefs.setDouble(_scoreKey, score);
    }

    return UserProfile(
      id: id,
      trustScore: score ?? 4.0,
    );
  }

  /// Useful for testing: Clears local identity to generate a new one.
  static Future<void> resetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idKey);
    await prefs.remove(_scoreKey);
  }
}