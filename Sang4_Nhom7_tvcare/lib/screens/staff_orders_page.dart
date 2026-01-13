import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/repair_api_service.dart';
import 'staff_order_detail_page.dart';

class StaffOrdersPage extends StatefulWidget {
  const StaffOrdersPage({Key? key}) : super(key: key);

  @override
  State<StaffOrdersPage> createState() => _StaffOrdersPageState();
}

class _StaffOrdersPageState extends State<StaffOrdersPage> {
  final RepairApiService _apiService = RepairApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Repairs'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _apiService.getMyRepairs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No assigned repairs.'));
          } else {
            final orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(order['customerName'] ?? 'N/A'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['address'] ?? 'N/A'),
                        Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(order['repairDate']))),
                      ],
                    ),
                    trailing: Text(order['status'] ?? 'N/A'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StaffOrderDetailPage(order: order),
                        ),
                      );
                    },
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
