import 'package:flutter/material.dart';
import 'package:tvcare_flutter/services/admin_repair_service.dart';
import '../models/repair_models.dart';
import '../models/user_model.dart';

class AdminRepairOrdersManagementScreen extends StatefulWidget {
  const AdminRepairOrdersManagementScreen({super.key});

  @override
  State<AdminRepairOrdersManagementScreen> createState() =>
      _AdminRepairOrdersManagementScreenState();
}

class _AdminRepairOrdersManagementScreenState
    extends State<AdminRepairOrdersManagementScreen> {
  final AdminRepairService _adminRepairService = AdminRepairService();

  List<RepairOrder> _orders = [];
  List<UserModel> _staffs = [];
  Map<int, String?> _selectedStaffInDropdown = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final orders = await _adminRepairService.getAllOrders();
      final staffs = await _adminRepairService.getStaffs();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _staffs = staffs;
        _selectedStaffInDropdown = {}; 
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Đơn sửa chữa"), 
        actions: [
          IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh))
        ]
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [DataTable(
                  columns: const [
                    DataColumn(label: Text("ID")),
                    DataColumn(label: Text("Dịch vụ")),
                    DataColumn(label: Text("Khách hàng")),
                    DataColumn(label: Text("Nhân viên")),
                    DataColumn(label: Text("Trạng thái")),
                    DataColumn(label: Text("Gán việc")),
                  ],
                  rows: _orders.map((order) {
                    UserModel? assignedStaff;
                    if (order.staffId != null) {
                      try {
                        // FIX: Compare String with String
                        assignedStaff = _staffs.firstWhere((s) => s.id == order.staffId);
                      } catch (e) {
                        assignedStaff = null;
                      }
                    }

                    return DataRow(cells: [
                      DataCell(Text("#${order.id}")),
                      DataCell(Text(order.serviceName)),
                      DataCell(Text(order.customerName)),
                      DataCell(
                        DropdownButton<String>(
                          value: _selectedStaffInDropdown[order.id] ?? assignedStaff?.id,
                          hint: const Text("Chưa có"),
                          isExpanded: true,
                          items: _staffs
                              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName)))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              if (val != null) {
                                _selectedStaffInDropdown[order.id] = val;
                              }
                            });
                          },
                        ),
                      ),
                      DataCell(
                        DropdownButton<RepairStatus>(
                          value: order.status,
                          items: RepairStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                          onChanged: (val) async {
                            if (val != null && val != order.status) {
                              final success = await _adminRepairService.adminUpdateStatus(order.id, val);
                              if (success) {
                                _fetchData();
                              } else {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thất bại")));
                              }
                            }
                          },
                        ),
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed: (_selectedStaffInDropdown[order.id] == null || _selectedStaffInDropdown[order.id] == assignedStaff?.id) 
                              ? null 
                              : () async {
                                  final staffId = _selectedStaffInDropdown[order.id];
                                  if (staffId != null) {
                                    final success = await _adminRepairService.assignStaff(order.id, staffId);
                                    if (success) {
                                      _fetchData(); 
                                    } else {
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gán việc thất bại")));
                                    }
                                  }
                                },
                          child: const Text("Lưu"),
                        ),
                      ),
                    ]);
                  }).toList(),
                )],
              ),
            ),
          ),
    );
  }
}
