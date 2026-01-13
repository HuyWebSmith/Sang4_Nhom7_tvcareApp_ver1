import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/repair_models.dart';
import '../../services/repair_service.dart' as service; // Added prefix

class UserRepairDetailScreen extends StatefulWidget {
  final RepairOrder order;

  const UserRepairDetailScreen({super.key, required this.order});

  @override
  State<UserRepairDetailScreen> createState() => _UserRepairDetailScreenState();
}

class _UserRepairDetailScreenState extends State<UserRepairDetailScreen> {
  final service.RepairService _service = service.RepairService(); // Use prefix
  late RepairOrder _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
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
      appBar: AppBar(
        title: Text("Chi tiết đơn #${_currentOrder.id}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Thông tin Dịch vụ',
              [
                _buildDetailRow('Dịch vụ:', _currentOrder.serviceName),
                _buildDetailRow('Ngày hẹn sửa:', DateFormat('dd/MM/yyyy HH:mm').format(_currentOrder.repairDate)),
                _buildDetailSection('Mô tả sự cố:', _currentOrder.issueDescription ?? 'Không có mô tả.'),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Thông tin liên hệ',
              [
                _buildDetailRow('Họ tên:', _currentOrder.customerName ?? 'N/A'),
                _buildDetailRow('Số điện thoại:', _currentOrder.phoneNumber ?? 'N/A'),
                _buildDetailRow('Địa chỉ:', _currentOrder.address ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _getStatusColor(_currentOrder.status).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("TRẠNG THÁI", style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(_currentOrder.status))),
            const SizedBox(height: 8),
            Text(_currentOrder.status.name.toUpperCase(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: _getStatusColor(_currentOrder.status))),
            if (_currentOrder.staffName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Nhân viên phụ trách: ${_currentOrder.staffName}"),
              )
          ],
        ),
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
