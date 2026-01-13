
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

  //============== START: METHOD ADDED BACK ==============
  Future<CustomerLocation> getRepairLocation(int repairId) async {
    final prefs = await SharedPreferences.getInstance();
    // Note: Ensure 'staff_token' is the correct key you use for saving the staff's token
    final token = prefs.getString('jwt_token') ?? prefs.getString('staff_token');

    if (token == null) {
      throw Exception('Authorization token not found');
    }

    final response = await get(
      'api/staff/repairs/$repairId/location', // Adjusted endpoint
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
  //============== END: METHOD ADDED BACK ==============

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _buildHeaders(headers),
    );
    _logResponse(response);
    return response;
  }

  Future<http.Response> post(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _buildHeaders(headers),
      body: jsonEncode(body),
    );
    _logResponse(response);
    return response;
  }

  Future<http.Response> put(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _buildHeaders(headers),
      body: jsonEncode(body),
    );
    _logResponse(response);
    return response;
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _buildHeaders(headers),
    );
    _logResponse(response);
    return response;
  }

  void _logResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      developer.log(
        'API Error: \n'
        '  - Request: ${response.request?.method} ${response.request?.url}\n'
        '  - Status Code: ${response.statusCode}\n'
        '  - Response Body: ${response.body}',
        name: 'ApiClient',
      );
    }
  }

  Future<Map<String, String>> _buildHeaders(Map<String, String>? customHeaders) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    // Automatically add auth token if not provided
    if (customHeaders == null || !customHeaders.containsKey('Authorization')) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }
}
