import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_ocr_result.dart';

class InvoiceService {
  final String _baseUrl = dotenv.env['BASE_URL']!;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<bool> uploadInvoice({
    required int repairOrderId,
    required File imageFile,
    required InvoiceOcrResult ocrResult,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${_baseUrl}staff/invoices/upload'), // Endpoint from your backend
    );

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add fields
    request.fields['repairOrderId'] = repairOrderId.toString();
    // Add the OCR result as a JSON string
    request.fields['invoiceJson'] = jsonEncode(ocrResult.toJson());

    // Add the image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'invoiceImage', // Field name must match backend
        imageFile.path,
      ),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to upload invoice. Status: ${response.statusCode}, Body: $responseBody');
    }
  }
}
