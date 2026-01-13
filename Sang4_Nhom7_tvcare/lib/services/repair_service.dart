import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../services/auth.dart';
import '../models/repair_models.dart' as models;

class RepairService {
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth) {
      String? token = await Auth.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // GET /api/RepairServices
  Future<List<models.RepairService>> getAllRepairServices() async {
    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("api/RepairServices")),
      headers: await _getHeaders(requireAuth: false),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => models.RepairService.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load repair services');
    }
  }

  // POST /api/RepairOrders
  Future<bool> createOrder(models.CreateRepairOrderDto dto) async {
    final response = await http.post(
      Uri.parse(Config_URL.buildUrl("api/RepairOrders")),
      headers: await _getHeaders(), 
      body: jsonEncode(dto.toJson()),
    );
    return response.statusCode == 201;
  }

  // GET /api/users/my-repairs
  Future<List<models.RepairOrder>> getMyOrders() async {
    final response = await http.get(
      Uri.parse(Config_URL.buildUrl("api/users/my-repairs")),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => models.RepairOrder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user orders');
    }
  }
}
