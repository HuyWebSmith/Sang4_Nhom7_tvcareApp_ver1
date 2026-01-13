class CustomerLocation {
  final int id;
  final double latitude;
  final double longitude;
  final String address;
  final String customerName;
  final String phoneNumber;

  CustomerLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.customerName,
    required this.phoneNumber,
  });

  factory CustomerLocation.fromJson(Map<String, dynamic> json) {
    return CustomerLocation(
      id: json['id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      customerName: json['customerName'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
