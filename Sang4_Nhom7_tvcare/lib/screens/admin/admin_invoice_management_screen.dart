import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tvcare_flutter/models/invoice_model.dart';
import 'package:tvcare_flutter/services/admin_invoice_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminInvoiceManagementScreen extends StatefulWidget {
  const AdminInvoiceManagementScreen({super.key});

  @override
  State<AdminInvoiceManagementScreen> createState() => _AdminInvoiceManagementScreenState();
}

class _AdminInvoiceManagementScreenState extends State<AdminInvoiceManagementScreen> {
  final AdminInvoiceService _service = AdminInvoiceService();
  Future<List<Invoice>>? _invoicesFuture;

  // Get the base URL, but remove the '/api/' part for displaying images
  final String _baseImageUrl = dotenv.env['BASE_URL']!.replaceAll('api/', '');

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  void _fetchInvoices() {
    setState(() {
      _invoicesFuture = _service.getInvoices();
    });
  }

  Future<void> _approveInvoice(int invoiceId) async {
    try {
      final success = await _service.approveInvoice(invoiceId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt hóa đơn và gửi email thành công!'), backgroundColor: Colors.green),
        );
        _fetchInvoices(); // Refresh the list
      } else {
        _showError('Duyệt hóa đơn thất bại.');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _viewImage(String imagePath) async {
    final Uri url = Uri.parse('$_baseImageUrl$imagePath');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showError('Không thể mở ảnh: $url');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInvoices,
          ),
        ],
      ),
      body: FutureBuilder<List<Invoice>>(
        future: _invoicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Lỗi tải danh sách hóa đơn: ${snapshot.error}'),
              ),
            );
          }

          final invoices = snapshot.data;
          if (invoices == null || invoices.isEmpty) {
            return const Center(child: Text('Không có hóa đơn nào cần duyệt.'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [DataTable(
                  columns: const [
                    DataColumn(label: Text('Khách hàng')),
                    DataColumn(label: Text('Tổng tiền')),
                    DataColumn(label: Text('Ngày HĐ')),
                    DataColumn(label: Text('Ảnh')),
                    DataColumn(label: Text('Hành động')),
                  ],
                  rows: invoices.map((invoice) {
                    return DataRow(cells: [
                      DataCell(Text(invoice.customerName ?? 'N/A')),
                      DataCell(Text(NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(invoice.totalAmount ?? 0))),
                      DataCell(Text(invoice.invoiceDate != null ? DateFormat('dd/MM/yyyy').format(invoice.invoiceDate!) : 'N/A')),
                      DataCell(IconButton(
                        icon: const Icon(Icons.image, color: Colors.blue),
                        onPressed: () => _viewImage(invoice.imagePath),
                      )),
                      DataCell(ElevatedButton(
                        onPressed: () => _approveInvoice(invoice.id),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Duyệt & Gửi Mail'),
                      )),
                    ]);
                  }).toList(),
                )],
              ),
            ),
          );
        },
      ),
    );
  }
}
