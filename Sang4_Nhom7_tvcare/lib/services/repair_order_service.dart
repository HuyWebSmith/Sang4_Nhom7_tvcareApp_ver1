import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import 'auth.dart';
import '../models/repair_models.dart';

class RepairOrderService {
  Future<Map<String, String>> _getHeaders() async {
    String? token = await Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ================= USER APIs =================
  Future<bool> createOrder(CreateRepairOrderDto dto) async {
    final response = await http.post(
      Uri.parse(Config_URL.buildUrl("api/user/repairs")),
      headers: await _getHeaders(),
      body: jsonEncode(dto.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<RepairOrder>> getMyOrders() async {
    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("api/user/repairs/my-orders")),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => RepairOrder.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> cancelOrder(int id) async {
    final response = await http.put(
      Uri.parse(Config_URL.buildUrl("api/user/repairs/$id/cancel")),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  // ================= STAFF APIs =================
  Future<List<RepairOrder>> getPendingOrders() async {
    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("api/staff/repairs/pending")),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => RepairOrder.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> acceptOrder(int id) async {
    final response = await http.post(
      Uri.parse(Config_URL.buildUrl("api/staff/repairs/$id/accept")),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateStaffStatus(int id, RepairStatus status) async {
    final response = await http.patch(
      Uri.parse(Config_URL.buildUrl("api/staff/repairs/$id/status")),
      headers: await _getHeaders(),
      body: jsonEncode({"status": status.index}),
    );
    return response.statusCode == 200;
  }

  // ================= ADMIN APIs =================
  Future<List<RepairOrder>> getAllOrders() async {
    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("api/admin/repair-orders")),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => RepairOrder.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> adminUpdateStatus(int id, RepairStatus status) async {
    final response = await http.put(
      Uri.parse(Config_URL.buildUrl("api/admin/repair-orders/$id/status?status=${status.index}")),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> assignStaff(int id, int staffId) async {
    final response = await http.put(
      Uri.parse(Config_URL.buildUrl("api/admin/repair-orders/$id/assign-staff?staffId=$staffId")),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }
}
