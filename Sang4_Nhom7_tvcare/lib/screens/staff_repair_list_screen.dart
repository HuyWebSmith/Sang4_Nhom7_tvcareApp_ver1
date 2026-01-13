import 'package:flutter/material.dart';
import '../services/staff_repair_service.dart';
import '../models/repair_models.dart';
import 'package:intl/intl.dart';

class StaffRepairListScreen extends StatefulWidget {
  const StaffRepairListScreen({super.key});

  @override
  State<StaffRepairListScreen> createState() => _StaffRepairListScreenState();
}

class _StaffRepairListScreenState extends State<StaffRepairListScreen> {
  final StaffRepairService _service = StaffRepairService();
  List<RepairOrder> _repairs = [];
  bool _isLoading = true;

  final List<String> _statusOptions = ['Confirmed', 'Repairing', 'Done', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchRepairs();
  }

  Future<void> _fetchRepairs() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getPendingRepairs();
      setState(() {
        _repairs = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAccept(RepairOrder repair) async {
    try {
      final success = await _service.acceptRepair(repair.id);
      if (success) {
        setState(() {
          repair.status = RepairStatus.Confirmed;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã nhận đơn thành công")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> _handleStatusChange(RepairOrder repair, String? newStatus) async {
    if (newStatus == null) return;
    
    RepairStatus status;
    switch (newStatus) {
      case 'Confirmed': status = RepairStatus.Confirmed; break;
      case 'Repairing': status = RepairStatus.Repairing; break;
      case 'Done': status = RepairStatus.Done; break;
      case 'Cancelled': status = RepairStatus.Cancelled; break;
      default: return;
    }

    try {
      final success = await _service.updateStatus(repair.id, status);
      if (success) {
        setState(() {
          repair.status = status;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã đổi sang trạng thái $newStatus")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách đơn sửa chữa", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _fetchRepairs, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _repairs.isEmpty 
          ? const Center(child: Text("Không có đơn hàng nào cần xử lý"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _repairs.length,
              itemBuilder: (context, index) {
                final repair = _repairs[index];
                return _buildRepairCard(repair);
              },
            ),
    );
  }

  Widget _buildRepairCard(RepairOrder repair) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Mã đơn: #${repair.id}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                _buildStatusBadge(repair.status),
              ],
            ),
            const Divider(height: 24),
            Text(repair.serviceName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(repair.repairDate)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Mô tả: ${repair.issueDescription ?? ''}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (repair.status == RepairStatus.Pending)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _handleAccept(repair),
                      icon: const Icon(Icons.check),
                      label: const Text("NHẬN ĐƠN"),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  )
                else
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _statusOptions.contains(repair.status.name) ? repair.status.name : null,
                      decoration: const InputDecoration(
                        labelText: "Cập nhật trạng thái",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => _handleStatusChange(repair, val),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RepairStatus status) {
    Color color;
    switch (status) {
      case RepairStatus.Pending: color = Colors.orange; break;
      case RepairStatus.Confirmed: color = Colors.blue; break;
      case RepairStatus.Repairing: color = Colors.purple; break;
      case RepairStatus.Done: color = Colors.green; break;
      case RepairStatus.Cancelled: color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
