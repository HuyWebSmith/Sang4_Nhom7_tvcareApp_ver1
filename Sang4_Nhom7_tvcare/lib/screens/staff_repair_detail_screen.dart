import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/repair_models.dart';
import '../../services/staff_repair_service.dart';

class StaffRepairDetailScreen extends StatefulWidget {
  final RepairOrder order;

  const StaffRepairDetailScreen({super.key, required this.order});

  @override
  State<StaffRepairDetailScreen> createState() => _StaffRepairDetailScreenState();
}

class _StaffRepairDetailScreenState extends State<StaffRepairDetailScreen> {
  final StaffRepairService _service = StaffRepairService();
  bool _isProcessing = false;
  late RepairOrder _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _updateStatus(RepairStatus newStatus) async {
    setState(() => _isProcessing = true);
    final success = await _service.updateStatus(_currentOrder.id, newStatus);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật trạng thái thành công!"), backgroundColor: Colors.green),
        );
        setState(() {
          _currentOrder.status = newStatus;
          _isProcessing = false;
        });
        Navigator.pop(context, true); // Pop and signal refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thao tác thất bại."), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn #${_currentOrder.id}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true), // Always signal refresh on back
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDetailCard(
              'Thông tin Khách hàng',
              [
                _buildDetailRow('Họ tên:', _currentOrder.customerName ?? 'N/A'),
                _buildDetailRow('Số điện thoại:', _currentOrder.phoneNumber ?? 'N/A'),
                _buildDetailRow('Địa chỉ:', _currentOrder.address ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Thông tin Dịch vụ',
              [
                _buildDetailRow('Dịch vụ:', _currentOrder.serviceName),
                _buildDetailRow('Ngày hẹn sửa:', DateFormat('dd/MM/yyyy HH:mm').format(_currentOrder.repairDate)),
                _buildDetailSection('Mô tả sự cố:', _currentOrder.issueDescription ?? 'Không có mô tả.'),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildActionButtons(),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentOrder.status) {
      case RepairStatus.Confirmed:
        return _actionButton(
          "BẮT ĐẦU SỬA CHỮA",
          Icons.construction,
          Colors.purple,
          () => _updateStatus(RepairStatus.Repairing),
        );
      case RepairStatus.Repairing:
        return _actionButton(
          "HOÀN THÀNH SỬA CHỮA",
          Icons.check_circle,
          Colors.green,
          () => _updateStatus(RepairStatus.Done),
        );
      default:
        return const SizedBox.shrink(); // No actions for other statuses
    }
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
