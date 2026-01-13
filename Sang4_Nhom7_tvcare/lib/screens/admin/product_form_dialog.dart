import 'package:flutter/material.dart';
import '../../models/tv_models.dart';
import '../../services/admin_product_service.dart';
import '../../services/admin_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ProductFormDialog extends StatefulWidget {
  final int? productId;
  const ProductFormDialog({super.key, this.productId});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final AdminProductService _service = AdminProductService();
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _descController = TextEditingController();
  final _specValueController = TextEditingController(); 

  int? _selectedCategoryId;
  int? _selectedSpecMetadataId; 
  List<Category> _categories = [];
  final List<VariantFormItem> _variants = [];

  List<ProductSpecDetail> _currentSpecs = [];
  List<SpecDefinition> _availableSpecs = [];
  List<ProductListItem> _otherProducts = [];
  ProductListItem? _selectedSourceTv;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _adminService.getCategories(), 
        _service.getAdminProducts(pageSize: 1000),
        _service.getSpecs(), 
        if (widget.productId != null) _service.getProductDetail(widget.productId!),
        if (widget.productId != null) _service.getProductSpecs(widget.productId!),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _otherProducts = (results[1] as Map<String, dynamic>)['items'] as List<ProductListItem>;
          _availableSpecs = results[2] as List<SpecDefinition>;

          if (widget.productId != null) {
            final p = results[3] as ProductDetail;
            _nameController.text = p.name;
            _imageController.text = p.image;
            _descController.text = p.description ?? "";
            
            // FIX: Chọn đúng Thương hiệu dựa trên CategoryId hoặc tên
            int? targetId = p.categoryId ;
            if (targetId != null && _categories.any((c) => c.id == targetId)) {
              _selectedCategoryId = targetId;
            } else if (p.categoryName != null) {
              final found = _categories.where((c) => c.categoryName.toLowerCase() == p.categoryName!.toLowerCase());
              if (found.isNotEmpty) _selectedCategoryId = found.first.id;
            }

            _currentSpecs = results[4] as List<ProductSpecDetail>;
            _variants.clear();
            for (var v in p.variants) {
              _variants.add(VariantFormItem.fromModel(v));
            }
          } else {
            if (_variants.isEmpty) _addVariant(); 
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshSpecs() async {
    if (widget.productId == null) return;
    try {
      final specs = await _service.getProductSpecs(widget.productId!);
      setState(() {
        _currentSpecs = specs;
      });
    } catch (e) {
      debugPrint("Error refreshing specs: $e");
    }
  }

  void _addVariant() {
    setState(() => _variants.add(VariantFormItem()));
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      setState(() => _variants.removeAt(index));
    }
  }

  Future<void> _addSpec() async {
    if (widget.productId == null || _selectedSpecMetadataId == null || _specValueController.text.isEmpty) return;
    try {
      await _service.addSpecsToProduct(widget.productId!, [
        CreateProductSpecDto(specId: _selectedSpecMetadataId!, value: _specValueController.text.trim())
      ]);
      _specValueController.clear();
      _selectedSpecMetadataId = null;
      await _refreshSpecs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi thêm: $e")));
    }
  }

  Future<void> _handleClone() async {
    if (_selectedSourceTv == null || widget.productId == null) return;
    setState(() => _isLoading = true);
    try {
      await _service.cloneSpecs(_selectedSourceTv!.id, widget.productId!);
      await _refreshSpecs();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sao chép thành công!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi clone: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSpec(int productSpecId) async {
    try {
      await _service.deleteProductSpec(productSpecId);
      await _refreshSpecs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi xóa: $e")));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Parse bình thường, không lọc ký tự
    int parseSafeInt(String text) {
      final match = RegExp(r'\d+').firstMatch(text);
      return match == null ? 0 : int.parse(match.group(0)!);
    }


    double parseNormalDouble(String text) {
      return double.tryParse(text.trim()) ?? 0.0;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.productId == null) {
        final dto = CreateProductDto(
          name: _nameController.text.trim(),
          image: _imageController.text.trim(),
          description: _descController.text.trim(),
          categoryId: _selectedCategoryId,
          variants: _variants.map((v) => CreateProductVariantDto(
            variantName: v.nameController.text.trim(),
            size: parseSafeInt(v.sizeController.text),
            price: parseNormalDouble(v.priceController.text),
            stock: parseSafeInt(v.stockController.text),
          )).toList(),
        );
        await _service.createProduct(dto);
      } else {
        final updateDto = UpdateProductDto(
          name: _nameController.text.trim(),
          image: _imageController.text.trim(),
          description: _descController.text.trim(),
          categoryId: _selectedCategoryId,
          variants: _variants.map((v) => UpdateProductVariantDto(
            id: v.id ?? 0,
            variantName: v.nameController.text.trim(),
            size: parseSafeInt(v.sizeController.text),
            price: parseNormalDouble(v.priceController.text),
            stock: parseSafeInt(v.stockController.text),
          )).toList(),
        );
        
        debugPrint("DEBUG PUT PAYLOAD: ${jsonEncode(updateDto.toJson())}");
        
        await _service.updateProductInfo(widget.productId!, updateDto);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("!!! ERROR SAVE: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi lưu: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 1100, 
        padding: const EdgeInsets.all(24),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      widget.productId == null ? "THÊM SẢN PHẨM MỚI" : "CHỈNH SỬA SẢN PHẨM",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                    ),
                    const Divider(height: 40),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(title: "1. Thông tin chung"),
                              const SizedBox(height: 16),
                              _buildField("Tên Tivi", _nameController),
                              const SizedBox(height: 12),
                              _buildField("URL Hình ảnh", _imageController),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int?>(
                                value: _selectedCategoryId,
                                decoration: const InputDecoration(labelText: "Thương hiệu", border: OutlineInputBorder()),
                                items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName))).toList(),
                                onChanged: (v) => setState(() => _selectedCategoryId = v),
                                validator: (v) => v == null ? "Bắt buộc" : null,
                              ),
                              const SizedBox(height: 12),
                              _buildField("Mô tả", _descController, maxLines: 3),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const _SectionTitle(title: "2. Danh sách biến thể"),
                                  TextButton.icon(onPressed: _addVariant, icon: const Icon(Icons.add), label: const Text("Thêm size")),
                                ],
                              ),
                              ..._variants.asMap().entries.map((entry) => _buildVariantRow(entry.key, entry.value)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        const VerticalDivider(width: 1),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(title: "3. Thông số kỹ thuật (Specs)"),
                              const SizedBox(height: 16),
                              if (widget.productId == null)
                                const Center(child: Text("Vui lòng lưu sản phẩm trước khi thêm thông số.", style: TextStyle(color: Colors.grey, fontSize: 13)))
                              else ...[
                                _buildAddSpecPanel(),
                                const SizedBox(height: 16),
                                _buildSearchableCloneSection(),
                                const SizedBox(height: 24),
                                _buildSpecTable(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 60),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")),
                        const SizedBox(width: 12),
                        FilledButton(onPressed: _save, child: const Text("LƯU THAY ĐỔI")),
                      ],
                    )
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildVariantRow(int index, VariantFormItem item) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(flex: 3, child: _buildField("Tên loại", item.nameController)),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: item.sizeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: "Size (inch)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                v == null || v.isEmpty ? "Bắt buộc" : null,
              ),
            ),

            const SizedBox(width: 8),
            Expanded(flex: 2, child: _buildField("Giá", item.priceController, isNum: true)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _buildField("Kho", item.stockController, isNum: true)),
            IconButton(onPressed: () => _removeVariant(index), icon: const Icon(Icons.delete, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNum = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      validator: (v) => v == null || v.isEmpty ? "Bắt buộc" : null,
    );
  }

  Widget _buildAddSpecPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade100)),
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: _selectedSpecMetadataId,
            hint: const Text("Chọn loại thông số", style: TextStyle(fontSize: 12)),
            items: _availableSpecs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => setState(() { _selectedSpecMetadataId = v; _specValueController.clear(); }),
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSpecValueInput()),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _addSpec, icon: const Icon(Icons.add), style: IconButton.styleFrom(backgroundColor: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecValueInput() {
    if (_selectedSpecMetadataId == null) return const TextField(enabled: false, decoration: InputDecoration(hintText: "Nhập giá trị", isDense: true, border: OutlineInputBorder()));
    final meta = _availableSpecs.firstWhere((m) => m.id == _selectedSpecMetadataId);
    if (meta.valueType == SpecValueType.Select) {
      return DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
        items: meta.options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12)))).toList(),
        onChanged: (v) => _specValueController.text = v ?? "",
      );
    }
    return TextFormField(
      controller: _specValueController,
      decoration: const InputDecoration(hintText: "Giá trị", isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildSearchableCloneSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sao chép Spec từ TV khác", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          SearchAnchor(
            builder: (context, controller) {
              return SearchBar(
                controller: controller,
                hintText: _selectedSourceTv?.name ?? "Gõ tên TV nguồn...",
                onTap: () => controller.openView(),
                onChanged: (_) => controller.openView(),
                leading: const Icon(Icons.search, size: 20),
                trailing: [
                  if (_selectedSourceTv != null)
                    IconButton(onPressed: _handleClone, icon: const Icon(Icons.copy_all, color: Colors.blue))
                ],
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: const WidgetStatePropertyAll(Colors.white),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300))),
              );
            },
            suggestionsBuilder: (context, controller) {
              final keyword = controller.text.toLowerCase();
              final filtered = _otherProducts.where((p) => p.name.toLowerCase().contains(keyword) && p.id != widget.productId).toList();
              return filtered.map((p) => ListTile(
                title: Text(p.name, style: const TextStyle(fontSize: 13)),
                onTap: () {
                  setState(() => _selectedSourceTv = p);
                  controller.closeView(p.name);
                },
              ));
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTable() {
    if (_currentSpecs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa có thông số nào.", style: TextStyle(fontSize: 12, color: Colors.grey))));
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
      child: DataTable(
        columnSpacing: 10,
        horizontalMargin: 10,
        headingRowHeight: 40,
        columns: const [
          DataColumn(label: Text("Tên Spec", style: TextStyle(fontSize: 12))),
          DataColumn(label: Text("Giá trị", style: TextStyle(fontSize: 12))),
          DataColumn(label: Text("", style: TextStyle(fontSize: 12))),
        ],
        rows: _currentSpecs.map((s) => DataRow(cells: [
          DataCell(Text(s.name, style: const TextStyle(fontSize: 11))),
          DataCell(Text("${s.value} ${s.unit ?? ''}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataCell(IconButton(onPressed: () => _deleteSpec(s.productSpecId), icon: const Icon(Icons.close, size: 16, color: Colors.red))),
        ])).toList(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87));
  }
}

class VariantFormItem {
  int? id;
  final nameController = TextEditingController();
  final sizeController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  VariantFormItem();
  VariantFormItem.fromModel(ProductVariant v) {
    id = v.id;
    nameController.text = v.variantName;
    sizeController.text = v.size.toString();
    priceController.text = v.price.toString();
    stockController.text = v.stock.toString();
  }
}
