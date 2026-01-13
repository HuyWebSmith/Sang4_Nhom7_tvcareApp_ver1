import 'package:flutter/material.dart';
import 'package:tvcare_flutter/services/auth.dart';

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ Nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: <Widget>[
          _buildFeatureCard(
            context,
            icon: Icons.playlist_add_check,
            label: 'Đơn hàng đang chờ',
            routeName: '/staff-pending-repairs',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.assignment_turned_in,
            label: 'Đơn hàng của tôi',
            routeName: '/staff-repairs',
          ),
          // Bạn có thể thêm các chức năng khác ở đây
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required String label, required String routeName}) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, routeName),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
