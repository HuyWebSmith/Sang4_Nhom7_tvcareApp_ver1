import 'package:flutter/material.dart';
import 'package:tvcare_flutter/screens/admin/admin_invoice_management_screen.dart';
import 'package:tvcare_flutter/services/auth.dart';
import 'screens/admin_repair_service_management_screen.dart';
import 'category_management_page.dart';
import 'screens/admin/spec_management_screen.dart';
import 'screens/admin_staff_management_screen.dart';
import 'screens/admin_repair_orders_management_screen.dart';
import 'screens/admin/product_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  // Add the new screen to the list of pages
  final List<Widget> _adminPages = [
    const AdminRepairOrdersManagementScreen(),
    const AdminInvoiceManagementScreen(), // New Invoice Screen
    const AdminRepairServiceManagementScreen(),
    const ProductManagementScreen(),
    const AdminStaffManagementScreen(),
    const SpecManagementScreen(),
    const CategoryManagementPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await Auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: isWideScreen ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
            extended: isWideScreen,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: Text('Đơn sửa chữa'),
              ),
              // Add the new destination for invoices
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Hóa đơn'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.build_circle_outlined),
                selectedIcon: Icon(Icons.build_circle),
                label: Text('Dịch vụ'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tv_outlined),
                selectedIcon: Icon(Icons.tv),
                label: Text('Sản phẩm'),
              ),
               NavigationRailDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt),
                label: Text('Nhân viên'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_input_component_outlined),
                selectedIcon: Icon(Icons.settings_input_component),
                label: Text('Thông số'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('Thương hiệu'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _adminPages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
