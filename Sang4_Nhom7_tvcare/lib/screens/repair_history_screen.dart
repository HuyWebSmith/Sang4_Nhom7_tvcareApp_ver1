import 'package:flutter/material.dart';
import '../services/repair_history_service.dart';
import '../models/repair_models.dart';
import 'package:intl/intl.dart';

class RepairHistoryScreen extends StatefulWidget {
  const RepairHistoryScreen({super.key});

  @override
  State<RepairHistoryScreen> createState() => _RepairHistoryScreenState();
}

class _RepairHistoryScreenState extends State<RepairHistoryScreen> {
  final RepairHistoryService _service = RepairHistoryService();
  List<RepairOrder> _history = [];
  bool _isLoading = true;

  // Filter states
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;
  final List<String> _statuses = ['All', 'Pending', 'Confirmed', 'Repairing', 'Done', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      String? fromDate = _selectedDateRange?.start.toIso8601String();
      String? toDate = _selectedDateRange?.end.toIso8601String();
      
      final data = await _service.getRepairHistory(
        status: _selectedStatus,
        fromDate: fromDate,
        toDate: toDate,
      );
      setState(() {
        _history = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _fetchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Lịch sử sửa chữa", style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: _buildFilterSection(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _history.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) => _buildHistoryCard(_history[index]),
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: "Trạng thái",
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedStatus = val!);
                    _fetchHistory();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Khoảng ngày",
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedDateRange == null 
                        ? 'Tất cả' 
                        : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedDateRange != null || _selectedStatus != 'All')
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = 'All';
                  _selectedDateRange = null;
                });
                _fetchHistory();
              },
              child: const Text("Xóa bộ lọc", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(RepairOrder repair) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                Text("Đơn #${repair.id}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                _buildStatusBadge(repair.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(repair.serviceName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(DateFormat('HH:mm - dd/MM/yyyy').format(repair.repairDate), style: const TextStyle(color: Colors.black87)),
              ],
            ),
            if (repair.staffName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text("Nhân viên: ${repair.staffName}", style: const TextStyle(color: Colors.blueGrey)),
                ],
              ),
            ],
            const Divider(height: 24),
            Text(
              "Mô tả: ${repair.issueDescription ?? ''}",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RepairStatus status) {
    Color color;
    switch (status) {
      case RepairStatus.Pending: color = Colors.amber.shade700; break;
      case RepairStatus.Confirmed: color = Colors.blue; break;
      case RepairStatus.Repairing: color = Colors.orange; break;
      case RepairStatus.Done: color = Colors.green; break;
      case RepairStatus.Cancelled: color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.name.toUpperCase(), 
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Không tìm thấy lịch sử sửa chữa", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
