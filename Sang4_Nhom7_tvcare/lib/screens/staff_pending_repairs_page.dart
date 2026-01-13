import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tvcare_flutter/services/repair_api_service.dart';

import '../models/repair_models.dart';

class StaffPendingRepairsPage extends StatefulWidget {
  const StaffPendingRepairsPage({Key? key}) : super(key: key);

  @override
  State<StaffPendingRepairsPage> createState() => _StaffPendingRepairsPageState();
}

class _StaffPendingRepairsPageState extends State<StaffPendingRepairsPage> {
  final RepairApiService _apiService = RepairApiService();
  Future<List<RepairOrder>>? _pendingRepairsFuture;

  @override
  void initState() {
    super.initState();
    _loadPendingRepairs();
  }

  void _loadPendingRepairs() {
    setState(() {
      _pendingRepairsFuture = _apiService.getPendingRepairs();
    });
  }

  Future<void> _acceptOrder(int orderId) async {
    try {
      final success = await _apiService.acceptRepair(orderId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã nhận đơn thành công!')),
        );
        _loadPendingRepairs(); // Refresh the list
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể nhận đơn. Vui lòng thử lại.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng đang chờ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRepairs,
          ),
        ],
      ),
      body: FutureBuilder<List<RepairOrder>>(
        future: _pendingRepairsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có đơn hàng nào đang chờ.'));
          } else {
            final orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khách hàng: ${order.customerName ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Địa chỉ: ${order.address ?? 'N/A'}'),
                        Text('Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(order.repairDate)}'),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _acceptOrder(order.id),
                            child: const Text('Chấp nhận đơn'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
