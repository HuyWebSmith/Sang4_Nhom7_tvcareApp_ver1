import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import '../models/repair_report_models.dart';
import '../services/admin_repair_report_service.dart';

class AdminRepairReportScreen extends StatefulWidget {
  const AdminRepairReportScreen({super.key});

  @override
  State<AdminRepairReportScreen> createState() => _AdminRepairReportScreenState();
}

class _AdminRepairReportScreenState extends State<AdminRepairReportScreen> {
  final AdminRepairReportService _service = AdminRepairReportService();
  List<RepairReportItem> _allRepairs = [];
  bool _isLoading = true;

  // Filters
  String _selectedStatus = 'All';
  final _staffController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  final List<String> _statuses = ['All', 'Pending', 'Confirmed', 'Repairing', 'Done', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAdminRepairs(
        staffName: _staffController.text.trim(),
        status: _selectedStatus,
        fromDate: _selectedDateRange?.start.toIso8601String(),
        toDate: _selectedDateRange?.end.toIso8601String(),
      );
      setState(() {
        _allRepairs = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _fetchData();
    }
  }

  Future<void> _exportToExcel() async {
    if (_allRepairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không có dữ liệu để xuất")));
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Repair Report'];
    excel.setDefaultSheet('Repair Report');

    // Header
    sheetObject.appendRow([
      TextCellValue('Mã đơn'),
      TextCellValue('Khách hàng'),
      TextCellValue('Nhân viên'),
      TextCellValue('Dịch vụ'),
      TextCellValue('Ngày sửa'),
      TextCellValue('Trạng thái'),
    ]);

    // Data
    for (var item in _allRepairs) {
      sheetObject.appendRow([
        IntCellValue(item.id),
        TextCellValue(item.userName),
        TextCellValue(item.staffName ?? '-'),
        TextCellValue(item.serviceName),
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(item.repairDate)),
        TextCellValue(item.status),
      ]);
    }

    var fileBytes = excel.save();
    String fileName = "repair-report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}";

    if (fileBytes != null) {
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(fileBytes),
        ext: "xlsx",
        mimeType: MimeType.microsoftExcel,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xuất file Excel thành công")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo sửa chữa", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.file_download, color: Colors.green),
            label: const Text("Excel", style: TextStyle(color: Colors.green)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _allRepairs.isEmpty
                ? const Center(child: Text("Không tìm thấy dữ liệu báo cáo"))
                : _buildReportTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _staffController,
                  decoration: const InputDecoration(
                    labelText: "Tên nhân viên",
                    prefixIcon: Icon(Icons.person_search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _fetchData(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: "Trạng thái",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedStatus = val!);
                    _fetchData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Khoảng ngày",
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.date_range),
                    ),
                    child: Text(
                      _selectedDateRange == null 
                        ? "Chọn ngày" 
                        : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _fetchData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                child: const Icon(Icons.search),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
          columns: const [
            DataColumn(label: Text("Mã đơn", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Khách hàng", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Nhân viên", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Dịch vụ", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Ngày sửa", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Trạng thái", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _allRepairs.map((item) => DataRow(cells: [
            DataCell(Text("#${item.id}")),
            DataCell(Text(item.userName)),
            DataCell(Text(item.staffName ?? "-")),
            DataCell(Text(item.serviceName)),
            DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(item.repairDate))),
            DataCell(_buildStatusBadge(item.status)),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Pending': color = Colors.amber.shade700; break;
      case 'Confirmed': color = Colors.blue; break;
      case 'Repairing': color = Colors.orange; break;
      case 'Done': color = Colors.green; break;
      case 'Cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
