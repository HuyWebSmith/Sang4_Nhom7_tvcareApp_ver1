import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/repair_location.dart';
import '../services/location_service.dart';
import '../services/repair_api_service.dart';
import '../services/routing_service.dart';

class StaffNavigationMapPage extends StatefulWidget {
  final int orderId;

  const StaffNavigationMapPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<StaffNavigationMapPage> createState() => _StaffNavigationMapPageState();
}

class _StaffNavigationMapPageState extends State<StaffNavigationMapPage> {
  final RepairApiService _repairApiService = RepairApiService();
  final LocationService _locationService = LocationService();
  final RoutingService _routingService = RoutingService();

  Future<RepairLocation>? _initializationFuture;
  RepairLocation? _repairLocation;
  LatLng? _staffPosition;
  List<LatLng> _routePoints = [];
  double _distance = 0.0;
  double _duration = 0.0;
  StreamSubscription<Position>? _positionSubscription;
  final MapController _mapController = MapController();

  // State for auto-following GPS location
  bool _isAutoFollowing = true;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  Future<RepairLocation> _initialize() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Vui lòng bật GPS để tiếp tục.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Vui lòng cấp quyền truy cập vị trí.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Quyền truy cập vị trí đã bị từ chối vĩnh viễn. Vui lòng vào cài đặt ứng dụng để cấp quyền.');
    }
    
    try {
      _repairLocation = await _repairApiService.getRepairLocation(widget.orderId);
      _startListeningToLocation();
      return _repairLocation!;
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  void _startListeningToLocation() {
    _positionSubscription = _locationService.getPositionStream().listen((Position position) {
      if (!mounted) return;
      final newStaffPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _staffPosition = newStaffPosition;
      });

      if (_repairLocation != null) {
          final customerPosition = LatLng(_repairLocation!.latitude, _repairLocation!.longitude);
          _updateRoute(newStaffPosition, customerPosition);
      }

      if (_isAutoFollowing) {
        try {
          _mapController.move(newStaffPosition, 15.0);
        } catch (e) {
          // Map might not be ready yet
        }
      }
    });
  }

  Future<void> _updateRoute(LatLng start, LatLng end) async {
    if (start.latitude == 0 && start.longitude == 0) {
      return; 
    }
    try {
      final routeData = await _routingService.getRoute(start, end);
      if (mounted && routeData != null) {
        setState(() {
          _routePoints = routeData['points'] as List<LatLng>;
          _distance = routeData['distance'] as double;
          _duration = routeData['duration'] as double;
        });
      }
    } catch (e) {
      // Silently fail on route updates
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉ đường'),
      ),
      body: FutureBuilder<RepairLocation>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Lỗi: ${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      onPressed: () {
                        setState(() {
                          _initializationFuture = _initialize();
                        });
                      },
                    )
                  ],
                ),
              ),
            );
          }
          
          if (_staffPosition == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Đang chờ tín hiệu GPS...", style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return _buildMap(snapshot.data!);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_staffPosition != null) {
            _mapController.move(_staffPosition!, 15.0);
            setState(() {
              _isAutoFollowing = true; // Bật lại chế độ auto-follow
            });
          }
        },
        // Thay đổi màu sắc của nút dựa trên trạng thái auto-follow
        backgroundColor: _isAutoFollowing ? Theme.of(context).primaryColor : Colors.grey,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildMap(RepairLocation repairLocation) {
    final customerPosition = LatLng(repairLocation.latitude, repairLocation.longitude);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _staffPosition!, 
            initialZoom: 15.0,
            // Phát hiện khi người dùng tương tác với bản đồ
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _isAutoFollowing = false; // Tắt auto-follow
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            PolylineLayer(
              polylines: [
                Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.blueAccent),
              ],
            ),
            MarkerLayer(
              markers: [
                if (_staffPosition != null)
                  Marker(
                    point: _staffPosition!,
                    child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                  ),
                Marker(
                  point: customerPosition,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khách hàng: ${repairLocation.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 16),
                  Text('Địa chỉ: ${repairLocation.address}'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse('tel:${repairLocation.phoneNumber}')),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          repairLocation.phoneNumber,
                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(Icons.drive_eta_rounded, '${(_distance / 1000).toStringAsFixed(1)} km'),
                      _buildInfoChip(Icons.timer_rounded, '${(_duration / 60).toStringAsFixed(0)} phút'),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Theme.of(context).primaryColor),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.grey[200],
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
