import 'package:flutter/material.dart';
import 'services/admin_service.dart';
import 'models/tv_models.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final AdminService _adminService = AdminService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final brands = await _adminService.getBrands();
      if (!mounted) return;
      setState(() {
        _categories = brands.map((b) => Category(id: b.id, categoryName: b.brandName)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddDialog([Category? category]) {
    final controller = TextEditingController(text: category?.categoryName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? "Thêm Thương hiệu" : "Sửa Thương hiệu"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Tên thương hiệu")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")),
          FilledButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              bool success;
              if (category == null) {
                success = await _adminService.addBrand(controller.text.trim());
              } else {
                success = await _adminService.updateBrand(category.id, controller.text.trim());
              }
              if (success) {
                _loadCategories();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("LƯU"),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa thương hiệu này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("HỦY")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("XÓA")),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _adminService.deleteBrand(id);
      if (success) _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý Thương hiệu")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return ListTile(
                title: Text(cat.categoryName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _showAddDialog(cat)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(cat.id)),
                  ],
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddDialog(), child: const Icon(Icons.add)),
    );
  }
}
