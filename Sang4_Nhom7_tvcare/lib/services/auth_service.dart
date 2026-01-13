import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvcare_flutter/config/config_url.dart'; // Corrected import path

class AuthService {
  // Hàm xây dựng URL thông minh, tránh trùng lặp "api/"
  String _buildUrl(String endpoint) {
    String base = Config_URL.baseUrl.trim();
    
    // 1. Đảm bảo base không kết thúc bằng dấu "/"
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    
    // 2. Nếu endpoint bắt đầu bằng "/" thì xóa đi
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    // 3. QUAN TRỌNG: Nếu base đã chứa "/api" và endpoint cũng bắt đầu bằng "api/"
    // thì ta xóa "api/" ở endpoint để tránh bị thành "/api/api/"
    if (base.endsWith('/api') && endpoint.startsWith('api/')) {
      endpoint = endpoint.substring(4); 
    }

    return "$base/$endpoint";
  }

  // ĐĂNG NHẬP GOOGLE
  Future<Map<String, dynamic>> googleLogin({
    required String email,
    required String displayName,
    required String idToken,
  }) async {
    // Gọi đến api/Authenticate/google-login
    final fullUrl = _buildUrl("api/Authenticate/google-login");
    print(">>> GỌI GOOGLE LOGIN: $fullUrl");
    
    try {
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "displayName": displayName,
          "idToken": idToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? token = data['token'];
        if (token != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          return {"success": true};
        }
      }
      return {"success": false, "message": "Lỗi Server (${response.statusCode}): ${response.body}"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối Backend: $e"};
    }
  }

  // Đăng nhập thường
  Future<Map<String, dynamic>> login(String username, String password) async {
    final fullUrl = _buildUrl("api/Authenticate/login");
    try {
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? token = data['token'];
        if (token != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          return {"success": true};
        }
      }
      return {"success": false, "message": "Sai tài khoản hoặc mật khẩu."};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối."};
    }
  }
}
