import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import 'payment_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../vendor/vendor_profile_screen.dart';
import '../../services/api_service.dart';
import '../../services/cart_service.dart';
import '../../models/listing_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StudioDetailScreen extends StatefulWidget {
  final ListingModel studio;
  const StudioDetailScreen({super.key, required this.studio});

  @override
  State<StudioDetailScreen> createState() => _StudioDetailScreenState();
}

class _StudioDetailScreenState extends State<StudioDetailScreen> {
  List<Map<String, dynamic>> userReviews = [];
  List<dynamic> userPhotos = []; // Local picked photos
  int selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isLoadingReviews = true;
  bool _isSubmittingReview = false;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadUserLocation();
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
      print("Error getting location in detail: $e");
    }
  }

  String _getDistanceString() {
    if (_userLat == null || _userLng == null) return " • 📍 Locating...";
    
    final lat = widget.studio.latitude;
    final lng = widget.studio.longitude;
    
    if (lat == null || lng == null) return "";

    final meters = Geolocator.distanceBetween(
      _userLat!, 
      _userLng!, 
      lat, 
      lng,
    );
    
    if (meters < 1000) {
      return " • ${meters.toStringAsFixed(0)}m Away";
    } else {
      return " • ${(meters / 1000).toStringAsFixed(1)}Km Away";
    }
  }

  Widget _buildMapSection() {
    final lat = widget.studio.latitude;
    final lng = widget.studio.longitude;

    if (lat == null || lng == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _buildSectionTitle("Location"),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(lat, lng),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(widget.studio.id),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(title: widget.studio.listingTitle),
                ),
              },
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              onTap: (_) => _openInGoogleMaps(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openInGoogleMaps,
          child: Row(
            children: [
              const Icon(Icons.directions, color: Color(0xFF4FC3F7), size: 18),
              const SizedBox(width: 8),
              const Text(
                "Get Directions on Google Maps",
                style: TextStyle(color: Color(0xFF4FC3F7), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadReviews() async {
    final reviews = await ApiService.getReviews(int.parse(widget.studio.id));
    if (mounted) {
      setState(() {
        userReviews = reviews.cast<Map<String, dynamic>>();
        _isLoadingReviews = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.studio.images;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomBookingBar(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomFloatingNavbar(
              selectedIndex: AppNavigation.selectedTabIndex.value,
              onTabSelected: (index) {},
            ),
          ),
          const SizedBox(height: 20), // Bottom margin for floating effect
        ],
      ),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildMainImage(images),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildThumbnailGallery(images),
                  const SizedBox(height: 24),
                  _buildTitlePrice(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Specifications"),
                  const SizedBox(height: 12),
                  _buildSpecificationsGrid(),
                  const SizedBox(height: 24),
                  _buildPromoBanner(),
                  const SizedBox(height: 32),
                  if (widget.studio.amenities.isNotEmpty) ...[
                    _buildSectionTitle("What's Included"),
                    const SizedBox(height: 16),
                    _buildWhatIsIncludedGrid(),
                    const SizedBox(height: 32),
                  ],
                  _buildBookingSteps(),
                  const SizedBox(height: 32),
                  _buildMapSection(),
                  const SizedBox(height: 32),
                  _buildPolicyCard(),
                  const SizedBox(height: 32),
                  _buildVendorShopSection(),
                  const SizedBox(height: 32),
                  _buildReviewsSection(context),
                  const SizedBox(height: 32),
                  if (userPhotos.isNotEmpty) ...[
                    _buildCustomerPhotosSection(),
                    const SizedBox(height: 32),
                  ],
                  const SizedBox(height: 120), // Bottom space
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF121212),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.studio.subCategory,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white, size: 22), onPressed: () {}),
        IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22), onPressed: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMainImage(List<dynamic> images) {
    if (images.isEmpty) return const SizedBox();
    return Stack(
      children: [
        Image.network(
          images[0],
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20, // Added right: 20 to prevent overflow and enable wrapping
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.studio.subCategory.toUpperCase(),
                style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                widget.studio.listingTitle,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: const Text(
              "Available",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailGallery(List<dynamic> images) {
    return images.length <= 1 ? const SizedBox() : SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 1; i < (images.length > 4 ? 4 : images.length); i++)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(images[i], width: 80, height: 60, fit: BoxFit.cover),
              ),
            ),
          if (images.length > 4)
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(images[4]),
                  fit: BoxFit.cover,
                  opacity: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Text("See All\nImages", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildTitlePrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "${_getShorterAddress(widget.studio.locationAddress)}${_getDistanceString()}",
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${widget.studio.pricePerDay ?? widget.studio.pricePerHour}/day',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFBA68C8)),
                ),
                Text(
                  'Instant Booking',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAmenityChipsRow(),
      ],
    );
  }

  Widget _buildAmenityChipsRow() {
    final amenities = widget.studio.amenities;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((a) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4FC3F7).withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.2)),
        ),
        child: Text(
          a.toString().toUpperCase(),
          style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 9, fontWeight: FontWeight.bold),
        ),
      )).toList(),
    );
  }

  Widget _buildSpecificationsGrid() {
    final category = widget.studio.category.toLowerCase();
    final isEquipment = category.contains('equipment');
    final isManpower = category.contains('manpower');

    final List<Map<String, String>> specs = [];

    if (isEquipment) {
      if ((widget.studio.brand ?? '').isNotEmpty)
        specs.add({'label': 'Brand', 'value': widget.studio.brand!});
      if ((widget.studio.model ?? '').isNotEmpty)
        specs.add({'label': 'Model', 'value': widget.studio.model!});
      if (widget.studio.quantity != null)
        specs.add({'label': 'Available Qty', 'value': '${widget.studio.quantity}x Units'});
      if (widget.studio.pricePerHour != null)
        specs.add({'label': 'Price / Hour', 'value': '₹${widget.studio.pricePerHour}'});
      if (widget.studio.pricePerDay != null)
        specs.add({'label': 'Price / Day', 'value': '₹${widget.studio.pricePerDay}'});
    } else if (isManpower) {
      if (widget.studio.subCategory.isNotEmpty)
        specs.add({'label': 'Role', 'value': widget.studio.subCategory});
      // if (widget.studio.experience_years != null) // Missing in ListingModel for now, but can be added if needed
      //   specs.add({'label': 'Experience', 'value': '${widget.studio.experience_years} Years'});
      if (widget.studio.pricePerHour != null)
        specs.add({'label': 'Rate / Hour', 'value': '₹${widget.studio.pricePerHour}'});
      if (widget.studio.pricePerDay != null)
        specs.add({'label': 'Day Rate', 'value': '₹${widget.studio.pricePerDay}'});
      if ((widget.studio.locationAddress ?? '').isNotEmpty)
        specs.add({'label': 'Based In', 'value': widget.studio.locationAddress!.split(',').last.trim()});
    } else {
      if (widget.studio.subCategory.isNotEmpty)
        specs.add({'label': 'Type', 'value': widget.studio.subCategory});
      if (widget.studio.areaSqft != null)
        specs.add({'label': 'Studio Size', 'value': '${widget.studio.areaSqft} sq ft'});
      if (widget.studio.capacity != null)
        specs.add({'label': 'Capacity', 'value': '${widget.studio.capacity} Persons'});
      if (widget.studio.minimumBookingHours != null)
        specs.add({'label': 'Min. Booking', 'value': '${widget.studio.minimumBookingHours} Hours'});
      if (widget.studio.openingTime != null && widget.studio.closingTime != null)
        specs.add({'label': 'Available Hours', 'value': '${widget.studio.openingTime} – ${widget.studio.closingTime}'});
      if (widget.studio.pricePerHour != null)
        specs.add({'label': 'Price / Hour', 'value': '₹${widget.studio.pricePerHour}'});
      if (widget.studio.pricePerDay != null)
        specs.add({'label': 'Price / Day', 'value': '₹${widget.studio.pricePerDay}'});
    }

    if (specs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No specifications provided.', style: TextStyle(color: Colors.white54))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: specs.asMap().entries.map((entry) {
          final isLast = entry.key == specs.length - 1;
          return _buildSpecTableRow(entry.value['label']!, entry.value['value']!, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildSpecTableRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF311B92).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 18),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "You will earn 20 super coins on this purchase",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWhatIsIncludedGrid() {
    final amenities = widget.studio.amenities;
    if (amenities.isEmpty) return const SizedBox();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: amenities.map((a) {
        final name = a.toString();
        final lower = name.toLowerCase();
        IconData icon = Icons.check_circle_outline;
        if (lower.contains('mic')) icon = Icons.mic;
        else if (lower.contains('head')) icon = Icons.headphones;
        else if (lower.contains('audio') || lower.contains('interface')) icon = Icons.settings_input_component;
        else if (lower.contains('desk') || lower.contains('table')) icon = Icons.table_bar;
        else if (lower.contains('lcd') || lower.contains('monitor') || lower.contains('screen')) icon = Icons.tv;
        else if (lower.contains('light')) icon = Icons.lightbulb;
        else if (lower.contains('camera')) icon = Icons.camera_alt;
        else if (lower.contains('tripod') || lower.contains('stand')) icon = Icons.videocam;
        else if (lower.contains('wifi') || lower.contains('internet')) icon = Icons.wifi;
        else if (lower.contains('parking')) icon = Icons.local_parking;
        else if (lower.contains('ac') || lower.contains('air')) icon = Icons.ac_unit;
        return _buildIncludedItem(icon, name);
      }).toList(),
    );
  }

  Widget _buildIncludedItem(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildBookingSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Book now in 3 simple steps!'),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepIcon(Icons.video_call, "Step 1", "Choose a service\nfor you parameters"),
            _buildStepIcon(Icons.store, "Step 2", "Choose location &\ndate set"),
            _buildStepIcon(Icons.verified_user, "Step 3", "Secure booking"),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIcon(IconData icon, String step, String desc) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color(0xFFBA68C8)),
          const SizedBox(height: 8),
          Text(step, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPolicyRow(Icons.access_time, "Minimum Booking", "5 hours per day minimum rental duration."),
          const SizedBox(height: 16),
          _buildPolicyRow(Icons.calendar_month, "Early Booking Required", "Must book at least 16 hours in advance."),
        ],
      ),
    );
  }

  Widget _buildPolicyRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openInGoogleMaps() async {
    final lat = widget.studio.latitude;
    final lng = widget.studio.longitude;
    final address = Uri.encodeComponent(widget.studio.locationAddress ?? '');

    Uri mapsUri;
    if (lat != null && lng != null) {
      mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else if (address.isNotEmpty) {
      mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
    } else {
      return;
    }

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  String _getShorterAddress(String? address) {
    if (address == null || address.isEmpty) return 'Location N/A';
    final parts = address.split(',');
    if (parts.length > 2) {
      return "${parts[parts.length - 2].trim()}, ${parts[parts.length - 1].trim()}";
    }
    return address;
  }

  Widget _buildVendorShopSection() {
    final shopName = widget.studio.listingTitle;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(widget.studio.images.isNotEmpty ? widget.studio.images[0] : 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=200&auto=format&fit=crop'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.studio.vendorName ?? shopName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        Text(" 4.2", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text("Location ", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                  const Icon(Icons.near_me, color: Colors.blueAccent, size: 18),
                  if (_userLat != null && _userLng != null)
                    Text(
                      _getDistanceString().replaceAll(' • ', ' '),
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorProfileScreen(
                      vendor: {
                        'id': widget.studio.vendorId,
                        'name': widget.studio.vendorName ?? shopName,
                        'business_type': 'Professional Service',
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA68C8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text("View Shop", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFBA68C8).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Report $shopName",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages(Function setModalState, List<dynamic> targetList) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: kIsWeb,
    );

    if (result != null) {
      setModalState(() {
        if (kIsWeb) {
          targetList.addAll(result.files.map((f) => f.bytes).whereType<Uint8List>());
        } else {
          targetList.addAll(result.paths.whereType<String>());
        }
      });
    }
  }

  Widget _buildPickedImage(dynamic photo, {double width = 70, double height = 70}) {
    if (kIsWeb && photo is Uint8List) {
      return Image.memory(photo, width: width, height: height, fit: BoxFit.cover);
    } else if (!kIsWeb && photo is String) {
      return Image.file(File(photo), width: width, height: height, fit: BoxFit.cover);
    }
    return Container(width: width, height: height, color: Colors.grey);
  }

  void _showReviewSheet(BuildContext context) {
    int localRating = 0;
    List<dynamic> pendingPhotos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.only(topRight: Radius.circular(24), topLeft: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text("Rate your experience", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: List.generate(5, (index) => GestureDetector(
                  onTap: () => setModalState(() => localRating = index + 1),
                  child: Icon(
                    index < localRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                )),
              ),
              const SizedBox(height: 24),
              const Text("Your Review", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Tell us about your experience...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  fillColor: Colors.black26,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Studio Photos", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: () => _pickImages(setModalState, pendingPhotos),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFBA68C8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ...pendingPhotos.map((photo) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildPickedImage(photo),
                      ),
                    )).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmittingReview ? null : () async {
                    if (_reviewController.text.isNotEmpty && localRating > 0) {
                      setModalState(() => _isSubmittingReview = true);
                      
                      try {
                        List<String> uploadedUrls = [];
                        // 1. Upload Images
                        for (var i = 0; i < pendingPhotos.length; i++) {
                          final fileName = 'review_${widget.studio.id}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
                          final url = await ApiService.uploadImage(pendingPhotos[i]);
                          if (url != null) uploadedUrls.add(url);
                        }

                        // 2. Post Review
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('user_id');
                        final userName = prefs.getString('user_name') ?? 'User';
                        
                        final reviewData = {
                          'listing_id': widget.studio.id,
                          'rating': localRating,
                          'comment': _reviewController.text,
                          'user_id': userId != null ? int.parse(userId) : null,
                          'user_name': userName,
                          'images': uploadedUrls,
                          'created_at': DateTime.now().toIso8601String(),
                        };
                        
                        final success = await ApiService.postReview(reviewData);
                        if (!success) throw Exception("Failed to post review");
                        
                        // 3. Update Local UI
                        if (mounted) {
                          setState(() {
                            userReviews.insert(0, reviewData);
                            userPhotos.addAll(pendingPhotos);
                            _reviewController.clear();
                          });
                        }
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Review published successfully!"), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                        );
                      } finally {
                        if (mounted) {
                          setModalState(() => _isSubmittingReview = false);
                        }
                      }
                    } else if (localRating == 0) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a rating"), backgroundColor: Colors.orange),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA68C8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmittingReview 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Publish Review", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle("Customer reviews"),
            GestureDetector(
              onTap: () => _showReviewSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBA68C8)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("Write a Review", style: TextStyle(color: Color(0xFFBA68C8), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator(color: Color(0xFFBA68C8)))
        else if (userReviews.isEmpty) 
          const Text("No reviews yet. Be the first to review!", style: TextStyle(color: Colors.white54, fontSize: 13))
        else
          Column(
            children: userReviews.map((review) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Row(children: List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < (review['rating'] as int) ? Colors.amber : Colors.white10))),
                          const SizedBox(width: 8),
                          Text(review['user_name'] ?? 'Verified Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      Text(
                        review['created_at'] != null ? review['created_at'].toString().split('T').first : 'Today',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review['comment'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  if (review['images'] != null && (review['images'] as List).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: (review['images'] as List).map((url) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(url, width: 50, height: 50, fit: BoxFit.cover),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildCustomerPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Customers photos & videos"),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: userPhotos.map((photo) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPickedImage(photo, width: 110, height: 130),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  bool _isAddingToCart = false;

  Widget _buildBottomBookingBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10), // Reduced bottom padding since Navbar follows
      color: const Color(0xFF121212),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: CartService.cartStream,
                builder: (context, snapshot) {
                  final cartItems = snapshot.data ?? [];
                  final isInCart = cartItems.any((item) => item['id'].toString() == widget.studio.id.toString());
                  
                  return Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: isInCart ? const Color(0xFFBA68C8).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isInCart ? const Color(0xFFBA68C8).withOpacity(0.3) : Colors.white10),
                    ),
                    child: IconButton(
                      onPressed: _isAddingToCart ? null : () async {
                        setState(() => _isAddingToCart = true);
                        try {
                          if (isInCart) {
                            await CartService.removeFromCart({'id': widget.studio.id, 'category': widget.studio.category, 'listing_title': widget.studio.listingTitle});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from cart'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            await CartService.addToCart(widget.studio.toJson());
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to cart successfully!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isAddingToCart = false);
                          }
                        }
                      },
                      icon: _isAddingToCart 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBA68C8)))
                        : Icon(
                            isInCart ? Icons.shopping_cart : Icons.shopping_cart_outlined, 
                            color: isInCart ? const Color(0xFFBA68C8) : Colors.white
                          ),
                    ),
                  );
                }
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentScreen(studio: widget.studio)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA68C8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Book Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
