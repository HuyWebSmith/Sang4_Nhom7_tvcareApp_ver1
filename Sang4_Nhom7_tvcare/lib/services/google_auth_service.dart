import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // ÉP BUỘC HIỆN BẢNG CHỌN TÀI KHOẢN:
      // Bước 1: Đăng xuất GoogleSignIn cũ (nếu có) để xóa session cũ
      await _googleSignIn.signOut();

      // Bước 2: Khởi chạy luồng đăng nhập
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      // 2. Lấy chi tiết xác thực
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Tạo credential cho Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Đăng nhập vào Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Lỗi Google Sign-In: $e");
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Lỗi Sign-Out: $e");
    }
  }
}
