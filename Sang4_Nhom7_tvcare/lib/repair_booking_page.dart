import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:tvcare_flutter/screens/location_picker_screen.dart';
import 'services/repair_booking_service.dart';
import 'models/repair_models.dart';
import 'package:intl/intl.dart';

class RepairBookingPage extends StatefulWidget {
  const RepairBookingPage({super.key});

  @override
  State<RepairBookingPage> createState() => _RepairBookingPageState();
}

class _RepairBookingPageState extends State<RepairBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final RepairBookingService _service = RepairBookingService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();

  List<RepairService> _services = [];
  int? _selectedServiceId;
  DateTime? _selectedDate;
  double? _latitude;
  double? _longitude;
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final data = await _service.getActiveServices();
      setState(() {
        _services = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      if (!mounted) return;
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn dịch vụ")));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn thời gian")));
      return;
    }

    setState(() => _isBooking = true);
    try {
      final dto = CreateRepairOrderDto(
        repairServiceId: _selectedServiceId!,
        customerName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        issueDescription: _descController.text.trim(),
        repairDate: _selectedDate!,
        latitude: _latitude,
        longitude: _longitude,
      );

      final success = await _service.createRepairBooking(dto);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đặt lịch thành công!")));
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đặt lịch thất bại")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Đặt lịch sửa TV', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Thông tin khách hàng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Họ và tên", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Vui lòng nhập tên" : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder()),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty ? "Vui lòng nhập SĐT" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty ? "Vui lòng nhập Email" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: "Địa chỉ sửa chữa", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Vui lòng nhập địa chỉ" : null,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
                        );
                        if (result != null && result is Map) {
                          final latlng = result['latlng'] as LatLng;
                          final address = result['address'] as String;
                          setState(() {
                            _addressController.text = address;
                            _latitude = latlng.latitude;
                            _longitude = latlng.longitude;
                          });
                        }
                      },
                      icon: const Icon(Icons.map),
                      label: const Text("Chọn trên bản đồ"),
                    ),
                    const SizedBox(height: 24),
                    const Text("Chọn loại dịch vụ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _services.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final s = _services[index];
                        final isSelected = _selectedServiceId == s.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedServiceId = s.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(s.serviceName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    if (isSelected) const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                                  ],
                                ),
                                Text(currencyFormat.format(s.estimatedPrice), style: const TextStyle(color: Colors.blue)),
                                if (s.description != null) Text(s.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text("Mô tả lỗi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "TV bị sọc màn hình, không lên nguồn..."),
                      validator: (v) => v!.isEmpty ? "Vui lòng mô tả lỗi" : null,
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month)),
                        child: Text(_selectedDate == null ? "Chọn ngày và giờ hẹn" : DateFormat('HH:mm - dd/MM/yyyy').format(_selectedDate!)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isBooking ? null : _submitBooking,
                        child: _isBooking ? const CircularProgressIndicator(color: Colors.white) : const Text("XÁC NHẬN ĐẶT LỊCH"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
