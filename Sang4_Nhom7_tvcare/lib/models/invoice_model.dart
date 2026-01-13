class Invoice {
  final int id;
  final int repairOrderId;
  final String? customerName;
  final double? totalAmount;
  final DateTime? invoiceDate;
  final String imagePath;
  final String? status; // Assuming the backend provides a status

  Invoice({
    required this.id,
    required this.repairOrderId,
    this.customerName,
    this.totalAmount,
    this.invoiceDate,
    required this.imagePath,
    this.status,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      repairOrderId: json['repairOrderId'],
      customerName: json['customerName'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      invoiceDate: json['invoiceDate'] != null ? DateTime.tryParse(json['invoiceDate']) : null,
      imagePath: json['imagePath'],
      status: json['status'],
    );
  }
}
