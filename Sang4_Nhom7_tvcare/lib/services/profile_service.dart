import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../services/auth.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  Future<Map<String, String>> _getHeaders() async {
    String? token = await Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<UserProfile> getProfile() async {
    // Corrected endpoint to match AuthenticateController
    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("Authenticate/profile")),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load profile (Status: ${response.statusCode})');
  }

  Future<bool> verifyPhone(String firebaseUid) async {
    // Corrected endpoint to match AuthenticateController
    final response = await http.post(
      Uri.parse(Config_URL.buildUrl("Authenticate/verify-phone")),
      headers: await _getHeaders(),
      body: jsonEncode({'firebaseUid': firebaseUid}),
    );
    return response.statusCode == 200;
  }
}
