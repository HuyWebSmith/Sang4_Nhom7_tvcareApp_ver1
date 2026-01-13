
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
      // Lấy danh sách sản phẩm là public, không cần xác thực
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: false),
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
      final productUrl = Config_URL.buildUrl("ProductApi/$id");
      final specsUrl = Config_URL.buildUrl("products/$id/specs");

      // API lấy chi tiết sản phẩm YÊU CẦU xác thực
      final results = await Future.wait([
        http.get(Uri.parse(productUrl), headers: await _getHeaders(requireAuth: true)),
        http.get(Uri.parse(specsUrl), headers: await _getHeaders(requireAuth: true))
      ]);

      final productRes = results[0];
      final specsRes = results[1];

      if (productRes.statusCode != 200) {
        debugPrint("!!! GET DETAIL FAILED (Product): ${productRes.statusCode} - ${productRes.body}");
        throw Exception("Lấy chi tiết sản phẩm thất bại (Mã: ${productRes.statusCode})");
      }

      Map<String, dynamic> productJson = jsonDecode(productRes.body);
      
      if (specsRes.statusCode == 200) {
        productJson['specs'] = jsonDecode(specsRes.body);
      } else {
        debugPrint("!!! WARN: Could not fetch specs (Mã: ${specsRes.statusCode}). Proceeding without specs.");
      }
      
      return ProductDetail.fromJson(productJson);

    } catch (e) {
      debugPrint("!!! ERROR GET DETAIL: $e");
      throw Exception("Lấy chi tiết thất bại. Vui lòng kiểm tra lại đường truyền hoặc cấu hình API.");
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
