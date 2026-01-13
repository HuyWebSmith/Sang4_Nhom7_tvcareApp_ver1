import 'package:flutter/material.dart';
import '../../models/tv_models.dart';
import '../../services/admin_product_service.dart';

class ProductSpecManagerScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const ProductSpecManagerScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductSpecManagerScreen> createState() => _ProductSpecManagerScreenState();
}

class _ProductSpecManagerScreenState extends State<ProductSpecManagerScreen> {
  final AdminProductService _service = AdminProductService();
  
  List<ProductSpecDetail> _currentSpecs = [];
  List<SpecDefinition> _availableMetadata = [];
  List<ProductListItem> _otherProducts = [];
  
  bool _isLoading = true;
  int? _selectedMetadataId;
  final TextEditingController _valueCtrl = TextEditingController();
  ProductListItem? _selectedSourceProduct;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getProductSpecs(widget.productId),
        _service.getSpecs(),
        _service.getAdminProducts(pageSize: 1000),
      ]);

      if (mounted) {
        setState(() {
          _currentSpecs = results[0] as List<ProductSpecDetail>;
          _availableMetadata = results[1] as List<SpecDefinition>;
          final allProds = results[2] as Map<String, dynamic>;
          _otherProducts = (allProds['items'] as List<ProductListItem>)
              .where((p) => p.id != widget.productId)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSpec() async {
    if (_selectedMetadataId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn loại thông số")));
       return;
    }
    if (_valueCtrl.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập giá trị")));
       return;
    }

    try {
      // ĐÂY CHÍNH LÀ CHỖ GỬI CreateProductSpecDto (SpecId và Value)
      await _service.addSpecsToProduct(widget.productId, [
        CreateProductSpecDto(specId: _selectedMetadataId!, value: _valueCtrl.text.trim())
      ]);
      _valueCtrl.clear();
      _selectedMetadataId = null;
      _loadAllData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thêm thành công!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi thêm: $e")));
    }
  }

  Future<void> _updateSpec(int productSpecId, String newValue) async {
    try {
      await _service.updateProductSpec(productSpecId, newValue);
      _loadAllData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi cập nhật: $e")));
    }
  }

  Future<void> _deleteSpec(int productSpecId) async {
    try {
      await _service.deleteProductSpec(productSpecId);
      _loadAllData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi xóa: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cấu hình thông số: ${widget.productName}")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PHẦN THÊM MỚI (Ứng với CreateProductSpecDto)
                _buildAddCard(),
                const SizedBox(height: 24),
                // 2. DANH SÁCH ĐÃ CÓ
                const Text("Thông số hiện tại của sản phẩm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Expanded(child: _buildSpecTableCard()),
              ],
            ),
          ),
    );
  }

  Widget _buildAddCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Thêm thông số kỹ thuật mới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CHỌN LOẠI SPEC (SpecId)
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _selectedMetadataId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: "Chọn loại thông số", filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                    items: _availableMetadata.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                    onChanged: (v) => setState(() {
                      _selectedMetadataId = v;
                      _valueCtrl.clear();
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                // NHẬP GIÁ TRỊ (Value)
                Expanded(
                  flex: 3,
                  child: _buildValueInputWidget(),
                ),
                const SizedBox(width: 16),
                // NÚT THÊM
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: _addSpec, 
                    icon: const Icon(Icons.add), 
                    label: const Text("THÊM")
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueInputWidget() {
    if (_selectedMetadataId == null) {
      return const TextField(enabled: false, decoration: InputDecoration(hintText: "Chọn loại trước...", filled: true, fillColor: Colors.white, border: OutlineInputBorder()));
    }
    
    final meta = _availableMetadata.firstWhere((m) => m.id == _selectedMetadataId);
    
    // Nếu là loại SELECT thì hiện sổ xuống
    if (meta.valueType == SpecValueType.Select) {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: "Chọn giá trị", filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
        items: meta.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) => _valueCtrl.text = v ?? "",
      );
    }
    
    // Nếu là loại Boolean thì hiện bật tắt
    if (meta.valueType == SpecValueType.Boolean) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey)),
        child: Row(
          children: [
            const Text("Kích hoạt?"),
            const Spacer(),
            Switch(
              value: _valueCtrl.text == "true",
              onChanged: (v) => setState(() => _valueCtrl.text = v.toString()),
            ),
          ],
        ),
      );
    }

    // Mặc định là nhập văn bản hoặc số
    return TextFormField(
      controller: _valueCtrl,
      keyboardType: meta.valueType == SpecValueType.Number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: "Nhập giá trị ${meta.unit != null ? '(${meta.unit})' : ''}",
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder()
      ),
    );
  }

  Widget _buildSpecTableCard() {
    if (_currentSpecs.isEmpty) {
      return const Center(child: Text("Sản phẩm này chưa có thông số nào."));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: ListView.separated(
        itemCount: _currentSpecs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = _currentSpecs[index];
          return ListTile(
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: s.unit != null ? Text(s.unit!) : null,
            trailing: SizedBox(
              width: 300,
              child: Row(
                children: [
                  Expanded(child: _buildInlineEdit(s)),
                  IconButton(onPressed: () => _deleteSpec(s.productSpecId), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInlineEdit(ProductSpecDetail s) {
    final meta = _availableMetadata.firstWhere(
      (m) => m.id == s.specId, 
      orElse: () => SpecDefinition(name: s.name, valueType: s.valueType, options: [], unit: s.unit)
    );

    if (s.valueType == SpecValueType.Select && meta.options.isNotEmpty) {
      return DropdownButton<String>(
        value: meta.options.contains(s.value) ? s.value : null,
        isExpanded: true,
        underline: Container(),
        items: meta.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) { if (v != null) _updateSpec(s.productSpecId, v); },
      );
    }

    if (s.valueType == SpecValueType.Boolean) {
      return Switch(
        value: s.value.toLowerCase() == "true",
        onChanged: (v) => _updateSpec(s.productSpecId, v.toString()),
      );
    }

    return TextFormField(
      initialValue: s.value,
      onFieldSubmitted: (v) => _updateSpec(s.productSpecId, v),
      decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: "Nhấn để sửa..."),
    );
  }
}
