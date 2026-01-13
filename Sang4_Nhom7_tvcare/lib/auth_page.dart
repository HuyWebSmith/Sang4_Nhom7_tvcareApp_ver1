import 'package:flutter/material.dart';
import 'package:tvcare_flutter/services/auth.dart';
import 'package:tvcare_flutter/services/google_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isCustomer = true; 
  bool _isLogin = true;    
  bool _isLoading = false;  
  bool _obscurePassword = true;

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController(); 
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<String> _employeeRoles = ['admin', 'staff', 'technician'];

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    bool loggedIn = await Auth.isLoggedIn();
    if (loggedIn) {
      String? role = await Auth.getRole();
      if (mounted) {
        if (role?.toLowerCase() == 'admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
        } else if (role?.toLowerCase() == 'staff') {
          Navigator.pushNamedAndRemoveUntil(context, '/staff-repairs', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); 
        }
      }
    }
  }

  // LUỒNG ĐĂNG NHẬP GOOGLE CHUẨN - KHÔNG DÙNG CHUNG VỚI ĐĂNG NHẬP THƯỜNG
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _googleAuthService.signInWithGoogle();
      
      if (userCredential != null && userCredential.user != null) {
        final googleUser = userCredential.user!;
        
        // 1. Lấy thông tin từ Google
        final email = googleUser.email ?? "";
        final displayName = googleUser.displayName ?? email;
        final idToken = await googleUser.getIdToken() ?? "";

        // 2. Gửi thông tin lên Backend xử lý riêng (Tự gán User Role, lấy Email làm Username)
        final result = await Auth.loginWithGoogle(
          email: email,
          displayName: displayName,
          idToken: idToken,
        );

        if (result['success'] == true) {
          _showSnackBar('Đăng nhập Google thành công!', Colors.green);
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else {
          _showSnackBar(result['message'] ?? 'Lỗi xác thực hệ thống', Colors.redAccent);
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi Google: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_isLogin) {
          final result = await Auth.login(_usernameController.text.trim(), _passwordController.text);
          if (result['success'] == true) {
            String? role = await Auth.getRole();
            bool isEmployee = _employeeRoles.contains(role?.toLowerCase());
            if (_isCustomer && isEmployee) {
              _showSnackBar('Vui lòng đăng nhập ở tab Nhân viên!', Colors.orange);
              await Auth.logout();
            } else {
              if (mounted) {
                if (role?.toLowerCase() == 'admin') {
                  Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
                } else if (role?.toLowerCase() == 'staff') {
                  Navigator.pushNamedAndRemoveUntil(context, '/staff-repairs', (route) => false);
                } else {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              }
            }
          } else {
            _showSnackBar(result['message'] ?? 'Đăng nhập thất bại', Colors.redAccent);
          }
        } else {
          final result = await Auth.register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: "User",
          );
          if (result['success'] == true) {
            _showSnackBar('Đăng ký thành công!', Colors.green);
            setState(() => _isLogin = true);
          } else {
            _showSnackBar(result['message'] ?? 'Đăng ký thất bại', Colors.redAccent);
          }
        }
      } catch (e) {
        _showSnackBar('Lỗi hệ thống: $e', Colors.redAccent);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                const Icon(Icons.tv_rounded, size: 60, color: Color(0xFF0D47A1)),
                const SizedBox(height: 12),
                const Text('TVCARE SYSTEM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), letterSpacing: 1.5)),
                const SizedBox(height: 40),
                _buildRoleSelector(),
                const SizedBox(height: 30),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _roleTab('Khách hàng', Icons.person_outline, _isCustomer, () => setState(() => _isCustomer = true)),
          _roleTab('Nhân viên', Icons.badge_outlined, !_isCustomer, () => setState(() => _isCustomer = false)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField('Tên đăng nhập', _usernameController, Icons.person_outline),
            const SizedBox(height: 16),
            if (!_isLogin && _isCustomer) ...[
              _buildTextField('Email', _emailController, Icons.alternate_email),
              const SizedBox(height: 16),
            ],
            _buildTextField('Mật khẩu', _passwordController, Icons.lock_outline, isPassword: _obscurePassword),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleAuth,
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ'),
              ),
            ),
            if (_isCustomer && _isLogin) ...[
              const SizedBox(height: 16),
              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('HOẶC', style: TextStyle(color: Colors.grey, fontSize: 12))), Expanded(child: Divider())]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_"G"_logo.svg/1200px-Google_"G"_logo.svg.png', height: 24),
                  label: const Text('Tiếp tục với Google'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Chưa có tài khoản? Đăng ký ngay' : 'Đã có tài khoản? Đăng nhập')),
          ],
        ),
      ),
    );
  }

  Widget _roleTab(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(child: InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? const Color(0xFF0D47A1) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black54), const SizedBox(width: 8), Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87))]))));
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
    );
  }
}
