import 'package:flutter/material.dart';
import 'services/admin_product_service.dart';
import 'services/admin_service.dart';
import 'models/tv_models.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final AdminProductService _adminProductService = AdminProductService();
  final AdminService _adminService = AdminService();

  // Controllers
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _descController = TextEditingController();
  
  int? _selectedCategoryId;
  List<Category> _categories = [];
  final List<Map<String, dynamic>> _images = []; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final cats = await _adminService.getCategories();
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu: $e");
    }
  }

  void _addImageField() {
    setState(() {
      _images.add({"imageUrl": "", "isMain": _images.isEmpty});
    });
  }

  void _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnackBar("Vui lòng chọn thương hiệu", Colors.orange);
      return;
    }
    
    String finalImage = _imageController.text.trim();
    if (finalImage.isEmpty && _images.isNotEmpty) {
      for (var img in _images) {
        if (img['isMain'] == true) {
          finalImage = img['imageUrl'];
          break;
        }
      }
      if (finalImage.isEmpty) finalImage = _images[0]['imageUrl'];
    }

    if (finalImage.isEmpty) {
      _showSnackBar("Vui lòng nhập URL ảnh hoặc thêm ảnh", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productToPost = CreateProductDto(
        name: _nameController.text.trim(),
        image: finalImage,
        description: _descController.text.trim(),

        categoryId: _selectedCategoryId,
        variants: [], 
      );

      bool success = await _adminProductService.createProduct(productToPost);
      if (success) {
        _showSnackBar("Thêm sản phẩm thành công!", Colors.green);
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar("Thêm thất bại. Hãy kiểm tra log Backend!", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Lỗi dữ liệu: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm sản phẩm mới")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text("Thông tin cơ bản", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                const SizedBox(height: 16),
                _buildField("Tên sản phẩm", _nameController, Icons.tv, validator: (v) => v!.isEmpty ? "Không được để trống" : null),
                const SizedBox(height: 16),
                _buildField("URL Hình ảnh chính", _imageController, Icons.image),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: "Thương hiệu", // Đổi label thành Thương hiệu
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.branding_watermark)
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Chọn thương hiệu")),
                    ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName)))
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) => v == null ? "Bắt buộc chọn thương hiệu" : null,
                ),
                const SizedBox(height: 16),
                _buildField("Mô tả sản phẩm", _descController, Icons.description, maxLines: 3),

                const SizedBox(height: 32),
                const Text("Hình ảnh bổ sung", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                ..._images.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (val) => _images[index]['imageUrl'] = val,
                            decoration: InputDecoration(labelText: "URL Hình ảnh ${index + 1}", border: const UnderlineInputBorder()),
                          ),
                          Row(
                            children: [
                              const Text("Ảnh đại diện:"),
                              Radio<bool>(
                                value: true,
                                groupValue: _images[index]['isMain'],
                                onChanged: (v) {
                                  setState(() {
                                    for (var img in _images) { img['isMain'] = false; }
                                    _images[index]['isMain'] = true;
                                  });
                                },
                              ),
                              const Spacer(),
                              IconButton(onPressed: () => setState(() => _images.removeAt(index)), icon: const Icon(Icons.delete, color: Colors.red))
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(onPressed: _addImageField, icon: const Icon(Icons.add_photo_alternate), label: const Text("Thêm URL hình ảnh")),

                const SizedBox(height: 40),
                SizedBox(
                  height: 55,
                  child: FilledButton(onPressed: _submitProduct, child: const Text("LƯU SẢN PHẨM", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                )
              ],
            ),
          ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
    );
  }
}
