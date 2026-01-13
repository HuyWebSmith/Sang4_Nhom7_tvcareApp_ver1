
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
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentCenter;
  String _currentAddress = "Đang tải...";
  bool _isLoading = true;
  Timer? _debounce;
  List<Location> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _setDefaultLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setDefaultLocation() async {
    LatLng defaultLocation = LatLng(10.762622, 106.660172); // Trung tâm TPHCM
    try {
      // Thử lấy vị trí hiện tại của user để có trải nghiệm tốt hơn
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      defaultLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Nếu không được thì dùng vị trí mặc định
      print("Không thể lấy vị trí hiện tại: $e");
    }
    setState(() {
      _currentCenter = defaultLocation;
      _isLoading = false;
    });
    _mapController.move(defaultLocation, 15.0);
    _getAddressFromLatLng(defaultLocation);
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
    if (hasGesture) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        final center = camera.center;
        if (center != null) {
          setState(() {
            _currentCenter = center;
            _currentAddress = "Đang tìm địa chỉ...";
          });
          _getAddressFromLatLng(center);
        }
      });
    }
  }

  Future<void> _searchLocation(String address) async {
    if (address.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    try {
      List<Location> locations = await locationFromAddress(address);
      setState(() {
        _searchResults = locations;
      });
    } catch (e) {
      print("Lỗi tìm kiếm: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn địa chỉ"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter ?? LatLng(10.762622, 106.660172),
                    initialZoom: 15.0,
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
                // Search UI
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  child: Column(
                    children: [
                      Card(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm địa chỉ...',
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _isSearching = false;
                                });
                              },
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _isSearching = true;
                              });
                              _searchLocation(value);
                            } else {
                              setState(() {
                                _isSearching = false;
                                _searchResults = [];
                              });
                            }
                          },
                        ),
                      ),
                      if (_isSearching && _searchResults.isNotEmpty)
                        Card(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final location = _searchResults[index];
                              return ListTile(
                                title: FutureBuilder<Placemark>(
                                  future: _getPlacemark(location),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final p = snapshot.data!;
                                      return Text("${p.street}, ${p.subLocality}, ${p.locality}");
                                    }
                                    return Text("Đang tải...");
                                  },
                                ),
                                onTap: () {
                                  final newPos = LatLng(location.latitude, location.longitude);
                                  _mapController.move(newPos, 17.0);
                                  setState(() {
                                    _currentCenter = newPos;
                                    _searchResults = [];
                                    _isSearching = false;
                                    _searchController.clear();
                                  });
                                  _getAddressFromLatLng(newPos);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Confirmation Card
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

  Future<Placemark> _getPlacemark(Location location) async {
    final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
    return placemarks.first;
  }
}
