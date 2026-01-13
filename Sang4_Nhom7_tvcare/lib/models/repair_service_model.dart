class RepairService {
  final int id;
  final String serviceName;
  final String? description;
  final double estimatedPrice;
  bool isActive;

  RepairService({
    this.id = 0,
    required this.serviceName,
    this.description,
    required this.estimatedPrice,
    this.isActive = true,
  });

  factory RepairService.fromJson(Map<String, dynamic> json) {
    return RepairService(
      id: json['id'] ?? json['Id'] ?? 0,
      serviceName: json['serviceName'] ?? json['ServiceName'] ?? '',
      description: json['description'] ?? json['Description'],
      estimatedPrice: (json['estimatedPrice'] ?? json['EstimatedPrice'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? json['IsActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    "serviceName": serviceName,
    "description": description,
    "estimatedPrice": estimatedPrice,
    "isActive": isActive,
  };
}
