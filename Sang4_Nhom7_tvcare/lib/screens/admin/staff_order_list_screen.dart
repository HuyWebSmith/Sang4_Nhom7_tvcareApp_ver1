import 'package:flutter/material.dart';
import '../../models/repair_models.dart';
import '../../services/admin_repair_service.dart';

class StaffOrderListScreen extends StatefulWidget {
  final String staffId;
  final String staffName;

  const StaffOrderListScreen({super.key, required this.staffId, required this.staffName});

  @override
  State<StaffOrderListScreen> createState() => _StaffOrderListScreenState();
}

class _StaffOrderListScreenState extends State<StaffOrderListScreen> {
  final AdminRepairService _service = AdminRepairService();
  Future<List<RepairOrder>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadAndFilterOrders();
  }

  Future<List<RepairOrder>> _loadAndFilterOrders() async {
    final allOrders = await _service.getAllOrders();
    return allOrders.where((order) => order.staffId.toString() == widget.staffId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đơn sửa chữa của ${widget.staffName}"),
      ),
      body: FutureBuilder<List<RepairOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
          }
          final orders = snapshot.data;
          if (orders == null || orders.isEmpty) {
            return const Center(child: Text("Nhân viên này chưa có đơn hàng nào."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(order.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Khách: ${order.customerName}\nTrạng thái: ${order.status.name}"),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
