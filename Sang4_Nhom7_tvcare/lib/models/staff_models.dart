class StaffMember {
  final String userId;
  final String fullName;
  final String email;
  final bool isLocked;
  final int processedOrders;

  StaffMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.isLocked,
    this.processedOrders = 0,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      // Kiểm tra cả các trường viết hoa từ ASP.NET Identity
      userId: json['id']?.toString() ?? json['Id']?.toString() ?? json['userId']?.toString() ?? '',
      fullName: json['fullName'] ?? json['FullName'] ?? 'Không tên',
      email: json['email'] ?? json['Email'] ?? '',
      isLocked: json['isLocked'] ?? json['IsLocked'] ?? false,
      processedOrders: json['processedOrders'] ?? json['ProcessedOrders'] ?? 0,
    );
  }
}
