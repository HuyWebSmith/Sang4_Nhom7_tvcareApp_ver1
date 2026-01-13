import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../services/auth.dart';
import '../models/repair_report_models.dart';

class AdminRepairReportService {
  Future<Map<String, String>> _getHeaders() async {
    String? token = await Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<RepairReportItem>> getAdminRepairs({
    String? staffName,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    List<String> params = [];
    if (staffName != null && staffName.isNotEmpty) params.add("staffName=$staffName");
    if (status != null && status != 'All') params.add("status=$status");
    if (fromDate != null) params.add("fromDate=$fromDate");
    if (toDate != null) params.add("toDate=$toDate");

    String query = params.isNotEmpty ? "?" + params.join("&") : "";

    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("api/admin/repairs$query")),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => RepairReportItem.fromJson(e)).toList();
    }
    throw Exception("Không thể tải báo cáo sửa chữa");
  }
}
