import 'package:flutter/material.dart';
import 'services/product_service.dart';
import 'models/tv_models.dart';

class TVDetailPage extends StatefulWidget {
  final int productId;
  const TVDetailPage({super.key, required this.productId});

  @override
  State<TVDetailPage> createState() => _TVDetailPageState();
}

class _TVDetailPageState extends State<TVDetailPage> {
  final ProductService _service = ProductService();
  ProductDetail? _product;
  ProductVariant? _selectedVariant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final data = await _service.getProductDetail(widget.productId);
      if (mounted) {
        setState(() {
          _product = data;
          _isLoading = false;
          if (_product!.variants.isNotEmpty) {
            _selectedVariant = _product!.variants.first;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading detail: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_product == null) return const Scaffold(body: Center(child: Text("Không tìm thấy sản phẩm")));

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 24),
                  _buildVariantSelector(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                  _buildTechSpecs(), // PHẦN THÔNG SỐ KỸ THUẬT
                  const SizedBox(height: 40),
                  _buildDescription(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFFF8FAFC),
          child: Hero(
            tag: 'product_${_product!.id}',
            child: _product!.image.isNotEmpty 
              ? Image.network(_product!.image, fit: BoxFit.contain)
              : const Icon(Icons.tv, size: 150, color: Colors.black12),
          ),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    String formattedPrice = _selectedVariant != null 
        ? "${_selectedVariant!.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫" 
        : "N/A";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(_product!.brandName.toUpperCase(), style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
        ),
        const SizedBox(height: 12),
        Text(_product!.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(formattedPrice, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFE11D48))),
            const Spacer(),
            if (_selectedVariant != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                child: Text("Sẵn hàng: ${_selectedVariant!.stock}", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Kích thước màn hình", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF334155))),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _product!.variants.map((v) {
            bool isSelected = _selectedVariant?.id == v.id;
            return InkWell(
              onTap: v.stock > 0 ? () => setState(() => _selectedVariant = v) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300, width: 2),
                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
                child: Text(
                  "${v.size} inch",
                  style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: (_selectedVariant == null || _selectedVariant!.stock == 0) ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("MUA NGAY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            height: 60,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0D47A1))),
          ),
        ),
      ],
    );
  }

  Widget _buildTechSpecs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest, color: Color(0xFF0D47A1)),
              const SizedBox(width: 12),
              const Text("Thông số kỹ thuật", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 20),
          if (_product!.specs.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Đang cập nhật thông số...")))
          else
            ..._product!.specs.map((s) => _buildSpecItem(s)).toList(),
        ],
      ),
    );
  }

  Widget _buildSpecItem(ProductSpecDetail s) {
    String displayValue = s.value;
    if (s.valueType == SpecValueType.Boolean) {
      displayValue = s.value.toLowerCase() == "true" ? "Có" : "Không";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(s.name, style: TextStyle(color: Colors.grey.shade600, fontSize: 15))),
          const SizedBox(width: 16),
          Expanded(
            flex: 3, 
            child: Text(
              "$displayValue ${s.unit ?? ''}", 
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF334155)),
              textAlign: TextAlign.right,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Đặc điểm nổi bật", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        Text(
          _product!.description ?? "Không có mô tả cho sản phẩm này.",
          style: const TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.8),
        ),
      ],
    );
  }
}
