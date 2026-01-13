
import 'package:flutter/material.dart';
import 'services/product_service.dart';
import 'models/tv_models.dart';
import 'tv_detail_page.dart';
import 'screens/admin/product_form_dialog.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _service = ProductService();
  List<ProductListItem> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.getProducts();
      setState(() => _products = data);
    } catch (e) {
      setState(() => _errorMessage = "Không thể kết nối máy chủ");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEdit(int productId) async {
    final result = await showDialog(
      context: context,
      builder: (_) => ProductFormDialog(productId: productId), // Truyền ID để sửa
    );
    if (result == true) {
      _fetchProducts(); // Tải lại danh sách nếu có thay đổi
    }
  }

  Future<void> _handleDelete(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _service.deleteProduct(productId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sản phẩm.'), backgroundColor: Colors.green));
        _fetchProducts();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa sản phẩm thất bại.'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleAddNew() async {
     final result = await showDialog(
      context: context,
      builder: (_) => const ProductFormDialog(), // Không có ID = thêm mới
    );
    if (result == true) {
      _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Quản lý Tivi", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _fetchProducts, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddNew,
        backgroundColor: const Color(0xFF0D47A1),
        tooltip: 'Thêm sản phẩm mới',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _products.isEmpty
                  ? const Center(child: Text("Hệ thống chưa có sản phẩm nào"))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return _ProductCard(
                          product: product,
                          onEdit: () => _handleEdit(product.id),
                          onDelete: () => _handleDelete(product.id),
                        );
                      },
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
          TextButton(onPressed: _fetchProducts, child: const Text("Thử lại")),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductListItem product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bool outOfStock = product.stock == 0;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // --- Image ---
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TVDetailPage(productId: product.id))),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: product.image != null && product.image!.isNotEmpty
                      ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(product.image!, fit: BoxFit.cover))
                      : const Icon(Icons.tv, size: 50, color: Colors.black12),
                  ),
                ),
                // --- Edit/Delete Buttons ---
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomLeft: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.white, size: 18), onPressed: onEdit, tooltip: 'Chỉnh sửa'),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: onDelete, tooltip: 'Xóa'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- Text Content ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(
                  "Giá từ ${product.minPrice.toStringAsFixed(0)}₫", 
                  style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w900, fontSize: 16)
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: outOfStock ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    outOfStock ? "🚫 HẾT HÀNG" : "✔ CÒN HÀNG",
                    style: TextStyle(color: outOfStock ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
