
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvcare_flutter/services/api_client.dart';
import 'package:tvcare_flutter/services/auth_service.dart';

class Auth {
  static final AuthService _authService = AuthService();
  static final ApiClient _apiClient = ApiClient();

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<String?> getRole() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ?? decodedToken['role'];
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;
    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    return await _authService.login(username, password);
  }

  static Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    required String displayName,
    required String idToken,
  }) async {
    return await _authService.googleLogin(
      email: email,
      displayName: displayName,
      idToken: idToken,
    );
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? initials,
    String role = "User",
  }) async {
    final body = {
      "username": username,
      "email": email,
      "password": password,
      "initials": initials,
      "role": role,
    };

    try {
      final response = await _apiClient.post('Authenticate/register', body: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "message": "Đăng ký thành công"};
      }
      return {'success': false, 'message': 'Đăng ký thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối'};
    }
  }
}
