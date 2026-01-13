import 'package:flutter/material.dart';
import '../../models/tv_models.dart';
import '../../services/admin_product_service.dart';
import 'product_form_dialog.dart';
import 'product_spec_manager_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final AdminProductService _service = AdminProductService();
  List<ProductListItem>? _products;
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchCtrl = TextEditingController();
  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _service.getAdminProducts(
        search: _searchCtrl.text,
        page: _currentPage,
        pageSize: _pageSize
      );
      if (mounted) {
        setState(() {
          _products = result['items'];
          _totalCount = result['totalCount'];
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showForm([int? productId]) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(productId: productId),
    );
    if (result == true) _loadProducts();
  }

  void _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xoá", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xoá sản phẩm này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("HỦY")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("XOÁ"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _service.deleteProduct(id);
      if (success) {
        _loadProducts();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xoá sản phẩm thành công")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatsSummary(),
                  _buildTableContent(),
                  _buildPagination(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Material(
      elevation: 1,
      color: Colors.white,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            const Text("Quản lý sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 48),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) {
                    _currentPage = 1;
                    _loadProducts();
                  },
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm tivi...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear), 
                      onPressed: () {
                        _searchCtrl.clear();
                        _currentPage = 1;
                        _loadProducts();
                      }
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("THÊM SẢN PHẨM"),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1), 
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _service.getDashboardStats(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {"totalProducts": 0, "totalStock": 0, "outOfStock": 0};
          return LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _statCard("Tổng sản phẩm", stats['totalProducts'].toString(), Icons.tv, Colors.blue, constraints.maxWidth),
                  _statCard("Tổng tồn kho", stats['totalStock'].toString(), Icons.warehouse, Colors.orange, constraints.maxWidth),
                  _statCard("Hết hàng", stats['outOfStock'].toString(), Icons.warning, Colors.red, constraints.maxWidth),
                ],
              );
            }
          );
        }
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, double maxWidth) {
    double cardWidth = (maxWidth - 32) / 3;
    if (maxWidth < 800) cardWidth = (maxWidth - 16) / 2;
    if (maxWidth < 500) cardWidth = maxWidth;

    return Container(
      width: cardWidth > 0 ? cardWidth : 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: const Color(0xFFE2E8F0))
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTableContent() {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    if (_error != null) return Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Lỗi: $_error")));
    if (_products == null || _products!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Không tìm thấy sản phẩm")));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)), 
          side: BorderSide(color: Color(0xFFE2E8F0))
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: const BoxConstraints(minWidth: 1000),
            child: DataTable(
              headingRowHeight: 50,
              dataRowMaxHeight: 70,
              columns: const [
                DataColumn(label: Text("HÌNH ẢNH")),
                DataColumn(label: Text("TÊN SẢN PHẨM")),
                DataColumn(label: Text("GIÁ THẤP NHẤT")),
                DataColumn(label: Text("KHO")),
                DataColumn(label: Text("TRẠNG THÁI")),
                DataColumn(label: Text("THAO TÁC")),
              ],
              rows: _products!.map((p) => DataRow(cells: [
                DataCell(_buildProductImage(p.image ?? '')),
                DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text("${p.minPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)))),
                DataCell(Text(p.stock.toString())),
                DataCell(_buildStockBadge(p.stock)),
                DataCell(Row(
                  children: [
                    IconButton(onPressed: () => _showForm(p.id), icon: const Icon(Icons.edit_outlined, color: Colors.blue), tooltip: "Chỉnh sửa"),
                    IconButton(onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProductSpecManagerScreen(productId: p.id, productName: p.name)));
                    }, icon: const Icon(Icons.settings_suggest_outlined, color: Colors.indigo), tooltip: "Quản lý Specs"),
                    IconButton(onPressed: () => _deleteProduct(p.id), icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: "Xóa"),
                  ],
                )),
              ])).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    int totalPages = (_totalCount / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox(height: 24);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 1 ? () {
            setState(() => _currentPage--);
            _loadProducts();
          } : null),
          Text("Trang $_currentPage / $totalPages"),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < totalPages ? () {
            setState(() => _currentPage++);
            _loadProducts();
          } : null),
        ],
      ),
    );
  }

  Widget _buildProductImage(String url) {
    return Container(
      width: 45,
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: url.isNotEmpty 
          ? Image.network(
            url, 
            fit: BoxFit.cover, 
            errorBuilder: (c,e,s) => const Icon(Icons.tv, size: 20, color: Colors.grey),
          )
          : const Icon(Icons.tv, size: 20, color: Colors.grey),
      ),
    );
  }

  Widget _buildStockBadge(int stock) {
    final bool isOut = stock == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: isOut ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(isOut ? "HẾT HÀNG" : "CÒN HÀNG", style: TextStyle(color: isOut ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
