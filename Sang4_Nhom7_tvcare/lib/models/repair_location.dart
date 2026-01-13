class RepairLocation {
  final int id;
  final double latitude;
  final double longitude;
  final String address;
  final String customerName;
  final String phoneNumber;

  RepairLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.customerName,
    required this.phoneNumber,
  });

  factory RepairLocation.fromJson(Map<String, dynamic> json) {
    return RepairLocation(
      id: json['id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      customerName: json['customerName'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }
}
