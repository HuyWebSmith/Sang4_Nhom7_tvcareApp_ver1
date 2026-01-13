import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvcare_flutter/screens/staff_pending_repairs_page.dart';
import 'firebase_options.dart';
import 'tv_list_page.dart';
import 'tv_detail_page.dart';
import 'repair_service_page.dart';
import 'auth_page.dart';
import 'registration_screen.dart';
import 'admin_screen.dart';
import 'repair_booking_page.dart';
import 'services/product_service.dart';
import 'models/tv_models.dart';
import 'screens/admin/product_management_screen.dart';
import 'screens/user_repair_orders_screen.dart';
import 'screens/staff_repair_management_screen.dart';
import 'screens/user_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file: $e");
  }
  runApp(const TVCareApp());
}

class TVCareApp extends StatelessWidget {
  const TVCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Care - Chuyên gia Tivi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF00B0FF),
          surface: const Color(0xFFF8FAFC),
          background: const Color(0xFFF8FAFC),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/login': (context) => const AuthPage(),
        '/register': (context) => const RegistrationScreen(),
        '/admin': (context) => const AdminScreen(),
        '/admin/products': (context) => const ProductManagementScreen(),
        '/': (context) => const HomePage(),
        '/tv-list': (context) => const TVListPage(),
        '/repair-services': (context) => const RepairServicePage(),
        '/book-repair': (context) => const RepairBookingPage(),
        '/my-repairs': (context) => const UserRepairOrdersScreen(),
        '/staff-repairs': (context) => const StaffRepairManagementScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/staff-pending-repairs': (context) => const StaffPendingRepairsPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductService _productService = ProductService();
  List<ProductListItem> _featuredProducts = [];
  bool _isLoadingProducts = true;
  String? username;
  String? role;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchFeaturedProducts();
  }

  Future<void> _fetchFeaturedProducts() async {
    try {
      setState(() => _isLoadingProducts = true);
      final products = await _productService.getProducts(limit: 5);
      setState(() {
        _featuredProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
      debugPrint("Failed to load featured products: $e");
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      setState(() {
        username = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
            decodedToken['unique_name'] ?? 'User';
        role = (decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
            decodedToken['role'])?.toString();
      });
    } else {
      setState(() => username = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildHeader(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchFeaturedProducts();
          await _loadUserInfo();
        },
        child: SingleChildScrollView(
          child: Column(children: [
            _buildHeroBanner(context),
            _buildServicesSection(context),
            _buildFeaturedTVs(context),
          ]),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      title: const Text('TV Care', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: Theme.of(context).colorScheme.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        _buildUserAction(context),
      ],
    );
  }

  Widget _buildUserAction(BuildContext context) {
    if (username == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: FilledButton(onPressed: () async {
          final result = await Navigator.pushNamed(context, '/login');
          if (result == true) {
            _loadUserInfo();
          }
        }, child: const Text('Đăng nhập')),
      );
    }
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'logout') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('jwt_token');
          _loadUserInfo();
        } else if (value == 'profile') {
          Navigator.pushNamed(context, '/profile');
        } else if (value == 'my-repairs') {
          Navigator.pushNamed(context, '/my-repairs');
        } else if (value == 'admin') {
          Navigator.pushNamed(context, '/admin');
        } else if (value == 'staff-repairs') {
          Navigator.pushNamed(context, '/staff-repairs');
        }
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> items = [
          PopupMenuItem<String>(
            value: 'profile',
            child: Text('Xin chào, $username'),
          ),
          const PopupMenuItem<String>(
            value: 'my-repairs',
            child: Text('Lịch sử sửa chữa'),
          ),
        ];

        if (role == 'Admin') {
          items.add(const PopupMenuItem<String>(
            value: 'admin',
            child: Text('Trang Admin'),
          ));
        }

        if (role == 'Staff') {
          items.add(const PopupMenuItem<String>(
            value: 'staff-repairs',
            child: Text('Quản lý sửa chữa'),
          ));
        }

        items.add(const PopupMenuDivider());
        items.add(const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Đăng xuất'),
        ));

        return items;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Chip(
          avatar: CircleAvatar(child: Text(username![0].toUpperCase())),
          label: Text(username!),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      height: 350,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuyên gia sửa chữa & mua bán Tivi',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.5))],
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dịch vụ chuyên nghiệp, uy tín, giá cả cạnh tranh. \nGọi ngay để được tư vấn!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 5.0, color: Colors.black.withOpacity(0.5))],
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.build),
                  label: const Text('Đặt lịch sửa chữa'),
                  onPressed: () => Navigator.pushNamed(context, '/book-repair'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dịch vụ của chúng tôi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildServiceCard(
                context,
                icon: Icons.tv,
                label: 'Mua bán TV',
                onTap: () => Navigator.pushNamed(context, '/tv-list'),
              ),
              _buildServiceCard(
                context,
                icon: Icons.build_circle_outlined,
                label: 'Sửa chữa TV',
                onTap: () => Navigator.pushNamed(context, '/repair-services'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 150,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedTVs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tivi nổi bật',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/tv-list'),
                child: const Text('Xem tất cả'),
              )
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _featuredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _featuredProducts[index];
                      return _buildProductCard(context, product);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductListItem product) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TVDetailPage(productId: product.productId),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(right: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                        )
                      : Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.tv, size: 50, color: Colors.grey)))),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  currencyFormat.format(product.price),
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
