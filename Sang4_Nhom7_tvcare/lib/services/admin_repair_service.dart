import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvcare_flutter/models/repair_models.dart';
import 'package:tvcare_flutter/models/user_model.dart';

class AdminRepairService {
  final String _baseUrl = dotenv.env['BASE_URL']!;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Sửa lại hàm để gọi đúng API và xử lý đúng response
  Future<List<UserModel>> getStaffs() async {
    final token = await _getToken();
    // Gọi đúng endpoint /api/admin/users và thêm pageSize để lấy đủ nhân viên
    final response = await http.get(
      Uri.parse('${_baseUrl}admin/users?role=Staff&pageSize=100'), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Backend trả về một object, cần lấy ra list 'items'
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load staff. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<bool> assignStaff(int orderId, String staffId) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${_baseUrl}admin/repair-orders/$orderId/assign-staff?staffId=$staffId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  Future<List<RepairOrder>> getAllOrders() async {
    final token = await _getToken();
    final response = await http.get(
       Uri.parse('${_baseUrl}admin/repair-orders'),
       headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
     if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RepairOrder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<bool> adminUpdateStatus(int orderId, RepairStatus status) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${_baseUrl}admin/repair-orders/$orderId/status?status=${status.index}'),
       headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
}
