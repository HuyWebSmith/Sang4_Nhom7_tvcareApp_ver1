import 'package:flutter/material.dart';
import 'package:tvcare_flutter/services/auth.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndNavigate();
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    final bool isLoggedIn = await Auth.isLoggedIn();
    
    // Phải thêm một khoảng delay nhỏ để Navigator sẵn sàng
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      if (isLoggedIn) {
        final String? role = await Auth.getRole();
        if (role == 'Admin' || role == 'Staff' || role == 'Technician') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Màn hình chờ trong lúc kiểm tra
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
