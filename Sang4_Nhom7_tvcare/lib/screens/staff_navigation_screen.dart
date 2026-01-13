import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tvcare_flutter/models/customer_location.dart';
import 'package:tvcare_flutter/services/api_client.dart';
import 'package:tvcare_flutter/services/routing_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class StaffNavigationScreen extends StatefulWidget {
  final int repairId;

  const StaffNavigationScreen({super.key, required this.repairId});

  @override
  State<StaffNavigationScreen> createState() => _StaffNavigationScreenState();
}

class _StaffNavigationScreenState extends State<StaffNavigationScreen> {
  final RoutingService _routingService = RoutingService();
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  LatLng? _staffPosition;
  CustomerLocation? _customerLocation;
  List<LatLng> _routePoints = [];
  double _distance = 0;
  double _duration = 0;

  bool _isLoading = true;
  String _errorMessage = '';

  // Threshold for re-fetching route in meters
  static const double _rerouteThreshold = 30.0;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    setState(() => _isLoading = true);
    try {
      _customerLocation = await ApiClient().getRepairLocation(widget.repairId);
      final initialPosition = await _determinePosition();
      _staffPosition = LatLng(initialPosition.latitude, initialPosition.longitude);

      await _fetchRoute();
      _startGpsListener();

    } catch (e) {
      developer.log(e.toString(), name: 'StaffNavigationScreen');
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRoute() async {
    if (_staffPosition == null || _customerLocation == null) return;

    final routeData = await _routingService.getRoute(
      _staffPosition!,
      LatLng(_customerLocation!.latitude, _customerLocation!.longitude),
    );

    if (mounted && routeData != null) {
      setState(() {
        _routePoints = routeData['points'] as List<LatLng>;
        _distance = routeData['distance'] as double;
        _duration = routeData['duration'] as double;
      });
    }
  }

  void _startGpsListener() {
    _positionStream = Geolocator.getPositionStream(locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // Update every 20 meters
    )).listen((Position position) async {
      if (!mounted) return;

      final newStaffPosition = LatLng(position.latitude, position.longitude);
      
      // Calculate distance from the last route calculation point
      final distance = Geolocator.distanceBetween(
        _staffPosition!.latitude,
        _staffPosition!.longitude,
        newStaffPosition.latitude,
        newStaffPosition.longitude,
      );

      // Update staff position on map
      setState(() {
         _staffPosition = newStaffPosition;
      });

      // Move map camera
      _mapController.move(newStaffPosition, _mapController.camera.zoom);
      
      // Re-fetch route if staff has moved significantly
      if (distance > _rerouteThreshold) {
        await _fetchRoute();
      }
    });
  }

  Future<Position> _determinePosition() async {
    // ... (permission logic remains the same)
    bool serviceEnabled; 
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _makePhoneCall() async {
    if (_customerLocation != null) {
      final Uri phoneUri = Uri(scheme: 'tel', path: _customerLocation!.phoneNumber);
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
           throw 'Could not launch $phoneUri';
        }
      } catch (e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not make phone call: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(body: Center(child: Text(_errorMessage, textAlign: TextAlign.center)));
    }
    
    if (_staffPosition == null || _customerLocation == null) {
        return const Scaffold(body: Center(child: Text('Could not get location data.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation to Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeNavigation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _staffPosition!,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 5),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Customer Marker
                  Marker(
                    point: LatLng(_customerLocation!.latitude, _customerLocation!.longitude),
                    child: const Icon(Icons.home, color: Colors.red, size: 30),
                  ),
                  // Staff Marker
                  if(_staffPosition != null)
                  Marker(
                    point: _staffPosition!,
                    child: const Icon(Icons.navigation, color: Colors.blue, size: 30),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Distance: ${(_distance / 1000).toStringAsFixed(2)} km',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('ETA: ${(_duration / 60).toStringAsFixed(0)} minutes',
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _makePhoneCall,
                      icon: const Icon(Icons.call),
                      label: const Text('Call Customer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
