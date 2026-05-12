import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import 'studio_detail_screen.dart';
import '../home/search_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/listing_model.dart';

class StudioListScreen extends StatefulWidget {
  final String? initialSubCategory;
  const StudioListScreen({super.key, this.initialSubCategory});

  @override
  State<StudioListScreen> createState() => _StudioListScreenState();
}

class _StudioListScreenState extends State<StudioListScreen> {
  final List<Map<String, dynamic>> _subCategories = [
    {'title': 'Green Screen', 'color': const Color(0xFFEF5350), 'icon': Icons.screenshot_monitor},
    {'title': 'Photography', 'color': const Color(0xFFE57373), 'icon': Icons.camera_alt},
    {'title': 'Recording', 'color': const Color(0xFFBA68C8), 'icon': Icons.mic},
    {'title': 'Podcast Studio', 'color': const Color(0xFF7986CB), 'icon': Icons.headphones},
    {'title': 'Dance Studio', 'color': const Color(0xFF4CAF50), 'icon': Icons.music_note},
    {'title': 'Event', 'color': const Color(0xFF4FC3F7), 'icon': Icons.event},
    {'title': 'Fashion Shoot', 'color': const Color(0xFFFFB74D), 'icon': Icons.accessibility_new},
    {'title': 'AR/VR Capture', 'color': const Color(0xFFFF7043), 'icon': Icons.view_in_ar},
  ];
  int _selectedIndex = 0; // Home related category selected
  List<ListingModel> _recentStudios = [];
  bool _isSortingByProximity = false;
  bool _isLoading = true;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadRecentStudios();
  }

  Future<void> _loadUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latStr = prefs.getString('location_lat');
    final lngStr = prefs.getString('location_lng');
    
    if (latStr != null && lngStr != null) {
      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);
      if (lat != null && lng != null) {
        if (mounted) {
          setState(() {
            _userLat = lat;
            _userLng = lng;
          });
        }
        return;
      }
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  String _getDistance(ListingModel studio) {
    if (_userLat == null || _userLng == null) return "📍 Locating..."; 
    
    final studioLat = studio.latitude;
    final studioLng = studio.longitude;
    
    if (studioLat == null || studioLng == null) return "N/A";

    final distanceInMeters = Geolocator.distanceBetween(
      _userLat!, 
      _userLng!, 
      studioLat, 
      studioLng,
    );
    
    if (distanceInMeters < 1000) {
      return "${distanceInMeters.toStringAsFixed(0)} m";
    } else {
      return "${(distanceInMeters / 1000).toStringAsFixed(1)} Km";
    }
  }

  void _sortListings() {
    if (_userLat == null || _userLng == null) return;
    
    setState(() {
      _isSortingByProximity = !_isSortingByProximity;
      if (_isSortingByProximity) {
        _recentStudios.sort((a, b) {
          if (a.latitude == null || a.longitude == null) return 1;
          if (b.latitude == null || b.longitude == null) return -1;
          
          final distA = Geolocator.distanceBetween(_userLat!, _userLng!, a.latitude!, a.longitude!);
          final distB = Geolocator.distanceBetween(_userLat!, _userLng!, b.latitude!, b.longitude!);
          return distA.compareTo(distB);
        });
      } else {
        // Just reload or keep current? Re-loading is safer to restore original order
        _loadRecentStudios();
      }
    });
  }

  Future<void> _loadRecentStudios() async {
    try {
      final response = await ApiService.getStudios();
      
      List<ListingModel> filtered = response;
      
      if (widget.initialSubCategory != null && widget.initialSubCategory!.isNotEmpty) {
        filtered = filtered.where((s) {
          final subCat = s.subCategory.toLowerCase();
          return subCat.contains(widget.initialSubCategory!.toLowerCase());
        }).toList();
      }
      
      if (mounted) {
        setState(() {
          _recentStudios = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error loading studios: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBlueHeader(),
            Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Column(
                children: [
                  _buildPromoBanner(),
                  const SizedBox(height: 24),
                  if (widget.initialSubCategory == null || widget.initialSubCategory!.isEmpty) ...[
                    _buildCategoryGrid(),
                  ] else ...[
                    _buildVerticalListSection(),
                  ],
                  const SizedBox(height: 120), // Bottom space for Navbar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomFloatingNavbar(
              selectedIndex: AppNavigation.selectedTabIndex.value,
              onTabSelected: (index) {},
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBlueHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF4FC3F7),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for Camera, lens, lights',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            widget.initialSubCategory != null && widget.initialSubCategory!.isNotEmpty
                ? 'Results for\n${widget.initialSubCategory}'
                : 'Your Perfect\nStudio, Ready When\nYou Are!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Up To 20% Off On Select Manpower',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Limited-Time Deals From Trusted Vendors',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF176),
              shape: BoxShape.circle,
            ),
            child: const Column(
              children: [
                Text('20%', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('OFF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: _subCategories.length,
      itemBuilder: (context, index) {
        final cat = _subCategories[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 50),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudioListScreen(
                    initialSubCategory: cat['title'],
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: cat['color'],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Text(
                    cat['title'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: Icon(
                      cat['icon'],
                      size: 80,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalListSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7)));
    }

    if (_recentStudios.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text(
          "No studios found in this category yet.",
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${widget.initialSubCategory ?? 'Recent'} Studios",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: _sortListings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isSortingByProximity ? const Color(0xFF4FC3F7) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isSortingByProximity ? Colors.transparent : Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(Icons.near_me, color: _isSortingByProximity ? Colors.black : Colors.white60, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _isSortingByProximity ? "Nearest" : "Sort",
                      style: TextStyle(
                        color: _isSortingByProximity ? Colors.black : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentStudios.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (ctx, index) => _buildStudioCard(_recentStudios[index]),
        ),
      ],
    );
  }

  Widget _buildStudioCard(ListingModel studio) {
    final amenities = studio.amenities;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudioDetailScreen(studio: studio),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: (studio.images.isNotEmpty)
                      ? Image.network(studio.images[0], fit: BoxFit.cover)
                      : Container(color: Colors.grey[800], child: const Center(child: Icon(Icons.image, color: Colors.white24))),
                  ),
                ),
                // Available Tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Available",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Wishlist Icon
                const Positioned(
                  top: 12,
                  right: 12,
                  child: Icon(Icons.favorite_border, color: Colors.white, size: 24),
                ),
                // Distance Tag
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        Text(_getDistance(studio), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        const Text("Away location", style: TextStyle(color: Colors.white70, fontSize: 8)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studio.listingTitle,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              studio.subCategory,
                              style: const TextStyle(color: Colors.white60, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                studio.avgRating.toString(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${studio.pricePerDay ?? studio.pricePerHour}/day",
                            style: const TextStyle(color: Color(0xFFBA68C8), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    studio.locationAddress ?? 'Location N/A',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  // Amenities Chips
                  if (amenities.isNotEmpty)
                    SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: amenities.length > 5 ? 5 : amenities.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FC3F7).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.3)),
                          ),
                          child: Text(
                            amenities[i].toString().toUpperCase(),
                            style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
