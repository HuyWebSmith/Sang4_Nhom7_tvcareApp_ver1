import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';

class PhoneVerifyScreen extends StatefulWidget {
  final String? phoneNumber;

  const PhoneVerifyScreen({super.key, this.phoneNumber});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    }
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;
    setState(() => _isSendingOtp = true);

    String phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+84')) {
      phoneNumber = '+84${phoneNumber.substring(1)}'; // Assuming 0 is the first digit
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval
        await FirebaseAuth.instance.signInWithCredential(credential);
        _verifyBackend();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isSendingOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gửi OTP: ${e.message}')));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isSendingOtp = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_isVerifyingOtp || _verificationId == null) return;
    setState(() => _isVerifyingOtp = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await _verifyBackend();
    } catch (e) {
      setState(() => _isVerifyingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã OTP không hợp lệ')));
    }
  }

  Future<void> _verifyBackend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isVerifyingOtp = false);
      return;
    }

    final success = await _profileService.verifyPhone(user.uid);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xác thực thành công!')));
        Navigator.pop(context, true);
      } else {
        setState(() => _isVerifyingOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật hồ sơ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực số điện thoại')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_verificationId == null)
              _buildPhoneInput(),
            if (_verificationId != null)
              _buildOtpInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Số điện thoại'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isSendingOtp ? null : _sendOtp,
          child: _isSendingOtp ? const CircularProgressIndicator() : const Text('Gửi mã OTP'),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        TextField(
          controller: _otpController,
          decoration: const InputDecoration(labelText: 'Mã OTP'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isVerifyingOtp ? null : _verifyOtp,
          child: _isVerifyingOtp ? const CircularProgressIndicator() : const Text('Xác nhận'),
        ),
      ],
    );
  }
}
