import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'address_details_screen.dart';
import 'home_screen.dart';

class LocationMapScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationMapScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(12.9716, 77.5946); // Default: Bangalore
  String _currentAddress = 'Fetching address...';
  String _currentLocality = 'Locating...';
  bool _isLoading = true;
  bool _isMapReady = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
    }
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (kIsWeb) {
      // Wait for a short duration on Web to ensure google.maps JS is fully evaluated
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (mounted) {
      if (widget.initialLat != null && widget.initialLng != null) {
        setState(() {
          _isMapReady = true;
          _isLoading = false;
        });
        _getAddressFromLatLng(_currentPosition);
      } else {
        await _getCurrentLocation();
        if (mounted) {
          setState(() {
            _isMapReady = true;
          });
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng loc = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _currentPosition = loc;
          _isLoading = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
        _getAddressFromLatLng(loc);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocality = place.locality ?? place.subLocality ?? 'Unknown Area';
          _currentAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Could not fetch address';
        _currentLocality = 'Unknown Area';
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentPosition = position.target;
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(_currentPosition);
  }

  Future<void> _confirmAndProceed() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('location_address', _currentAddress);
      await prefs.setString('location_locality', _currentLocality);
      await prefs.setDouble('location_lat', _currentPosition.latitude);
      await prefs.setDouble('location_lng', _currentPosition.longitude);

      final userId = prefs.getString('user_id');
      if (userId != null) {
        await ApiService.updateLocation(
          userId, 
          _currentAddress, 
          _currentPosition.latitude, 
          _currentPosition.longitude,
        );
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update location: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map View
          if (_isMapReady)
            GoogleMap(
              initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          )
          else
            const Center(child: CircularProgressIndicator()),

          // Custom Dark Mode styling would require styling json but we'll stick to normal MapType

          // Center Marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0), // offset for pin tip
              child: Image.network(
                'https://cdn-icons-png.flaticon.com/512/2776/2776067.png',
                width: 40,
                color: AppColors.primary,
              ),
            ),
          ),

          // Top Search Bar
          Positioned(
            top: 50,
            left: AppConstants.padding,
            right: AppConstants.padding,
            child: FadeInDown(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: TextField(
                        onSubmitted: (val) async {
                          if (val.trim().isEmpty) return;
                          try {
                            List<Location> locs = await locationFromAddress(val);
                            if (locs.isNotEmpty) {
                              LatLng newLoc = LatLng(locs.first.latitude, locs.first.longitude);
                              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLoc, 15));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Location not found'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search by area or building',
                          hintStyle: TextStyle(color: AppColors.textHint),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // "Current Location" Button
          Positioned(
            bottom: 200,
            right: AppConstants.padding,
            child: FloatingActionButton.extended(
              onPressed: _isLoading ? null : _getCurrentLocation,
              backgroundColor: AppColors.surface,
              icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.my_location, color: AppColors.primary),
              label: Text(_isLoading ? 'Locating...' : 'Current location', style: const TextStyle(color: Colors.white)),
            ),
          ),

          // Bottom Sheet with Address
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(AppConstants.padding),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order will be delivered here',
                      style: TextStyle(color: AppColors.primary.withValues(alpha: 0.8), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentLocality,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentAddress,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (_isLoading || _isSaving) ? null : _confirmAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Confirm & Proceed'),
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
