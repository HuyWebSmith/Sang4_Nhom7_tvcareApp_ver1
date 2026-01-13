import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../services/auth.dart';
import '../models/tv_models.dart';

class AdminProductService {
  Future<Map<String, String>> _getHeaders() async {
    String? token = await Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- PRODUCT APIs (api/ProductApi) ---
  Future<Map<String, dynamic>> getAdminProducts({String? search, int page = 1, int pageSize = 10}) async {
    String query = "ProductApi?page=$page&pageSize=$pageSize";
    if (search != null && search.isNotEmpty) query += "&search=$search";
    
    final response = await http.get(Uri.parse(Config_URL.buildUrl(query)), headers: await _getHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return {"items": data.map((e) => ProductListItem.fromJson(e)).toList(), "totalCount": data.length};
      }
      return {
        "items": (data['items'] as List).map((e) => ProductListItem.fromJson(e)).toList(),
        "totalCount": data['totalCount'] ?? 0
      };
    }
    throw Exception("Lỗi tải sản phẩm");
  }

  Future<ProductDetail> getProductDetail(int id) async {
    final response = await http.get(Uri.parse(Config_URL.buildUrl("ProductApi/$id")), headers: await _getHeaders());
    if (response.statusCode == 200) return ProductDetail.fromJson(jsonDecode(response.body));
    throw Exception("Lỗi tải chi tiết");
  }

  Future<bool> createProduct(CreateProductDto dto) async {
    final response = await http.post(Uri.parse(Config_URL.buildUrl("ProductApi")), headers: await _getHeaders(), body: jsonEncode(dto.toJson()));
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> updateProductInfo(int id, UpdateProductDto dto) async {
    final response = await http.put(Uri.parse(Config_URL.buildUrl("ProductApi/$id")), headers: await _getHeaders(), body: jsonEncode(dto.toJson()));
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse(Config_URL.buildUrl("ProductApi/$id")), 
      headers: await _getHeaders()
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // --- SPEC METADATA APIs (api/admin/specs) ---
  Future<List<SpecDefinition>> getSpecs() async {
    final response = await http.get(Uri.parse(Config_URL.buildUrl("admin/specs")), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => SpecDefinition.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> createSpec(SpecDefinition spec) async {
    await http.post(Uri.parse(Config_URL.buildUrl("admin/specs")), headers: await _getHeaders(), body: jsonEncode(spec.toJson()));
  }

  Future<void> updateSpec(int id, SpecDefinition spec) async {
    await http.put(Uri.parse(Config_URL.buildUrl("admin/specs/$id")), headers: await _getHeaders(), body: jsonEncode(spec.toJson()));
  }

  Future<void> deleteSpec(int id) async {
    await http.delete(Uri.parse(Config_URL.buildUrl("admin/specs/$id")), headers: await _getHeaders());
  }

  // --- PRODUCT SPEC DETAIL (api/products) ---
  Future<List<ProductSpecDetail>> getProductSpecs(int productId) async {
    final response = await http.get(Uri.parse(Config_URL.buildUrl("products/$productId/specs")), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => ProductSpecDetail.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> addSpecsToProduct(int productId, List<CreateProductSpecDto> specs) async {
    await http.post(Uri.parse(Config_URL.buildUrl("products/$productId/specs")), headers: await _getHeaders(), body: jsonEncode(specs.map((e) => e.toJson()).toList()));
  }

  Future<void> updateProductSpec(int productSpecId, String value) async {
    await http.put(Uri.parse(Config_URL.buildUrl("products/specs/$productSpecId")), headers: await _getHeaders(), body: jsonEncode({"Value": value}));
  }

  Future<void> deleteProductSpec(int productSpecId) async {
    await http.delete(Uri.parse(Config_URL.buildUrl("products/specs/$productSpecId")), headers: await _getHeaders());
  }

  Future<void> cloneSpecs(int fromProductId, int toProductId) async {
    await http.post(Uri.parse(Config_URL.buildUrl("products/$fromProductId/clone-specs/$toProductId")), headers: await _getHeaders());
  }

  // --- CATEGORY (api/CategoryApi) ---
  Future<List<Brand>> getBrands() async {
    final response = await http.get(Uri.parse(Config_URL.buildUrl("CategoryApi")), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Brand.fromJson(e)).toList();
    }
    return [];
  }

  // --- STATS ---
  Future<Map<String, dynamic>> getDashboardStats() async {
    final products = await getAdminProducts(pageSize: 1000);
    List<ProductListItem> items = products['items'];
    int totalStock = items.fold(0, (sum, item) => (sum + item.stock).toInt());
    int outOfStock = items.where((p) => p.stock == 0).length;
    return {
      "totalProducts": items.length,
      "totalStock": totalStock,
      "outOfStock": outOfStock
    };
  }
}
