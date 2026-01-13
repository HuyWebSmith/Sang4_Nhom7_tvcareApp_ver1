import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tvcare_flutter/services/staff_repair_service.dart';
import '../models/repair_models.dart';
import 'staff_repair_detail_screen.dart';
import 'staff_navigation_map_page.dart'; // Import trang chỉ đường

class StaffRepairManagementScreen extends StatefulWidget {
  const StaffRepairManagementScreen({super.key});

  @override
  State<StaffRepairManagementScreen> createState() => _StaffRepairManagementScreenState();
}

class _StaffRepairManagementScreenState extends State<StaffRepairManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StaffRepairService _service = StaffRepairService();
  
  List<RepairOrder> _pendingOrders = [];
  List<RepairOrder> _myOrders = [];
  bool _isLoadingPending = true;
  bool _isLoadingMyOrders = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_tabController.index == 0) {
      await _fetchPending();
    } else {
      await _fetchMyOrders();
    }
  }

  Future<void> _fetchPending() async {
    if (!mounted) return;
    setState(() => _isLoadingPending = true);
    try {
      final list = await _service.getPendingRepairs();
      if (mounted) setState(() => _pendingOrders = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải đơn chờ: $e")));
    } finally {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _fetchMyOrders() async {
    if (!mounted) return;
    setState(() => _isLoadingMyOrders = true);
    try {
      final list = await _service.getMyRepairs();
      if (mounted) setState(() => _myOrders = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải đơn của tôi: $e")));
    } finally {
      if (mounted) setState(() => _isLoadingMyOrders = false);
    }
  }

  void _navigateToDetailAndRefresh(RepairOrder order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StaffRepairDetailScreen(order: order)),
    );

    if (result == true) {
      _fetchData(); 
      _tabController.animateTo(1);
    }
  }

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.Pending: return Colors.orange;
      case RepairStatus.Confirmed: return Colors.blue;
      case RepairStatus.Repairing: return Colors.purple;
      case RepairStatus.Done: return Colors.green;
      case RepairStatus.Cancelled: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(RepairStatus status) {
     switch (status) {
      case RepairStatus.Pending: return Icons.hourglass_top_rounded;
      case RepairStatus.Confirmed: return Icons.check_circle_outline_rounded;
      case RepairStatus.Repairing: return Icons.build_rounded;
      case RepairStatus.Done: return Icons.task_alt_rounded;
      case RepairStatus.Cancelled: return Icons.cancel_outlined;
      default: return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Quản lý Đơn sửa chữa"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Đơn chờ nhận"), Tab(text: "Đơn của tôi")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_isLoadingPending, _pendingOrders, _buildPendingOrderItem, _fetchPending, "Không có đơn hàng nào chờ nhận."),
          _buildList(_isLoadingMyOrders, _myOrders, _buildMyOrderItem, _fetchMyOrders, "Bạn chưa nhận đơn hàng nào."),
        ],
      ),
    );
  }

  Widget _buildList(bool isLoading, List<RepairOrder> orders, Widget Function(RepairOrder) itemBuilder, Future<void> Function() onRefresh, String emptyMessage) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (orders.isEmpty) return Center(child: Text(emptyMessage));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) => itemBuilder(orders[index]),
      ),
    );
  }

  Widget _buildPendingOrderItem(RepairOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
            const Divider(height: 20),
            _buildInfoRow(Icons.person_outline, 'Khách hàng', order.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', order.address),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_outlined, 'Ngày hẹn', DateFormat('dd/MM/yyyy HH:mm').format(order.repairDate)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                label: const Text('Xem chi tiết & Nhận đơn'),
                onPressed: () => _navigateToDetailAndRefresh(order),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrderItem(RepairOrder order) {
    Color statusColor = _getStatusColor(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final refreshed = await Navigator.push(context, MaterialPageRoute(builder: (_) => StaffRepairDetailScreen(order: order)));
          if (refreshed == true) _fetchMyOrders();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: statusColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(_getStatusIcon(order.status), color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(order.status.name.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text("#${order.id}", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person_outline, 'Khách hàng', order.customerName),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Ngày hẹn', DateFormat('dd/MM/yyyy HH:mm').format(order.repairDate)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.near_me_outlined, size: 20),
                    label: const Text('Chỉ đường đến khách hàng'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => StaffNavigationMapPage(orderId: order.id)));
                    },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.green[600],
                       foregroundColor: Colors.white,
                       minimumSize: const Size(double.infinity, 44),
                     ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(value ?? 'N/A', style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
}
