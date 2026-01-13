import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';

class OtpInputScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpInputScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpInputScreen> createState() => _OtpInputScreenState();
}

class _OtpInputScreenState extends State<OtpInputScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      await _verifyBackend();

    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã OTP không hợp lệ hoặc đã hết hạn.')),
        );
      }
    }
  }

  Future<void> _verifyBackend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi xác thực Firebase, vui lòng thử lại.')),
        );
      }
      return;
    }

    final success = await _profileService.verifyPhone(user.uid);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực số điện thoại thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); 
      } else {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi cập nhật hồ sơ trên hệ thống.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập mã xác thực'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Một mã OTP gồm 6 chữ số đã được gửi đến số điện thoại:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.phoneNumber,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Mã OTP',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('XÁC NHẬN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
