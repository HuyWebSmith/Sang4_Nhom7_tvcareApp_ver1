import 'package:flutter/material.dart';
import '../services/admin_staff_service.dart';
import '../models/staff_models.dart';

class AdminStaffManagementScreen extends StatefulWidget {
  const AdminStaffManagementScreen({super.key});

  @override
  State<AdminStaffManagementScreen> createState() => _AdminStaffManagementScreenState();
}

class _AdminStaffManagementScreenState extends State<AdminStaffManagementScreen> {
  final AdminStaffService _service = AdminStaffService();
  List<StaffMember> _staffList = [];
  bool _isLoading = true;
  
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _service.getStaffList(page: _currentPage, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _staffList = result['items'];
        _totalCount = result['totalCount'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLock(StaffMember staff) async {
    final bool lock = !staff.isLocked;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lock ? "Khóa tài khoản" : "Mở khóa tài khoản"),
        content: Text("Bạn có chắc muốn ${lock ? 'Khóa' : 'Mở khóa'} tài khoản của ${staff.fullName}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("HỦY")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("XÁC NHẬN")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _service.toggleLockAccount(staff.userId, lock);
        if (success && mounted) {
          _fetchStaff();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý nhân viên"),
        actions: [
          IconButton(onPressed: _fetchStaff, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [DataTable(
                      columnSpacing: 40,
                      headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                      columns: const [
                        DataColumn(label: Text("UserID")),
                        DataColumn(label: Text("Họ tên")),
                        DataColumn(label: Text("Email")),
                        DataColumn(label: Text("Đơn đã xử lý")),
                        DataColumn(label: Text("Trạng thái")),
                        DataColumn(label: Text("Thao tác")),
                      ],
                      rows: _staffList.map((staff) => DataRow(cells: [
                        DataCell(Text("#${staff.userId.length > 8 ? staff.userId.substring(0,8) + '...' : staff.userId}")),
                        DataCell(Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(staff.email)),
                        DataCell(Center(child: Text(staff.processedOrders.toString()))),
                        DataCell(_buildStatusBadge(staff.isLocked)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _toggleLock(staff),
                              icon: Icon(
                                staff.isLocked ? Icons.lock_open : Icons.lock_outline,
                                color: staff.isLocked ? Colors.green : Colors.red,
                              ),
                              tooltip: staff.isLocked ? "Mở khóa" : "Khóa",
                            ),
                          ],
                        )),
                      ])).toList(),
                    )],
                  ),
                ),
                _buildPagination(),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildStatusBadge(bool isLocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocked ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isLocked ? "LOCKED" : "ACTIVE",
        style: TextStyle(
          color: isLocked ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    int totalPages = (_totalCount / _pageSize).ceil();
    if (totalPages == 0) totalPages = 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Hiển thị $_pageSize / $_totalCount nhân viên"),
          const SizedBox(width: 20),
          IconButton(
            onPressed: _currentPage > 1 ? () { setState(() => _currentPage--); _fetchStaff(); } : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text("Trang $_currentPage / $totalPages"),
          IconButton(
            onPressed: _currentPage < totalPages ? () { setState(() => _currentPage++); _fetchStaff(); } : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
