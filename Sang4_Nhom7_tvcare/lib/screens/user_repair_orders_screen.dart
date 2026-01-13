import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/repair_order_service.dart';
import '../models/repair_models.dart';

class UserRepairOrdersScreen extends StatefulWidget {
  const UserRepairOrdersScreen({super.key});

  @override
  State<UserRepairOrdersScreen> createState() => _UserRepairOrdersScreenState();
}

class _UserRepairOrdersScreenState extends State<UserRepairOrdersScreen> {
  final RepairOrderService _service = RepairOrderService();
  List<RepairOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final list = await _service.getMyOrders();
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.Pending: return Colors.orange;
      case RepairStatus.Confirmed: return Colors.blue;
      case RepairStatus.Repairing: return Colors.purple;
      case RepairStatus.Done: return Colors.green;
      case RepairStatus.Cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đơn sửa của tôi"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty 
            ? const Center(child: Text("Bạn chưa có đơn sửa nào"))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Card(
                    // SỬA LỖI EdgeInsets.bottom THÀNH EdgeInsets.only
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(order.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              _StatusBadge(status: order.status, color: _getStatusColor(order.status)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(icon: Icons.calendar_today, text: DateFormat('dd/MM/yyyy HH:mm').format(order.repairDate)),
                          _InfoRow(icon: Icons.location_on_outlined, text: order.address ?? "Không rõ"),
                          _InfoRow(icon: Icons.phone_outlined, text: order.phoneNumber ?? ""),
                          const Divider(),
                          if (order.status == RepairStatus.Pending)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    final ok = await _service.cancelOrder(order.id);
                                    if (ok && mounted) _fetchOrders();
                                  }, 
                                  child: const Text("HỦY ĐƠN", style: TextStyle(color: Colors.red))
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(onPressed: () {}, child: const Text("SỬA")),
                              ],
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RepairStatus status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
