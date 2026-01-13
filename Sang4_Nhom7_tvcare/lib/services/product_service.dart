import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../services/auth.dart';
import '../models/tv_models.dart';

class ProductService {
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    String? token = await Auth.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 1. GET ALL PRODUCTS
  Future<List<ProductListItem>> getProducts({int? limit}) async {
    try {
      var url = Config_URL.buildUrl("ProductApi");
      if (limit != null) {
        url += '?limit=$limit';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: false), // Public endpoint
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductListItem.fromJson(json)).toList();
      }
      
      debugPrint("!!! GET PRODUCTS FAILED: ${response.statusCode} - ${response.body}");
      throw Exception("Lấy danh sách thất bại (Mã: ${response.statusCode})");
    } catch (e) {
      debugPrint("!!! ERROR GET PRODUCTS: $e");
      rethrow;
    }
  }

  // 2. GET PRODUCT DETAIL (Gộp cả thông tin chính và Specs)
  Future<ProductDetail> getProductDetail(int id) async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse(Config_URL.buildUrl("ProductApi/$id")), headers: await _getHeaders(requireAuth: false)), // Public
        http.get(Uri.parse(Config_URL.buildUrl("products/$id/specs")), headers: await _getHeaders(requireAuth: false)) // Public
      ]);

      final productRes = results[0];
      final specsRes = results[1];

      if (productRes.statusCode == 200) {
        Map<String, dynamic> productJson = jsonDecode(productRes.body);
        if (specsRes.statusCode == 200) {
          productJson['specs'] = jsonDecode(specsRes.body);
        }
        return ProductDetail.fromJson(productJson);
      }
      
      debugPrint("!!! GET DETAIL FAILED: ${productRes.statusCode}");
      throw Exception("Lấy chi tiết thất bại");
    } catch (e) {
      debugPrint("!!! ERROR GET DETAIL: $e");
      rethrow;
    }
  }

  // 3. CREATE PRODUCT
  Future<bool> createProduct(CreateProductDto dto) async {
    try {
      final response = await http.post(
        Uri.parse(Config_URL.buildUrl("ProductApi")),
        headers: await _getHeaders(),
        body: jsonEncode(dto.toJson()),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. UPDATE PRODUCT
  Future<bool> updateProduct(int id, UpdateProductDto dto) async {
    try {
      final response = await http.put(
        Uri.parse(Config_URL.buildUrl("ProductApi/$id")),
        headers: await _getHeaders(),
        body: jsonEncode(dto.toJson()),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. DELETE PRODUCT
  Future<bool> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(Config_URL.buildUrl("ProductApi/$id")),
        headers: await _getHeaders(),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
