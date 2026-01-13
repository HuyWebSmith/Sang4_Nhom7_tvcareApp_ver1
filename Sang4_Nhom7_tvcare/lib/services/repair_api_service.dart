import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvcare_flutter/models/repair_models.dart';
import '../models/repair_location.dart';

class RepairApiService {
  final String _baseUrl = dotenv.env['BASE_URL']!;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<dynamic>> getMyRepairs() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${_baseUrl}staff/repairs/my'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load repairs. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<RepairLocation> getRepairLocation(int id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${_baseUrl}staff/repairs/$id/location'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return RepairLocation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load repair location. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<List<RepairOrder>> getPendingRepairs() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${_baseUrl}staff/repairs/pending'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RepairOrder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending repairs. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<bool> acceptRepair(int orderId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${_baseUrl}staff/repairs/$orderId/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to accept repair. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
