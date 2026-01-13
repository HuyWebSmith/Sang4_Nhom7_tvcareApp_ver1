import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../services/auth.dart';
import '../models/repair_models.dart';

class RepairBookingService {
  Future<Map<String, String>> _getHeaders() async {
    String? token = await Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Lấy danh sách dịch vụ đang hoạt động từ Admin Controller (để User chọn)
  Future<List<RepairService>> getActiveServices() async {
    final url = Config_URL.buildUrl("api/admin/repair-services");
    try {
      final response = await http.get(Uri.parse(url), headers: await _getHeaders());
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data
            .map((e) => RepairService.fromJson(e))
            .where((s) => s.isActive)
            .toList();
      }
    } catch (e) {
      print("Error: $e");
    }
    return [];
  }

  // GỬI ĐƠN ĐẶT LỊCH - Khớp với api/user/repairs
  Future<bool> createRepairBooking(CreateRepairOrderDto dto) async {
    // Sửa lại đường dẫn thành api/user/repairs
    final url = Config_URL.buildUrl("api/user/repairs");
    
    print(">>> BOOKING REQUEST: $url");
    print(">>> BODY: ${jsonEncode(dto.toJson())}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(dto.toJson()),
      );

      print("<<< STATUS: ${response.statusCode}");
      print("<<< BODY: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("<<< EXCEPTION: $e");
      return false;
    }
  }
}
