import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tvcare_flutter/screens/staff_navigation_map_page.dart';

class StaffOrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const StaffOrderDetailPage({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order['customerName'] ?? 'N/A'}'),
            Text('Address: ${order['address'] ?? 'N/A'}'),
            Text('Phone: ${order['phoneNumber'] ?? 'N/A'}'),
            Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(order['repairDate']))}'),
            Text('Status: ${order['status'] ?? 'N/A'}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffNavigationMapPage(orderId: order['id'] as int),
                  ),
                );
              },
              child: const Text('Chỉ đường đến khách hàng'),
            ),
          ],
        ),
      ),
    );
  }
}
