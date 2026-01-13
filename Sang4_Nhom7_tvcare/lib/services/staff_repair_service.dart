import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../services/auth.dart';
import '../models/repair_models.dart';

class StaffRepairService {
  Future<Map<String, String>> _getHeaders() async {
    String? token = await Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET: /api/staff/repairs/pending
  Future<List<RepairOrder>> getPendingRepairs() async {
    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("api/staff/repairs/pending")),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => RepairOrder.fromJson(e)).toList();
    }
    throw Exception("Không thể tải đơn hàng chờ");
  }

  // GET: /api/staff/repairs/my
  Future<List<RepairOrder>> getMyRepairs() async {
    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("api/staff/repairs/my")),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => RepairOrder.fromJson(e)).toList();
    }
    throw Exception("Không thể tải đơn hàng của tôi");
  }

  // POST: /api/staff/repairs/{id}/accept
  Future<bool> acceptRepair(int id) async {
    final response = await http.post(
      Uri.parse(Config_URL.buildUrl("api/staff/repairs/$id/accept")),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  // PATCH: /api/staff/repairs/{id}/status
  Future<bool> updateStatus(int id, RepairStatus status) async {
    final response = await http.patch(
      Uri.parse(Config_URL.buildUrl("api/staff/repairs/$id/status")),
      headers: await _getHeaders(),
      body: jsonEncode({"Status": status.index}), // UpdateRepairStatusDto
    );
    return response.statusCode == 200;
  }
}
