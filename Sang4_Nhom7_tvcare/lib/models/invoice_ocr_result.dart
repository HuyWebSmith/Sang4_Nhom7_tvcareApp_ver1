import 'package:intl/intl.dart';

class InvoiceOcrResult {
  String customerName;
  // ADDED: Email field
  String email;
  String service;
  double? totalAmount;
  DateTime? invoiceDate;

  InvoiceOcrResult({
    this.customerName = '',
    this.email = '', // Initialize email
    this.service = '',
    this.totalAmount,
    this.invoiceDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'email': email, // Add email to JSON
      'service': service,
      'totalAmount': totalAmount,
      'invoiceDate': invoiceDate != null ? DateFormat('yyyy-MM-dd').format(invoiceDate!) : null,
    };
  }
}
