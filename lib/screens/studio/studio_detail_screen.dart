import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import 'payment_screen.dart';
import 'report_screen.dart';
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
import 'package:share_plus/share_plus.dart';
import '../../services/wishlist_service.dart';

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
  bool _isAddingToCart = false;
  double? _userLat;
  double? _userLng;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadUserLocation();
    _checkWishlistStatus();
    CartService.refresh(); // Populate cart stream so the cart icon shows correct state
  }

  Future<void> _checkWishlistStatus() async {
    final wishlisted = await WishlistService.isWishlisted(widget.studio.id);
    if (mounted) {
      setState(() {
        _isWishlisted = wishlisted;
      });
    }
  }

  Future<void> _loadUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    // Coordinates are saved as double via prefs.setDouble(), so read them correctly
    final lat = prefs.getDouble('location_lat');
    final lng = prefs.getDouble('location_lng');
    
    if (lat != null && lng != null) {
      if (mounted) {
        setState(() {
          _userLat = lat;
          _userLng = lng;
        });
      }
      return;
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
    final address = widget.studio.locationAddress;
    if (address == null || address.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Location"),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadReviews() async {
    final reviews = await ApiService.getReviews(int.parse(widget.studio.id));
    if (mounted) {
      setState(() {
        userReviews = reviews.cast<Map<String, dynamic>>();
        
        // Extract all images from reviews to show in the "Customers photos & videos" gallery
        userPhotos.clear();
        for (var review in userReviews) {
          if (review['images'] != null && review['images'] is List) {
            userPhotos.addAll(review['images'] as List);
          }
        }
        
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
    final category = widget.studio.category.toLowerCase();
    final isEquipment = category.contains('equipment');
    final isManpower = category.contains('manpower');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomBookingBar(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: CustomFloatingNavbar(
                selectedIndex: AppNavigation.selectedTabIndex.value,
                onTabSelected: (index) {},
              ),
            ),
          ],
        ),
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
                  if (!isManpower && widget.studio.amenities.isNotEmpty) ...[
                    _buildSectionTitle("Amenities"),
                    const SizedBox(height: 16),
                    _buildWhatIsIncludedGrid(widget.studio.amenities, Colors.green),
                    const SizedBox(height: 32),
                  ],
                  if (isEquipment && widget.studio.equipments.isNotEmpty) ...[
                    _buildSectionTitle("Included Accessories"),
                    const SizedBox(height: 16),
                    _buildWhatIsIncludedGrid(widget.studio.equipments, const Color(0xFFF95B72), textColor: const Color(0xFFF95B72), hasIconBg: true),
                    const SizedBox(height: 32),
                  ],
                  if (widget.studio.manpower.isNotEmpty) ...[
                    _buildSectionTitle("Included Services"),
                    const SizedBox(height: 16),
                    _buildWhatIsIncludedGrid(widget.studio.manpower, Colors.green, textColor: Colors.orange),
                    const SizedBox(height: 32),
                  ],
                  _buildBookingSteps(),
                  const SizedBox(height: 32),
                  _buildPolicyCard(),
                  const SizedBox(height: 24),
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
        IconButton(
          icon: Icon(_isWishlisted ? Icons.favorite : Icons.favorite_border, color: _isWishlisted ? Colors.redAccent : Colors.white, size: 22), 
          onPressed: () async {
            await WishlistService.toggleWishlist(widget.studio);
            _checkWishlistStatus();
          }
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22), 
          onPressed: () {
            Share.share('Check out ${widget.studio.listingTitle} on Z01! Download the app now to book it.');
          }
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMainImage(List<dynamic> images) {
    if (images == null || images.isEmpty) return const SizedBox();
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullscreenImageViewer(images: images, initialIndex: 0),
              ),
            );
          },
          child: Image.network(
            ApiService.getSafeImageUrl(images[0]),
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
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
    return (images == null || images.length <= 1) ? const SizedBox() : SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 1; i < (images.length > 4 ? 4 : images.length); i++)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullscreenImageViewer(images: images, initialIndex: i),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(ApiService.getSafeImageUrl(images[i]), width: 80, height: 60, fit: BoxFit.cover),
                ),
              ),
            ),
          if (images.length > 4)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullscreenImageViewer(images: images, initialIndex: 4),
                  ),
                );
              },
              child: Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(ApiService.getSafeImageUrl(images[4])),
                    fit: BoxFit.cover,
                    opacity: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text("See All\nImages", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.studio.listingTitle,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((widget.studio.vendorName ?? '').isNotEmpty) ...[
                     const SizedBox(height: 4),
                     Text(
                       widget.studio.vendorName!,
                       style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                     ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    textAlign: TextAlign.right,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₹${widget.studio.pricePerDay ?? widget.studio.pricePerHour}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFCA9AFF)),
                        ),
                        const TextSpan(
                          text: '/day',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '20% Deposit',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
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
    if (amenities == null || amenities.isEmpty) return const SizedBox();
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

  Widget _buildWhatIsIncludedGrid(List<String> items, Color iconColor, {Color? textColor, bool hasIconBg = false}) {
    if (items.isEmpty) return const SizedBox();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: items.map((a) {
        final name = a.toString();
        final lower = name.toLowerCase();
        IconData icon = Icons.check_circle_outline;
        if (lower.contains('mic')) icon = Icons.mic;
        else if (lower.contains('head')) icon = Icons.headphones;
        else if (lower.contains('audio') || lower.contains('interface')) icon = Icons.settings_input_component;
        else if (lower.contains('desk') || lower.contains('table')) icon = Icons.table_bar;
        else if (lower.contains('lcd') || lower.contains('monitor') || lower.contains('screen')) icon = Icons.tv;
        else if (lower.contains('light')) icon = Icons.lightbulb;
        else if (lower.contains('camera') || lower.contains('drone')) icon = Icons.camera_alt;
        else if (lower.contains('lens')) icon = Icons.camera;
        else if (lower.contains('tripod') || lower.contains('stand') || lower.contains('gimbal')) icon = Icons.videocam;
        else if (lower.contains('wifi') || lower.contains('internet')) icon = Icons.wifi;
        else if (lower.contains('parking')) icon = Icons.local_parking;
        else if (lower.contains('ac') || lower.contains('air')) icon = Icons.ac_unit;
        else if (lower.contains('battery') || lower.contains('power')) icon = Icons.battery_full;
        else if (lower.contains('cable') || lower.contains('wire') || lower.contains('cord')) icon = Icons.cable;
        else if (lower.contains('charger') || lower.contains('adapter')) icon = Icons.electrical_services;
        else if (lower.contains('memory') || lower.contains('sd card') || lower.contains('storage') || lower.contains('drive') || lower.contains('disk')) icon = Icons.sd_storage;
        else if (lower.contains('bag') || lower.contains('case') || lower.contains('cover')) icon = Icons.cases;
        else if (lower.contains('remote') || lower.contains('controller')) icon = Icons.settings_remote;
        else if (lower.contains('wireless') || lower.contains('bluetooth')) icon = Icons.bluetooth;
        else if (lower.contains('rgb') || lower.contains('color')) icon = Icons.color_lens;
        else if (lower.contains('video') || lower.contains('raw') || lower.contains('4k') || lower.contains('8k') || lower.contains('hd')) icon = Icons.high_quality;
        else if (lower.contains('frame') || lower.contains('sensor')) icon = Icons.crop_free;
        else if (lower.contains('flash') || lower.contains('strobe')) icon = Icons.flash_on;
        else if (lower.contains('filter')) icon = Icons.filter_alt;
        else if (lower.contains('editor') || lower.contains('director') || lower.contains('assistant') || lower.contains('engineer') || lower.contains('artist') || lower.contains('man')) icon = Icons.person;
        return _buildIncludedItem(icon, name, iconColor, textColor: textColor, hasIconBg: hasIconBg);
      }).toList(),
    );
  }

  Widget _buildIncludedItem(IconData icon, String label, Color iconColor, {Color? textColor, bool hasIconBg = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasIconBg)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.15),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            )
          else
            Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor ?? Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: textColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
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
          Icon(icon, size: 30, color: const Color(0xFFCA9AFF)),
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
        Icon(icon, color: const Color(0xFFCA9AFF), size: 20),
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
                backgroundImage: NetworkImage(ApiService.getSafeImageUrl(
                    (widget.studio.images != null && widget.studio.images.isNotEmpty) 
                        ? widget.studio.images[0] 
                        : 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=200&auto=format&fit=crop')),
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
              GestureDetector(
                onTap: _openInGoogleMaps,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 120,
                      child: Text(
                        widget.studio.locationAddress ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 3,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
                backgroundColor: const Color(0xFFCA9AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text("View Shop", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportScreen(studio: widget.studio),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFCA9AFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Report $shopName",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages(Function setModalState, List<dynamic> targetList) async {
    if (targetList.length >= 3) {
      return;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: kIsWeb,
    );

    if (result != null) {
      setModalState(() {
        final remaining = 3 - targetList.length;
        if (kIsWeb) {
          final newFiles = result.files.map((f) => f.bytes).whereType<Uint8List>().toList();
          targetList.addAll(newFiles.take(remaining));
        } else {
          final newPaths = result.paths.whereType<String>().toList();
          targetList.addAll(newPaths.take(remaining));
        }
      });
    }
  }

  Widget _buildPickedImage(dynamic photo, {double width = 70, double height = 70, BoxFit fit = BoxFit.cover}) {
    if (kIsWeb && photo is Uint8List) {
      return Image.memory(photo, width: width, height: height, fit: fit);
    } else if (photo is String) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return Image.network(
          ApiService.getSafeImageUrl(photo),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 20),
          ),
        );
      } else if (!kIsWeb) {
        return Image.file(
          File(photo),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 20),
          ),
        );
      }
    }
    return Container(width: width, height: height, color: Colors.grey);
  }

  void _openFullScreenImage(List<dynamic> photos, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.95),
        pageBuilder: (context, _, __) {
          return _FullScreenImageViewer(
            photos: photos,
            initialIndex: initialIndex,
            buildImage: _buildPickedImage,
          );
        },
      ),
    );
  }

  void _showReviewSheet(BuildContext context) {
    _isSubmittingReview = false;
    int localRating = 0;
    List<dynamic> pendingPhotos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => PopScope(
          canPop: !_isSubmittingReview,
          child: Container(
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
            child: Stack(
              children: [
                SingleChildScrollView(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Studio Photos", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text("${pendingPhotos.length} / 3", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 70,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (pendingPhotos.length < 3) ...[
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
                                  child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFCA9AFF)),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            ...pendingPhotos.asMap().entries.map((entry) {
                              final index = entry.key;
                              final photo = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildPickedImage(photo),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            pendingPhotos.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
                                // 1. Upload Images in Parallel
                                final uploadFutures = pendingPhotos.map((photo) => ApiService.uploadImage(photo)).toList();
                                final urls = await Future.wait(uploadFutures);
                                List<String> uploadedUrls = urls.whereType<String>().toList();
        
                                // 2. Post Review
                                final prefs = await SharedPreferences.getInstance();
                                final userId = prefs.getString('user_id');
                                final userName = prefs.getString('user_name') ?? 'User';
                                
                                final reviewData = {
                                  'listing_id': int.tryParse(widget.studio.id) ?? 0,
                                  'rating': localRating,
                                  'comment': _reviewController.text,
                                  'user_id': userId,
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
                                    userPhotos.addAll(uploadedUrls);
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
                            backgroundColor: const Color(0xFFCA9AFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Publish Review", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                if (_isSubmittingReview)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFCA9AFF)),
                            SizedBox(height: 16),
                            Text(
                              "Publishing your review...",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
                  border: Border.all(color: const Color(0xFFCA9AFF)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("Write a Review", style: TextStyle(color: Color(0xFFCA9AFF), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator(color: Color(0xFFCA9AFF)))
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
                          Row(children: List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < (double.tryParse(review['rating']?.toString() ?? '0')?.round() ?? 0) ? Colors.amber : Colors.white10))),
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
                        children: (review['images'] as List).asMap().entries.map((entry) {
                          final index = entry.key;
                          final url = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _openFullScreenImage(review['images'] as List, index),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildPickedImage(url, width: 50, height: 50),
                              ),
                            ),
                          );
                        }).toList(),
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
            children: userPhotos.asMap().entries.map((entry) {
              final index = entry.key;
              final photo = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _openFullScreenImage(userPhotos, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildPickedImage(photo, width: 110, height: 130),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

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
                      color: isInCart ? const Color(0xFFCA9AFF).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isInCart ? const Color(0xFFCA9AFF).withOpacity(0.3) : Colors.white10),
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
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFCA9AFF)))
                        : Icon(
                            isInCart ? Icons.shopping_cart : Icons.shopping_cart_outlined, 
                            color: isInCart ? const Color(0xFFCA9AFF) : Colors.white
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
                    onPressed: () => _showDateConfirmationSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCA9AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Select Booking Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFCA9AFF), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.5)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDateConfirmationSheet(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('filter_date');
    final countVal = prefs.getInt('filter_count');
    final rentalTypeVal = prefs.getString('filter_rental_type');
    final timeVal = prefs.getString('filter_time');

    String rentalType = rentalTypeVal ?? 'Hourly';
    int count = countVal ?? (rentalType == 'Hourly' ? 4 : 1);
    DateTime initialDate = dateStr != null ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();
    String time = timeVal ?? '10:00';

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            // Generate 7 consecutive days starting from today
            final List<DateTime> days = [];
            DateTime d = DateTime.now();
            for (int i = 0; i < 7; i++) {
              days.add(d);
              d = d.add(const Duration(days: 1));
            }

            bool dateExists = false;
            for (var day in days) {
              if (day.day == initialDate.day && day.month == initialDate.month && day.year == initialDate.year) {
                dateExists = true;
                break;
              }
            }
            if (!dateExists) {
              days.add(initialDate);
              days.sort((a, b) => a.compareTo(b));
            }

            final dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

            final startHour = int.tryParse(time.split(':')[0]) ?? 10;
            final startMinute = int.tryParse(time.split(':')[1]) ?? 0;
            final startDT = DateTime(initialDate.year, initialDate.month, initialDate.day, startHour, startMinute);
            final endDT = rentalType == 'Hourly'
                ? startDT.add(Duration(hours: count))
                : startDT.add(Duration(days: count));

            String fmt(DateTime dt) {
              final wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
              return '$wd, ${dt.day} ${months[dt.month - 1]}';
            }

            String fmtTime(DateTime dt) {
              final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
              final m = dt.minute.toString().padLeft(2, '0');
              return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
            }

            final List<String> timeSlots = [
              '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00',
            ];

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Decorative Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Colors.white, size: 22),
                        ),
                        const Text(
                          'Confirm Booking Period',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.help_outline, color: Colors.white38, size: 22),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hourly / Daily Toggle Slider
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: ['Hourly', 'Daily'].map((tab) {
                                final sel = rentalType == tab;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setSheet(() {
                                        rentalType = tab;
                                        count = tab == 'Hourly' ? 4 : 1;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: sel ? const Color(0xFFCA9AFF) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Text(
                                        tab,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: sel ? Colors.white : Colors.white38,
                                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Duration selection
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                rentalType == 'Hourly' ? 'NUMBER OF HOURS' : 'NUMBER OF DAYS',
                                style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              const Text(
                                'Max 12 hours',
                                style: TextStyle(color: Color(0xFFCA9AFF), fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _stepperBtn(Icons.remove, () {
                                if (count > 1) {
                                  setSheet(() => count--);
                                }
                              }),
                              const SizedBox(width: 24),
                              Column(
                                children: [
                                  Text(
                                    '$count',
                                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    rentalType == 'Hourly' ? 'SELECTED HOURS' : 'SELECTED DAYS',
                                    style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              _stepperBtn(Icons.add, () {
                                final max = rentalType == 'Hourly' ? 12 : 30;
                                if (count < max) {
                                  setSheet(() => count++);
                                }
                              }),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Quick duration selection chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: (rentalType == 'Hourly'
                                      ? [2, 3, 4, 6, 8]
                                      : [1, 2, 3, 5, 7])
                                  .map((val) {
                                final sel = count == val;
                                final label = rentalType == 'Hourly' ? '$val hrs' : '$val ${val == 1 ? "day" : "days"}';
                                return GestureDetector(
                                  onTap: () {
                                    setSheet(() {
                                      count = val;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel ? const Color(0xFFCA9AFF) : const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: sel ? Colors.transparent : Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: sel ? Colors.white : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Date Selection horizontal slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                rentalType == 'Daily' ? 'SELECT START DATE' : 'SELECT DATE',
                                style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate.isBefore(DateTime.now()) ? DateTime.now() : initialDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: Color(0xFFCA9AFF),
                                            onPrimary: Colors.white,
                                            surface: Color(0xFF1E1E1E),
                                            onSurface: Colors.white,
                                          ),
                                          dialogBackgroundColor: const Color(0xFF1E1E1E),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (pickedDate != null) {
                                    setSheet(() {
                                      initialDate = pickedDate;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCA9AFF).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFCA9AFF).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_month, color: Color(0xFFCA9AFF), size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${months[initialDate.month - 1]} ${initialDate.day}',
                                        style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                ...days.map((d) {
                                  final sel = d.day == initialDate.day && d.month == initialDate.month;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () => setSheet(() => initialDate = d),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        width: 54,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: sel ? Colors.white : const Color(0xFF2A2A2A),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              dayNames[d.weekday - 1],
                                              style: TextStyle(
                                                color: sel ? Colors.black : Colors.white38,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${d.day}',
                                              style: TextStyle(
                                                color: sel ? Colors.black : Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Start Time Selection
                          const Text(
                            'SELECT START TIME',
                            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: timeSlots.map((slot) {
                              final sel = slot == time;
                              return GestureDetector(
                                onTap: () => setSheet(() => time = slot),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 72,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFFCA9AFF).withOpacity(0.15) : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: sel ? const Color(0xFFCA9AFF) : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    slot,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: sel ? const Color(0xFFCA9AFF) : Colors.white54,
                                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Booking Summary preview card
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'BOOKING SUMMARY',
                                style: TextStyle(color: Color(0xFFCA9AFF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  'AVAILABLE',
                                  style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF242424),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _summaryTile(Icons.category_outlined, 'CATEGORY', widget.studio.category)),
                                    Expanded(child: _summaryTile(Icons.calendar_today_outlined, 'DATE', fmt(initialDate))),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _summaryTile(Icons.access_time_rounded, 'PICKUP', fmtTime(startDT))),
                                    Expanded(
                                      child: _summaryTile(
                                        Icons.update_rounded,
                                        rentalType == 'Hourly' ? 'RETURN' : 'RETURN DATE',
                                        rentalType == 'Hourly' ? fmtTime(endDT) : fmt(endDT),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white10, height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.timelapse_rounded, color: Colors.white38, size: 14),
                                        const SizedBox(width: 6),
                                        const Text('Duration', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                      ],
                                    ),
                                    Text(
                                      rentalType == 'Hourly' ? '$count Hours' : '$count Days',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Proceed to Cart Action Button
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).padding.bottom + 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);

                          // Save selected values to SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('filter_date', initialDate.toIso8601String());
                          await prefs.setInt('filter_count', count);
                          await prefs.setString('filter_rental_type', rentalType);
                          await prefs.setString('filter_time', time);
                          await prefs.setString('filter_category', widget.studio.category);

                          // Form the item JSON including explicit start & end dates
                          final itemMap = widget.studio.toJson();
                          itemMap['start_date'] = startDT.toIso8601String();
                          itemMap['end_date'] = endDT.toIso8601String();
                          itemMap['rental_type'] = rentalType;
                          itemMap['duration_count'] = count;

                          await CartService.addToCart(itemMap);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Booking period confirmed. Redirecting to cart...'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            
                            // Navigate to the Cart Screen (tab index 3)
                            AppNavigation.switchTab(3, context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCA9AFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Proceed to Cart',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class FullscreenImageViewer extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeUrls = widget.images.map((img) => ApiService.getSafeImageUrl(img)).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background black
          Positioned.fill(
            child: Container(
              color: Colors.black,
            ),
          ),
          // Main PageView with InteractiveViewer for zoom
          PageView.builder(
            controller: _pageController,
            itemCount: safeUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    safeUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
                    ),
                  ),
                ),
              );
            },
          ),
          // Close button and counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_currentIndex + 1} / ${safeUrls.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 40), // Balance
              ],
            ),
          ),
          // Bottom premium Thumbnail Slider
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 64,
              child: Center(
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: safeUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFCA9AFF) : Colors.white24,
                            width: isSelected ? 3 : 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            safeUrls[index],
                            fit: BoxFit.cover,
                            opacity: isSelected ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<dynamic> photos;
  final int initialIndex;
  final Widget Function(dynamic photo, {double width, double height, BoxFit fit}) buildImage;

  const _FullScreenImageViewer({
    required this.photos,
    required this.initialIndex,
    required this.buildImage,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: widget.buildImage(
                    photo,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.photos.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${_currentIndex + 1} / ${widget.photos.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const SizedBox(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

