import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tvcare_flutter/services/auth.dart';
import 'package:tvcare_flutter/config/config_url.dart';
import 'package:tvcare_flutter/models/tv_models.dart';

class AdminService {
  Future<Map<String, String>> _getHeaders() async {
    String? token = await Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- DANH MỤC (CATEGORY) APIs ---
  Future<List<Brand>> getBrands() async {
    try {
      final url = Config_URL.buildUrl("CategoryApi");
      final response = await http.get(Uri.parse(url), headers: await _getHeaders());
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Brand.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("!!! ERROR GET CATEGORIES: $e");
      return [];
    }
  }

  Future<bool> addBrand(String name) async {
    try {
      final url = Config_URL.buildUrl("CategoryApi");
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({"categoryName": name}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBrand(int id, String name) async {
    try {
      final url = Config_URL.buildUrl("CategoryApi/$id");
      final response = await http.put(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({"id": id, "categoryName": name}),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBrand(int id) async {
    try {
      final url = Config_URL.buildUrl("CategoryApi/$id");
      final response = await http.delete(Uri.parse(url), headers: await _getHeaders());
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Ép kiểu dữ liệu để tránh lỗi List<Brand> không thể gán cho List<Category>
  Future<List<Category>> getCategories() async {
    return await getBrands();
  }

  Future<bool> addCategory(String name) => addBrand(name);
  Future<bool> updateCategory(int id, String name) => updateBrand(id, name);
  Future<bool> deleteCategory(int id) => deleteBrand(id);

  // --- PRODUCT API ---
  Future<bool> addProductDto(CreateProductDto dto) async {
    try {
      final url = Config_URL.buildUrl("ProductApi");
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(dto.toJson()),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
