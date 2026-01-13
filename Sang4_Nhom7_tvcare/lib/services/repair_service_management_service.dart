import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/repair_models.dart';

class RepairServiceManagementService {
  final String _baseUrl = dotenv.env['BASE_URL']!;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<RepairService>> getAllServices() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${_baseUrl}admin/repair-services'), // Fixed URL joining
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RepairService.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load services. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<bool> createService(RepairService service) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${_baseUrl}admin/repair-services'), // Fixed URL joining
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(service.toJson()),
    );
    return response.statusCode == 201;
  }

  Future<bool> toggleService(int serviceId) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('${_baseUrl}admin/repair-services/$serviceId/toggle-active'), // Fixed URL joining
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
}
