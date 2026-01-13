import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../services/auth.dart';
import '../models/staff_models.dart';

class AdminStaffService {
  Future<Map<String, String>> _getHeaders() async {
    String? token = await Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getStaffList({int page = 1, int pageSize = 10}) async {
    final String url = Config_URL.buildUrl("api/admin/users?role=Staff&page=$page&pageSize=$pageSize");
    
    print(">>> REQUEST: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print(">>> STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "items": (data['items'] as List?)?.map((e) => StaffMember.fromJson(e)).toList() ?? [],
          "totalCount": data['totalCount'] ?? 0
        };
      } else {
        throw Exception("Lỗi ${response.statusCode}: Không tìm thấy dịch vụ Quản lý nhân viên");
      }
    } catch (e) {
      print(">>> EXCEPTION: $e");
      rethrow;
    }
  }

  // Sửa từ int sang String để khớp với IdentityUser Id
  Future<bool> toggleLockAccount(String userId, bool lock) async {
    final endpoint = lock ? "lock" : "unlock";
    final url = Config_URL.buildUrl("api/admin/users/$userId/$endpoint");
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
