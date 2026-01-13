
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentCenter;
  String _currentAddress = "Di chuyển bản đồ để chọn...";
  bool _isLoading = true;
  LatLng? _initialPosition;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _currentCenter = _initialPosition;
        _isLoading = false;
      });
      _getAddressFromLatLng(_currentCenter!);
    } catch (e) {
      // Handle case where location cannot be determined, center on a default location
      setState(() {
        _initialPosition = LatLng(10.762622, 106.660172); // Default to HCMC
        _currentCenter = _initialPosition;
        _isLoading = false;
      });
      _getAddressFromLatLng(_currentCenter!);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _currentAddress = "${p.street}, ${p.subLocality}, ${p.locality}, ${p.country}";
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Không thể tìm thấy địa chỉ.";
      });
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final center = camera.center;
      if(center != null) {
        _getAddressFromLatLng(center);
        setState(() {
          _currentCenter = center;
        });
       }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn địa chỉ của bạn"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialPosition!,
                    initialZoom: 17.0,
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                  ],
                ),
                const Center(
                  child: Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Card(
                    margin: const EdgeInsets.all(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentAddress,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_currentCenter != null) {
                                Navigator.of(context).pop({
                                  'latlng': _currentCenter,
                                  'address': _currentAddress,
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text("Xác nhận địa chỉ này"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
