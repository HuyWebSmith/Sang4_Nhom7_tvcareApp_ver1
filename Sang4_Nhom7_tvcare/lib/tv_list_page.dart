import 'package:flutter/material.dart';
import 'tv_detail_page.dart';
import 'services/product_service.dart';
import 'models/tv_models.dart';

class TVListPage extends StatefulWidget {
  const TVListPage({super.key});

  @override
  State<TVListPage> createState() => _TVListPageState();
}

class _TVListPageState extends State<TVListPage> {
  final ProductService _productService = ProductService();
  List<ProductListItem> allTVs = [];
  List<ProductListItem> filteredTVs = [];
  bool _isLoading = true;
  String selectedBrand = 'Tất cả';
  double maxPrice = 100000000;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await _productService.getProducts();
      setState(() {
        allTVs = data;
        filteredTVs = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterTVs() {
    setState(() {
      filteredTVs = allTVs.where((tv) {
        // Note: Backend ProductListItem may not have brand info currently. 
        // We'll filter by price for now.
        return tv.price <= maxPrice;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildHeader(context),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar Filter
              if (MediaQuery.of(context).size.width > 800)
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: _buildFilterSection(),
                ),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách Tivi (${filteredTVs.length})',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          if (MediaQuery.of(context).size.width <= 800)
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () => _showMobileFilter(context),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      filteredTVs.isEmpty 
                        ? const Center(child: Text("Không có sản phẩm nào"))
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: filteredTVs.length,
                            itemBuilder: (context, index) {
                              final tv = filteredTVs[index];
                              return _buildTVCard(tv);
                            },
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Row(
        children: [
          Icon(Icons.tv_rounded, color: Color(0xFF0D47A1), size: 28),
          SizedBox(width: 8),
          Text(
            'TVCARE',
            style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ],
      ),
      actions: [
        if (MediaQuery.of(context).size.width > 1000)
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tivi...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                fillColor: const Color(0xFFF1F5F9),
                filled: true,
              ),
            ),
          ),
        const SizedBox(width: 20),
        const CircleAvatar(backgroundColor: Color(0xFF0D47A1), child: Icon(Icons.person, color: Colors.white)),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hãng sản xuất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...['Tất cả', 'Samsung', 'Sony', 'LG', 'TCL'].map((brand) => RadioListTile<String>(
          title: Text(brand),
          value: brand,
          groupValue: selectedBrand,
          onChanged: (value) {
            setState(() {
              selectedBrand = value!;
              _filterTVs();
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        )),
        const SizedBox(height: 32),
        const Text('Khoảng giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Dưới ${maxPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ'),
        Slider(
          value: maxPrice,
          min: 0,
          max: 100000000,
          divisions: 20,
          onChanged: (value) {
            setState(() {
              maxPrice = value;
              _filterTVs();
            });
          },
        ),
      ],
    );
  }

  Widget _buildTVCard(ProductListItem tv) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFF1F5F9),
              width: double.infinity,
              child: tv.image != null && tv.image!.isNotEmpty
                  ? Image.network(tv.image!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.tv, size: 80, color: Colors.black12))
                  : const Icon(Icons.tv, size: 100, color: Colors.black12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tv.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('Kho: ${tv.stock}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Text(
                  '${tv.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TVDetailPage(productId: tv.id)));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.8,
        child: SingleChildScrollView(child: _buildFilterSection()),
      ),
    );
  }
}
