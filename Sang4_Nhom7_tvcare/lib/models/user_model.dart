class UserModel {
  final String id;
  final String fullName;
  final String? email;
  final String? role;

  UserModel({required this.id, required this.fullName, this.email, this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      // Sửa lỗi: Cung cấp giá trị mặc định nếu fullName là null
      fullName: json['fullName']?.toString() ?? 'Chưa có tên',
      email: json['email'] as String?,
      role: json['role'] as String?,
    );
  }
}
