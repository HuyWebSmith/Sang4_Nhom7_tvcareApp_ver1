import 'package:flutter/material.dart';
import 'repair_booking_page.dart';

class RepairServicePage extends StatelessWidget {
  const RepairServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildHeader(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildRepairBanner(context),
            _buildCommonIssues(context),
            _buildPricingTable(context),
            _buildCTASection(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Row(
        children: [
          Icon(Icons.tv_rounded, color: Color(0xFF0D47A1), size: 28),
          SizedBox(width: 8),
          Text(
            'TVCARE REPAIR',
            style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.handyman_rounded, size: 64, color: Color(0xFF00B0FF)),
          const SizedBox(height: 24),
          const Text(
            'Dịch Vụ Sửa Chữa TV Chuyên Nghiệp',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Khắc phục mọi sự cố - Linh kiện chính hãng - Bảo hành dài hạn',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RepairBookingPage()));
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('ĐẶT LỊCH SỬA CHỮA NGAY'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00B0FF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonIssues(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          _buildSectionTitle('Các Lỗi Thường Gặp'),
          const SizedBox(height: 50),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _issueCard(Icons.power_off, 'Không lên nguồn', 'TV không có tín hiệu đèn nguồn, không khởi động được.'),
              _issueCard(Icons.grid_3x3, 'Sọc màn hình', 'Xuất hiện các đường kẻ dọc, ngang hoặc chồng ảnh.'),
              _issueCard(Icons.volume_off, 'Mất tiếng', 'Có hình nhưng không có âm thanh hoặc âm thanh bị rè.'),
              _issueCard(Icons.wifi_off, 'Lỗi kết nối', 'Không nhận wifi, không vào được ứng dụng thông minh.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _issueCard(IconData icon, String title, String desc) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFF0D47A1)),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPricingTable(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: screenWidth > 800 ? 100 : 20),
      child: Column(
        children: [
          _buildSectionTitle('Bảng Giá Tham Khảo'),
          const SizedBox(height: 20),
          const Text(
            '* Giá có thể thay đổi sau khi kỹ thuật viên kiểm tra trực tiếp tình trạng máy',
            style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _priceRow('Kiểm tra tại nhà', 'Miễn phí', true, isHeader: true),
                _priceRow('Sửa nguồn TV', '350.000đ - 800.000đ', false),
                _priceRow('Thay LED nền', '500.000đ - 1.500.000đ', true),
                _priceRow('Sửa bo mạch chính', '600.000đ - 2.000.000đ', false),
                _priceRow('Thay màn hình', 'Liên hệ báo giá', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String service, String price, bool isGrey, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: isGrey ? const Color(0xFFF8FAFC) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.w500, fontSize: 16)),
          Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          const Text('Sẵn sàng hồi sinh chiếc TV của bạn?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          SizedBox(
            width: 300,
            height: 60,
            child: FilledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RepairBookingPage()));
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
              child: const Text('ĐẶT LỊCH NGAY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(width: 60, height: 4, color: const Color(0xFF00B0FF)),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.all(40),
      child: const Text(
        '© 2024 TVCare Repair Service. Tất cả quyền được bảo lưu.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
