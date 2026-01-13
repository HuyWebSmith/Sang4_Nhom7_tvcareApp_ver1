import 'dart:convert';

// --- SPEC METADATA DEFINITION ---
enum SpecValueType { Text, Number, Boolean, Select }

class SpecDefinition {
  final int? id;
  final String name;
  final String? unit;
  final SpecValueType valueType;
  final List<String> options;
  final bool isFilterable;
  final bool isRequired;
  final int sortOrder;

  SpecDefinition({
    this.id,
    required this.name,
    this.unit,
    required this.valueType,
    required this.options,
    this.isFilterable = false,
    this.isRequired = false,
    this.sortOrder = 0,
  });

  factory SpecDefinition.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    var optionsRaw = json['optionsJson'] ?? json['OptionsJson'];
    if (optionsRaw != null && optionsRaw.toString().isNotEmpty) {
      try {
        parsedOptions = List<String>.from(jsonDecode(optionsRaw.toString()));
      } catch (_) {}
    }
    
    return SpecDefinition(
      id: json['id'] ?? json['Id'],
      name: json['name'] ?? json['Name'] ?? '',
      unit: json['unit'] ?? json['Unit'],
      valueType: _parseType(json['valueType'] ?? json['ValueType']),
      options: parsedOptions,
      isFilterable: json['isFilterable'] ?? json['IsFilterable'] ?? false,
      isRequired: json['isRequired'] ?? json['IsRequired'] ?? false,
      sortOrder: json['sortOrder'] ?? json['SortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) "Id": id,
    "Name": name,
    "Unit": unit,
    "ValueType": valueType.index, 
    "OptionsJson": jsonEncode(options),
    "isFilterable": isFilterable,
    "isRequired": isRequired,
    "sortOrder": sortOrder,
  };

  static SpecValueType _parseType(dynamic type) {
    if (type == null) return SpecValueType.Text;
    String t = type.toString().toLowerCase();
    if (t == '1' || t == 'number') return SpecValueType.Number;
    if (t == '2' || t == 'boolean') return SpecValueType.Boolean;
    if (t == '3' || t == 'select') return SpecValueType.Select;
    return SpecValueType.Text;
  }
}

// --- PRODUCT SPEC DETAIL ---
class ProductSpecDetail {
  final int productSpecId;
  final int specId;
  final String name; 
  final String value;
  final String? unit;
  final SpecValueType valueType;

  ProductSpecDetail({
    required this.productSpecId,
    required this.specId,
    required this.name,
    required this.value,
    this.unit,
    required this.valueType,
  });

  factory ProductSpecDetail.fromJson(Map<String, dynamic> json) => ProductSpecDetail(
    productSpecId: json['productSpecId'] ?? json['ProductSpecId'] ?? json['id'] ?? json['Id'] ?? 0,
    specId: json['specId'] ?? json['SpecId'] ?? 0,
    name: json['name'] ?? json['Name'] ?? '',
    value: json['value']?.toString() ?? json['Value']?.toString() ?? '',
    unit: json['unit'] ?? json['Unit'],
    valueType: SpecDefinition._parseType(json['valueType'] ?? json['ValueType']),
  );
}

// --- PRODUCT LIST ITEM ---
class ProductListItem {
  final int productId;
  final String name;
  final String? imageUrl;
  final double price;
  final double minPrice;
  final int stock;

  ProductListItem({required this.productId, required this.name, this.imageUrl, required this.price, required this.minPrice, required this.stock});
  
  // GETTERS FOR BACKWARDS COMPATIBILITY
  int get id => productId;
  String? get image => imageUrl;

  factory ProductListItem.fromJson(Map<String, dynamic> json) => ProductListItem(
    productId: json['productId'] ?? json['id'] ?? json['Id'] ?? 0,
    name: json['name'] ?? json['Name'] ?? '',
    imageUrl: json['imageUrl'] ?? json['image'] ?? json['Image'],
    price: (json['price'] ?? json['Price'] as num?)?.toDouble() ?? 0.0,
    minPrice: (json['minPrice'] ?? json['MinPrice'] as num?)?.toDouble() ?? 0.0,
    stock: json['stock'] ?? json['Stock'] ?? 0,
  );
}

// --- PRODUCT VARIANT ---
class ProductVariant {
  final int id;
  final String variantName;
  final int size;
  final double price;
  final int stock;
  ProductVariant({required this.id, required this.variantName, required this.size, required this.price, required this.stock});
  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: json['id'] ?? json['Id'] ?? 0,
    variantName: json['variantName'] ?? json['VariantName'] ?? '',
    size: (json['size'] ?? json['Size'] as num?)?.toInt() ?? 0,
    price: (json['price'] ?? json['Price'] as num?)?.toDouble() ?? 0.0,
    stock: json['stock'] ?? json['Stock'] ?? 0,
  );
}

// --- PRODUCT DETAIL ---
class ProductDetail {
  final int id;
  final String name;
  final String image;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final List<ProductVariant> variants;
  final List<ProductSpecDetail> specs;

  ProductDetail({
    required this.id,
    required this.name,
    required this.image,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.variants,
    required this.specs,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    var variantsJson = (json['variants'] ?? json['Variants']) as List?;
    List<ProductVariant> variantsList = variantsJson != null 
        ? variantsJson.map((v) => ProductVariant.fromJson(v)).toList() 
        : [];

    var specsJson = (json['specs'] ?? json['Specs']) as List?;
    List<ProductSpecDetail> specsList = specsJson != null 
        ? specsJson.map((s) => ProductSpecDetail.fromJson(s)).toList() 
        : [];

    return ProductDetail(
      id: json['id'] ?? json['Id'] ?? 0,
      name: json['name'] ?? json['Name'] ?? '',
      image: json['image'] ?? json['Image'] ?? '',
      description: json['description'] ?? json['Description'],
      categoryId: json['categoryId'] ?? json['CategoryId'],
      categoryName: json['categoryName'] ?? json['CategoryName'],
      variants: variantsList,
      specs: specsList,
    );
  }

  // Getter để không làm hỏng UI cũ
  String get brandName => categoryName ?? "";
  int get brandId => categoryId ?? 0;
}

typedef Product = ProductDetail;

// --- DTOs ---
class CreateProductDto {
  final String name;
  final String image;
  final String? description;
  final int? categoryId;
  final List<CreateProductVariantDto> variants;

  CreateProductDto({required this.name, required this.image, this.description, this.categoryId, required this.variants});

  Map<String, dynamic> toJson() => {
    "Name": name,
    "Image": image,
    "Description": description,
    "CategoryId": categoryId,
    "Variants": variants.map((v) => v.toJson()).toList(),
  };
}

class CreateProductVariantDto {
  final String variantName;
  final int size;
  final double price;
  final int stock;
  CreateProductVariantDto({required this.variantName, required this.size, required this.price, required this.stock});
  Map<String, dynamic> toJson() => {"VariantName": variantName, "Size": size, "Price": price, "Stock": stock};
}

class UpdateProductDto {
  final String name;
  final String? image;
  final String? description;
  final int? categoryId;
  final List<UpdateProductVariantDto> variants;

  UpdateProductDto({required this.name, this.image, this.description, this.categoryId, required this.variants});

  Map<String, dynamic> toJson() => {
    "Name": name,
    "Image": image,
    "Description": description,
    "CategoryId": categoryId,
    "Variants": variants.map((v) => v.toJson()).toList(),
  };
}

class UpdateProductVariantDto {
  final int? id; 
  final String variantName;
  final int size;
  final double price;
  final int stock;
  UpdateProductVariantDto({this.id, required this.variantName, required this.size, required this.price, required this.stock});
  Map<String, dynamic> toJson() => {
    if (id != null && id != 0) "Id": id,
    "VariantName": variantName, 
    "Size": size, 
    "Price": price, 
    "Stock": stock
  };
}

class CreateProductSpecDto {
  final int specId;
  final String value;
  CreateProductSpecDto({required this.specId, required this.value});
  Map<String, dynamic> toJson() => {"SpecId": specId, "Value": value};
}

class UpdateProductSpecDto {
  final String value;
  UpdateProductSpecDto({required this.value});
  Map<String, dynamic> toJson() => {"Value": value};
}

class Category {
  final int id;
  final String categoryName;
  Category({required this.id, required this.categoryName});
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] ?? json['Id'] ?? 0,
    categoryName: json['categoryName'] ?? json['CategoryName'] ?? '',
  );
  Map<String, dynamic> toJson() => {"Id": id, "CategoryName": categoryName};
  String get brandName => categoryName;
}

typedef Brand = Category;
