import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tvcare_flutter/models/invoice_ocr_result.dart';
import 'package:tvcare_flutter/services/invoice_service.dart';
import 'package:tvcare_flutter/services/ocr_service.dart';

class InvoiceUploadScreen extends StatefulWidget {
  final int repairOrderId;

  const InvoiceUploadScreen({Key? key, required this.repairOrderId}) : super(key: key);

  @override
  _InvoiceUploadScreenState createState() => _InvoiceUploadScreenState();
}

class _InvoiceUploadScreenState extends State<InvoiceUploadScreen> {
  final OcrService _ocrService = OcrService();
  final InvoiceService _invoiceService = InvoiceService();
  final ImagePicker _picker = ImagePicker();

  XFile? _imageFile;
  InvoiceOcrResult _ocrResult = InvoiceOcrResult();
  bool _isProcessingOcr = false;
  bool _isUploading = false;

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Controller for email
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    _emailController.dispose();
    _serviceController.dispose();
    _totalAmountController.dispose();
    _invoiceDateController.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _isProcessingOcr = true;
        _clearForm();
      });

      try {
        final String recognizedText = await _ocrService.recogniseText(File(pickedFile.path));
        _parseOcrText(recognizedText);
      } catch (e) {
        _showError("Lỗi OCR: ${e.toString()}");
      } finally {
        if(mounted) {
          setState(() {
            _isProcessingOcr = false;
          });
        }
      }
    }
  }

  void _parseOcrText(String text) {
    // Basic parsing logic. This should be expanded with more robust regex.
    setState(() {
      _ocrResult = InvoiceOcrResult(service: text); // Simple assignment for demo
      _updateControllers();
    });
  }

  void _clearForm() {
    _customerNameController.clear();
    _emailController.clear();
    _serviceController.clear();
    _totalAmountController.clear();
    _invoiceDateController.clear();
  }

  void _updateControllers() {
    _customerNameController.text = _ocrResult.customerName;
    _emailController.text = _ocrResult.email;
    _serviceController.text = _ocrResult.service;
    _totalAmountController.text = _ocrResult.totalAmount?.toStringAsFixed(0) ?? '';
    if (_ocrResult.invoiceDate != null) {
      _invoiceDateController.text = DateFormat('yyyy-MM-dd').format(_ocrResult.invoiceDate!);
    } else {
      _invoiceDateController.text = '';
    }
  }

  Future<void> _handleUpload() async {
    if (_imageFile == null) {
      _showError("Vui lòng chọn ảnh hóa đơn.");
      return;
    }
    
    // Basic email validation
    if (!_emailController.text.contains('@')) {
      _showError("Email không hợp lệ.");
      return;
    }

    setState(() => _isUploading = true);

    try {
      final finalResult = InvoiceOcrResult(
        customerName: _customerNameController.text.trim(),
        email: _emailController.text.trim(),
        service: _serviceController.text.trim(),
        totalAmount: double.tryParse(_totalAmountController.text),
        invoiceDate: DateTime.tryParse(_invoiceDateController.text),
      );

      final success = await _invoiceService.uploadInvoice(
        repairOrderId: widget.repairOrderId,
        imageFile: File(_imageFile!.path),
        ocrResult: finalResult,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload hóa đơn thành công!"), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else {
        _showError("Upload thất bại. Vui lòng thử lại.");
      }
    } catch (e) {
      _showError("Lỗi upload: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
        title: const Text("Upload Hóa Đơn"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 24),
            if (_isProcessingOcr)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
            if (_imageFile != null && !_isProcessingOcr)
              _buildOcrResultForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    // ... (same as before) ...
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _imageFile != null
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_imageFile!.path), fit: BoxFit.cover))
              : const Center(child: Text("Chưa có ảnh nào được chọn", style: TextStyle(color: Colors.grey)))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : () => _pickAndProcessImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Chụp ảnh"),
            ),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : () => _pickAndProcessImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text("Chọn từ thư viện"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOcrResultForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Kiểm tra và điền thông tin hóa đơn", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.black54)),
        const Divider(height: 24),
        TextFormField(
          controller: _customerNameController,
          decoration: const InputDecoration(labelText: "Tên khách hàng", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        // ADDED: Email input field
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: "Email khách hàng để gửi hóa đơn", border: OutlineInputBorder()),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _serviceController,
          decoration: const InputDecoration(labelText: "Dịch vụ/Nội dung", border: OutlineInputBorder()),
          maxLines: 5,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _totalAmountController,
                decoration: const InputDecoration(labelText: "Tổng tiền", border: OutlineInputBorder(), suffixText: "VNĐ"),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _invoiceDateController,
                decoration: const InputDecoration(labelText: "Ngày hóa đơn", border: OutlineInputBorder(), hintText: "yyyy-MM-dd"),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    _invoiceDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _handleUpload,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: _isUploading
              ? const Text("ĐANG UPLOAD...")
              : const Text("XÁC NHẬN VÀ UPLOAD"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
