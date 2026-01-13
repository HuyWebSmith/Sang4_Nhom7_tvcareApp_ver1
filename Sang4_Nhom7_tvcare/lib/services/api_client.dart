
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvcare_flutter/config/config_url.dart';
import 'package:tvcare_flutter/models/customer_location.dart';

class ApiClient {
  final String? _customBaseUrl;

  ApiClient({String? baseUrl}) : _customBaseUrl = baseUrl;

  String get _baseUrl => _customBaseUrl ?? Config_URL.baseUrl;

  Future<CustomerLocation> getRepairLocation(int repairId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('staff_token');

    if (token == null) {
      throw Exception('Authorization token not found');
    }

    final response = await get(
      '/api/staff/repairs/$repairId/location',
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return CustomerLocation.fromJson(jsonDecode(response.body));
    } else {
      developer.log('Failed to load customer location: ${response.body}', name: 'ApiClient');
      throw Exception('Failed to load customer location');
    }
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    return await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _buildHeaders(headers),
    );
  }

  Future<http.Response> post(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    return await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _buildHeaders(headers),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    return await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _buildHeaders(headers),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
    return await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _buildHeaders(headers),
    );
  }

  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }
}
