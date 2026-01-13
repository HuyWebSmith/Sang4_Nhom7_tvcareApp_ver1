import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/tv_models.dart';
import 'services/product_service.dart';
import 'services/admin_service.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductDetail? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final AdminService _adminService = AdminService();
  
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _descController = TextEditingController();
  
  int? _selectedCategoryId;
  List<Category> _categories = [];
  final List<VariantInput> _variantInputs = [];

  @override
  void initState() {
    super.initState();
    _fetchData();

    if (widget.product != null) {
      _loadProductData();
    } else {
      _loadDraft();
    }
    
    _nameController.addListener(_saveDraft);
    _imageController.addListener(_saveDraft);
    _descController.addListener(_saveDraft);
  }

  void _loadProductData() {
    _nameController.text = widget.product!.name;
    _imageController.text = widget.product!.image;
    _descController.text = widget.product!.description ?? "";
    _selectedCategoryId = widget.product!.categoryId;
    
    for (var v in widget.product!.variants) {
      _variantInputs.add(VariantInput(
        id: v.id,
        size: TextEditingController(text: v.size.toString()),
        variantName: TextEditingController(text: v.variantName),
        price: TextEditingController(text: v.price.toString()),
        stock: TextEditingController(text: v.stock.toString()),
      )..addListener(_saveDraft));
    }
  }

  Future<void> _saveDraft() async {
    if (widget.product != null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': _nameController.text,
      'image': _imageController.text,
      'description': _descController.text,
      'categoryId': _selectedCategoryId,
      'variants': _variantInputs.map((v) => {
        'variantName': v.variantName.text,
        'size': v.size.text,
        'price': v.price.text,
        'stock': v.stock.text,
      }).toList(),
    };
    await prefs.setString('product_form_draft', jsonEncode(data));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('product_form_draft');
    if (draft != null) {
      final data = jsonDecode(draft);
      if (mounted) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _imageController.text = data['image'] ?? '';
          _descController.text = data['description'] ?? '';
          _selectedCategoryId = data['categoryId'];
          
          final List? variantsData = data['variants'];
          if (variantsData != null && variantsData.isNotEmpty) {
            _variantInputs.clear();
            for (var v in variantsData) {
              _variantInputs.add(VariantInput(
                variantName: TextEditingController(text: v['variantName']),
                size: TextEditingController(text: v['size']),
                price: TextEditingController(text: v['price']),
                stock: TextEditingController(text: v['stock']),
              )..addListener(_saveDraft));
            }
          } else if (_variantInputs.isEmpty) {
            _addVariantInput();
          }
        });
      }
    } else if (_variantInputs.isEmpty) {
      _addVariantInput();
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('product_form_draft');
  }

  void _addVariantInput() {
    setState(() {
      _variantInputs.add(VariantInput(
        size: TextEditingController(),
        variantName: TextEditingController(),
        price: TextEditingController(),
        stock: TextEditingController(),
      )..addListener(_saveDraft));
    });
  }

  void _removeVariantInput(int index) {
    if (_variantInputs.length > 1) {
      setState(() => _variantInputs.removeAt(index));
      _saveDraft();
    }
  }

  Future<void> _fetchData() async {
    try {
      final cats = await _adminService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          // Tự động chọn đúng category nếu đang sửa
          if (widget.product != null) {
            int? catId = widget.product!.categoryId;
            if (_categories.any((c) => c.id == catId)) {
              _selectedCategoryId = catId;
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    int parseSafeInt(String text) {
      String clean = text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(clean) ?? 0;
    }

    double parseSafeDouble(String text) {
      String clean = text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.product == null) {
        final dto = CreateProductDto(
          name: _nameController.text.trim(),
          image: _imageController.text.trim(),
          description: _descController.text.trim(),
          categoryId: _selectedCategoryId,
          variants: _variantInputs.map((v) => CreateProductVariantDto(
            variantName: v.variantName.text.trim(),
            size: parseSafeInt(v.size.text),
            price: parseSafeDouble(v.price.text),
            stock: parseSafeInt(v.stock.text),
          )).toList(),
        );

        bool success = await _productService.createProduct(dto);
        if (success && mounted) {
          await _clearDraft();
          Navigator.pop(context, true);
        }
      } else {
        final dto = UpdateProductDto(
          name: _nameController.text.trim(),
          image: _imageController.text.trim(),
          description: _descController.text.trim(),
          categoryId: _selectedCategoryId,
          variants: _variantInputs.map((v) => UpdateProductVariantDto(
            id: v.id ?? 0, // Gửi ID để tránh lỗi 400
            variantName: v.variantName.text.trim(),
            size: parseSafeInt(v.size.text),
            price: parseSafeDouble(v.price.text),
            stock: parseSafeInt(v.stock.text),
          )).toList(),
        );

        bool success = await _productService.updateProduct(widget.product!.id, dto);
        if (success && mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("!!! SAVE ERROR: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi lưu: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product == null ? "Thêm Tivi mới" : "Chỉnh sửa sản phẩm"),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _sectionTitle("Thông tin chung"),
                _textField("Tên Tivi", _nameController),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: "Thương hiệu", border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategoryId = val);
                    _saveDraft();
                  },
                ),
                const SizedBox(height: 16),
                _textField("URL Hình ảnh", _imageController),
                const SizedBox(height: 16),
                _textField("Mô tả", _descController, maxLines: 3),
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle("Danh sách biến thể (Size)"),
                    TextButton.icon(onPressed: _addVariantInput, icon: const Icon(Icons.add), label: const Text("Thêm size")),
                  ],
                ),
                
                ..._variantInputs.asMap().entries.map((entry) {
                  int idx = entry.key;
                  VariantInput v = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: const Color(0xFFF8FAFC),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _textField("Tên biến thể", v.variantName)),
                              const SizedBox(width: 12),
                              Expanded(child: _textField("Size (inch)", v.size, isNumber: true)),
                              IconButton(onPressed: () => _removeVariantInput(idx), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _textField("Giá bán", v.price, isNumber: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _textField("Kho", v.stock, isNumber: true)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 40),
                SizedBox(
                  height: 60,
                  child: FilledButton(
                    onPressed: _handleSave,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text("LƯU SẢN PHẨM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
    );
  }

  Widget _textField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
      validator: (val) => val == null || val.isEmpty ? "Bắt buộc" : null,
    );
  }
}

class VariantInput {
  final int? id;
  final TextEditingController size;
  final TextEditingController variantName;
  final TextEditingController price;
  final TextEditingController stock;

  VariantInput({this.id, required this.size, required this.variantName, required this.price, required this.stock});

  void addListener(VoidCallback listener) {
    size.addListener(listener);
    variantName.addListener(listener);
    price.addListener(listener);
    stock.addListener(listener);
  }
}
