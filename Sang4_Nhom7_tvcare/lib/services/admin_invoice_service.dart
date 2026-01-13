import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';

class AdminInvoiceService {
  final String _baseUrl = dotenv.env['BASE_URL']!;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Get all invoices (assuming an endpoint exists)
  Future<List<Invoice>> getInvoices() async {
    final token = await _getToken();
    // Assuming the endpoint is /api/admin/invoices
    final response = await http.get(
      Uri.parse('${_baseUrl}admin/invoices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Invoice.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load invoices. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Approve an invoice and trigger the email
  Future<bool> approveInvoice(int invoiceId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${_baseUrl}admin/invoices/$invoiceId/approve'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final responseBody = await response.body;
      throw Exception('Failed to approve invoice. Status: ${response.statusCode}, Body: $responseBody');
    }
  }
}
