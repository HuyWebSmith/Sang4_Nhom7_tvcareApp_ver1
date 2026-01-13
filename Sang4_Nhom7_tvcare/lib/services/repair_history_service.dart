import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../services/auth.dart';
import '../models/repair_models.dart';

class RepairHistoryService {
  Future<Map<String, String>> _getHeaders() async {
    String? token = await Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<RepairOrder>> getRepairHistory({String? status, String? fromDate, String? toDate}) async {
    String query = "";
    List<String> params = [];
    if (status != null && status != 'All') params.add("status=$status");
    if (fromDate != null) params.add("fromDate=$fromDate");
    if (toDate != null) params.add("toDate=$toDate");
    
    if (params.isNotEmpty) {
      query = "?" + params.join("&");
    }

    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("api/repairs/history$query")),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => RepairOrder.fromJson(e)).toList();
    }
    throw Exception("Không thể tải lịch sử sửa chữa");
  }
}
