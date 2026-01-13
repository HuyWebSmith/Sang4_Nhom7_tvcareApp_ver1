class UserProfile {
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final bool isPhoneVerified;
  final String? avatarUrl;
  final String? address;

  UserProfile({
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.isPhoneVerified,
    this.avatarUrl,
    this.address,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      avatarUrl: json['avatarUrl'],
      address: json['address'],
    );
  }
}
