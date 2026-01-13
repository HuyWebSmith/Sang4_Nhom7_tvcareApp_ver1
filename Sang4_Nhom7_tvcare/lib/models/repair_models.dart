import 'package:intl/intl.dart';

enum RepairStatus {
  Pending,     // 0
  Confirmed,   // 1
  Repairing,   // 2
  Done,        // 3
  Cancelled    // 4
}

class RepairService {
  final int id;
  final String serviceName;
  final double estimatedPrice;
  final String? description;
  final bool isActive;

  RepairService({
    required this.id,
    required this.serviceName,
    required this.estimatedPrice,
    this.description,
    required this.isActive,
  });

  factory RepairService.fromJson(Map<String, dynamic> json) {
    return RepairService(
      id: json['id'] ?? json['Id'] ?? 0,
      serviceName: json['serviceName'] ?? json['ServiceName'] ?? '',
      estimatedPrice: (json['estimatedPrice'] ?? json['EstimatedPrice'] ?? 0).toDouble(),
      description: json['description'] ?? json['Description'],
      isActive: json['isActive'] ?? json['IsActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'serviceName': serviceName,
    'estimatedPrice': estimatedPrice,
    'description': description,
    'isActive': isActive,
  };
}

class RepairOrder {
  final int id;
  final String customerName;
  final String phoneNumber;
  final String email;
  final String address;
  final String? issueDescription;
  final DateTime repairDate;
  RepairStatus status;
  final String serviceName;
  final String? staffName;
  // FIX: Change staffId to String? to match backend GUID
  final String? staffId;

  RepairOrder({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    this.issueDescription,
    required this.repairDate,
    required this.status,
    required this.serviceName,
    this.staffName,
    this.staffId,
  });

  factory RepairOrder.fromJson(Map<String, dynamic> json) {
    String? nameFromUser;
    final userObject = json['user'] ?? json['User'];
    if (userObject != null && userObject is Map) {
      nameFromUser = userObject['fullName']?.toString() ?? userObject['FullName']?.toString();
    }

    String? serviceNameFromService;
    final serviceObject = json['repairService'] ?? json['RepairService'];
    if (serviceObject != null && serviceObject is Map) {
      serviceNameFromService = serviceObject['serviceName']?.toString() ?? serviceObject['ServiceName']?.toString();
    }
    
    return RepairOrder(
      id: json['id'] ?? json['Id'] ?? 0,
      customerName: nameFromUser ?? json['customerName']?.toString() ?? json['CustomerName']?.toString() ?? 'N/A',
      phoneNumber: json['phoneNumber']?.toString() ?? json['PhoneNumber']?.toString() ?? 'N/A',
      email: json['email']?.toString() ?? json['Email']?.toString() ?? 'N/A',
      address: json['address']?.toString() ?? json['Address']?.toString() ?? 'N/A',
      issueDescription: json['issueDescription']?.toString() ?? json['IssueDescription']?.toString(),
      repairDate: DateTime.tryParse(json['repairDate']?.toString() ?? json['RepairDate']?.toString() ?? '') ?? DateTime.now(),
      status: RepairStatus.values[json['status'] ?? 0],
      serviceName: serviceNameFromService ?? 'Dịch vụ không xác định',
      // FIX: Parse staffId as a String
      staffId: json['staffId']?.toString(),
      staffName: (json['staff'] ?? json['Staff'])?['fullName']?.toString(),
    );
  }
}

class CreateRepairOrderDto {
  final int repairServiceId;
  final String customerName;
  final String phoneNumber;
  final String email;
  final String address;
  final String? issueDescription;
  final DateTime repairDate;
  final double? latitude;
  final double? longitude;

  CreateRepairOrderDto({
    required this.repairServiceId,
    required this.customerName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    this.issueDescription,
    required this.repairDate,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
    "repairServiceId": repairServiceId,
    "customerName": customerName,
    "phoneNumber": phoneNumber,
    "email": email,
    "address": address,
    "issueDescription": issueDescription,
    "repairDate": repairDate.toIso8601String(),
    "latitude": latitude,
    "longitude": longitude,
  };
}
