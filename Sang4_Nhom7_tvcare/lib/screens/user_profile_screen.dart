import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tvcare_flutter/screens/otp_input_screen.dart';
import '../services/profile_service.dart';
import '../models/user_profile_model.dart';
import '../services/auth.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải hồ sơ: $e')),
        );
      }
    }
  }

  Future<void> _startPhoneVerification() async {
    if (_isSendingOtp || _userProfile?.phoneNumber == null) return;
    setState(() => _isSendingOtp = true);

    String phoneNumber = _userProfile!.phoneNumber!;
    // Firebase requires the phone number in E.164 format (e.g., +84...)
    if (!phoneNumber.startsWith('+')) {
      if (phoneNumber.startsWith('0')) {
         phoneNumber = '+84${phoneNumber.substring(1)}';
      } else {
         phoneNumber = '+84$phoneNumber';
      }
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // This callback is for auto-retrieval, which might not happen on all devices.
        // We will primarily rely on user entering the code.
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isSendingOtp = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gửi OTP: ${e.message}')));
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        setState(() => _isSendingOtp = false);
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpInputScreen(
                verificationId: verificationId,
                phoneNumber: _userProfile!.phoneNumber!,
              ),
            ),
          );
          if (result == true) {
            _loadProfile(); // Refresh on success
          }
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Hồ sơ của tôi", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text("Không thể tải hồ sơ người dùng."))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildAvatar(),
                        const SizedBox(height: 16),
                        Text(_userProfile!.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 40),
                        _buildInfoCard(),
                        const SizedBox(height: 40),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: CircleAvatar(
        radius: 55,
        backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
        child: const Icon(Icons.person_rounded, size: 65, color: Color(0xFF0D47A1)),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          InfoTile(icon: Icons.person_outline, title: "Họ và tên", value: _userProfile!.fullName),
          const Divider(height: 1), 
          InfoTile(icon: Icons.email_outlined, title: "Email", value: _userProfile!.email ?? 'Chưa cập nhật'),
          const Divider(height: 1),
          InfoTile(icon: Icons.location_on_outlined, title: "Địa chỉ", value: _userProfile!.address ?? 'Chưa cập nhật'),
          const Divider(height: 1),
          _buildPhoneVerificationTile(),
        ],
      ),
    );
  }

  Widget _buildPhoneVerificationTile() {
    return ListTile(
      leading: Icon(
        _userProfile!.isPhoneVerified ? Icons.verified_user : Icons.phone_android,
        color: _userProfile!.isPhoneVerified ? Colors.green : Colors.orange,
      ),
      title: Text(_userProfile!.phoneNumber ?? 'Chưa cập nhật SĐT'),
      subtitle: Text(
        _userProfile!.isPhoneVerified ? 'Đã xác thực' : 'Chưa xác thực',
        style: TextStyle(color: _userProfile!.isPhoneVerified ? Colors.green : Colors.orange),
      ),
      trailing: !_userProfile!.isPhoneVerified
          ? ElevatedButton(
              onPressed: _isSendingOtp ? null : _startPhoneVerification,
              child: _isSendingOtp ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Xác thực'),
            )
          : null,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () async {
          await Auth.logout();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text("ĐĂNG XUẤT", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// Reusable info tile widget
class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}
