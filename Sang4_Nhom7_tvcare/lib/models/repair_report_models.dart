class RepairReportItem {
  final int id;
  final String userName;
  final String? staffName;
  final String serviceName;
  final DateTime repairDate;
  final String status;

  RepairReportItem({
    required this.id,
    required this.userName,
    this.staffName,
    required this.serviceName,
    required this.repairDate,
    required this.status,
  });

  factory RepairReportItem.fromJson(Map<String, dynamic> json) {
    return RepairReportItem(
      id: json['id'] ?? json['Id'] ?? 0,
      userName: json['userName'] ?? json['UserName'] ?? '',
      staffName: json['staffName'] ?? json['StaffName'],
      serviceName: json['serviceName'] ?? json['ServiceName'] ?? '',
      repairDate: DateTime.parse(json['repairDate'] ?? json['RepairDate']),
      status: json['status'] ?? json['Status'] ?? 'Pending',
    );
  }
}
