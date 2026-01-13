import 'package:flutter/material.dart';
import '../../models/tv_models.dart';
import '../../services/admin_product_service.dart';

class SpecManagementScreen extends StatefulWidget {
  const SpecManagementScreen({super.key});

  @override
  State<SpecManagementScreen> createState() => _SpecManagementScreenState();
}

class _SpecManagementScreenState extends State<SpecManagementScreen> {
  final AdminProductService _service = AdminProductService();
  List<SpecDefinition>? _specs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecs();
  }

  Future<void> _loadSpecs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _service.getSpecs();
      if (mounted) {
        setState(() {
          _specs = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForm([SpecDefinition? spec]) async {
    final result = await showDialog(
      context: context,
      builder: (context) => SpecFormDialog(spec: spec),
    );
    if (result == true) _loadSpecs();
  }

  void _deleteSpec(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa Spec này? Hành động này có thể ảnh hưởng đến các sản phẩm đang dùng nó."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("HỦY")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("XOÁ")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteSpec(id);
        _loadSpecs();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Không thể xóa: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Thông số (Spec Metadata)"),
        actions: [
          FilledButton.icon(onPressed: () => _showForm(), icon: const Icon(Icons.add), label: const Text("Thêm Spec")),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), 
                side: const BorderSide(color: Color(0xFFE2E8F0))
              ),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Thứ tự")),
                      DataColumn(label: Text("Tên Spec")),
                      DataColumn(label: Text("Đơn vị")),
                      DataColumn(label: Text("Kiểu dữ liệu")),
                      DataColumn(label: Text("Lọc")),
                      DataColumn(label: Text("Thao tác")),
                    ],
                    rows: _specs!.map((s) => DataRow(cells: [
                      DataCell(Text(s.sortOrder.toString())),
                      DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(s.unit ?? "-")),
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.valueType.name.toUpperCase()),
                          if (s.valueType == SpecValueType.Select && s.options.isNotEmpty)
                            Container(
                              width: 150,
                              child: Text(
                                s.options.join(", "),
                                style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      )),
                      DataCell(Icon(s.isFilterable ? Icons.check_circle : Icons.radio_button_unchecked, color: s.isFilterable ? Colors.green : Colors.grey, size: 20)),
                      DataCell(Row(
                        children: [
                          IconButton(onPressed: () => _showForm(s), icon: const Icon(Icons.edit_outlined, color: Colors.blue)),
                          IconButton(onPressed: () => _deleteSpec(s.id!), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                        ],
                      )),
                    ])).toList(),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class SpecFormDialog extends StatefulWidget {
  final SpecDefinition? spec;
  const SpecFormDialog({super.key, this.spec});

  @override
  State<SpecFormDialog> createState() => _SpecFormDialogState();
}

class _SpecFormDialogState extends State<SpecFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final AdminProductService _service = AdminProductService();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _orderCtrl;
  late TextEditingController _optionCtrl;
  
  SpecValueType _type = SpecValueType.Text;
  List<String> _options = [];
  bool _isFilterable = false;
  bool _isRequired = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.spec?.name);
    _unitCtrl = TextEditingController(text: widget.spec?.unit);
    _orderCtrl = TextEditingController(text: (widget.spec?.sortOrder ?? 0).toString());
    _optionCtrl = TextEditingController();
    
    if (widget.spec != null) {
      _type = widget.spec!.valueType;
      _options = List.from(widget.spec!.options);
      _isFilterable = widget.spec!.isFilterable;
      _isRequired = widget.spec!.isRequired;
    }
  }

  void _addOption() {
    final val = _optionCtrl.text.trim();
    if (val.isNotEmpty && !_options.contains(val)) {
      setState(() {
        _options.add(val);
        _optionCtrl.clear();
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final spec = SpecDefinition(
      id: widget.spec?.id,
      name: _nameCtrl.text.trim(),
      unit: _unitCtrl.text.isEmpty ? null : _unitCtrl.text.trim(),
      valueType: _type,
      options: _options,
      isFilterable: _isFilterable,
      isRequired: _isRequired,
      sortOrder: int.tryParse(_orderCtrl.text) ?? 0,
    );

    try {
      if (widget.spec == null) {
        await _service.createSpec(spec);
      } else {
        await _service.updateSpec(widget.spec!.id!, spec);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.spec == null ? "Thêm Spec Metadata" : "Sửa Spec Metadata"),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl, 
                  decoration: const InputDecoration(labelText: "Tên thông số (VD: Độ phân giải)", border: OutlineInputBorder()), 
                  validator: (v) => v!.isEmpty ? "Bắt buộc" : null
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitCtrl, 
                  decoration: const InputDecoration(labelText: "Đơn vị (inch, Hz, ...) - Có thể bỏ trống", border: OutlineInputBorder())
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SpecValueType>(
                  value: _type,
                  items: SpecValueType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                  decoration: const InputDecoration(labelText: "Kiểu dữ liệu", border: OutlineInputBorder()),
                ),
                
                // PHẦN THÊM OPTIONS CHO LOẠI SELECT
                if (_type == SpecValueType.Select) ...[
                  const SizedBox(height: 20),
                  const Text("Danh sách các lựa chọn (Options):", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionCtrl, 
                          decoration: const InputDecoration(
                            hintText: "Nhập giá trị (VD: OLED, 4K...)", 
                            border: OutlineInputBorder(),
                            isDense: true
                          ),
                          onFieldSubmitted: (_) => _addOption(),
                        )
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(onPressed: _addOption, icon: const Icon(Icons.add)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: _options.isEmpty 
                      ? const Text("Chưa có lựa chọn nào. Hãy nhập ở trên.", style: TextStyle(color: Colors.grey, fontSize: 12))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _options.map((opt) => Chip(
                            label: Text(opt, style: const TextStyle(fontSize: 12)), 
                            onDeleted: () => setState(() => _options.remove(opt)),
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        ),
                  ),
                ],
                
                const SizedBox(height: 16),
                SwitchListTile(title: const Text("Dùng để lọc (Filter)"), value: _isFilterable, onChanged: (v) => setState(() => _isFilterable = v)),
                SwitchListTile(title: const Text("Bắt buộc nhập"), value: _isRequired, onChanged: (v) => setState(() => _isRequired = v)),
                const SizedBox(height: 16),
                TextFormField(controller: _orderCtrl, decoration: const InputDecoration(labelText: "Thứ tự hiển thị", border: OutlineInputBorder()), keyboardType: TextInputType.number),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")),
        FilledButton(onPressed: _save, child: const Text("LƯU")),
      ],
    );
  }
}
