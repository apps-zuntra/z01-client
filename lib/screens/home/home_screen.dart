import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/wishlist_button_widget.dart';
import '../studio/studio_list_screen.dart';
import '../equipment/equipment_list_screen.dart';
import '../manpower/manpower_list_screen.dart';
import '../studio/studio_detail_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import 'location_search_screen.dart';
import 'search_screen.dart';
import 'bookings_screen.dart';
import '../profile/profile_screen.dart'; 
import 'cart_screen.dart';
import '../../services/api_service.dart';
import '../../services/cart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/listing_model.dart';
import '../../widgets/booking_period_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _currentBannerIndex = 0;
  String _userLocationLocality = '';
  String _userLocationAddress = '';
  List<ListingModel> _recommendedListings = [];
  bool _isLoadingRecommended = true;

  // ── Filter state ──────────────────────────────────────────────
  String _filterRentalType = 'Hourly'; // 'Hourly' | 'Daily'
  String _filterCategory   = 'Studios'; // 'Studios' | 'Equipment' | 'Manpower'
  int    _filterCount      = 4;          // hours or days
  DateTime _filterDate     = DateTime.now();
  String _filterTime       = '10:00';    // HH:mm
  bool   _filterApplied    = false;

  @override
  void initState() {
    super.initState();
    _checkLocation();
    _loadRecommendedListings();
    CartService.init();
    _loadFiltersFromSharedPrefs();
    
    // Listen for tab switches from other screens
    AppNavigation.selectedTabIndex.addListener(_handleGlobalTabChange);
  }

  Future<void> _loadFiltersFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('filter_date');
    final countVal = prefs.getInt('filter_count');
    final rentalTypeVal = prefs.getString('filter_rental_type');
    final timeVal = prefs.getString('filter_time');
    final categoryVal = prefs.getString('filter_category');
    
    if (mounted) {
      setState(() {
        if (dateStr != null) {
          _filterDate = DateTime.tryParse(dateStr) ?? DateTime.now();
        }
        if (countVal != null) {
          _filterCount = countVal;
        }
        if (rentalTypeVal != null) {
          _filterRentalType = rentalTypeVal;
        }
        if (timeVal != null) {
          _filterTime = timeVal;
        }
        if (categoryVal != null) {
          _filterCategory = categoryVal;
        }
        if (dateStr != null || countVal != null || rentalTypeVal != null || timeVal != null || categoryVal != null) {
          _filterApplied = true;
        }
      });
    }
  }

  Future<void> _saveFiltersToSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('filter_date', _filterDate.toIso8601String());
    await prefs.setInt('filter_count', _filterCount);
    await prefs.setString('filter_rental_type', _filterRentalType);
    await prefs.setString('filter_time', _filterTime);
    await prefs.setString('filter_category', _filterCategory);
  }

  void _handleGlobalTabChange() {
    if (mounted) {
      setState(() {
        _selectedIndex = AppNavigation.selectedTabIndex.value;
      });
    }
  }

  @override
  void dispose() {
    AppNavigation.selectedTabIndex.removeListener(_handleGlobalTabChange);
    super.dispose();
  }

  Future<void> _loadRecommendedListings() async {
    try {
      final response = await ApiService.getStudios();
      
      if (mounted) {
        setState(() {
          _recommendedListings = response;
          _isLoadingRecommended = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecommended = false);
      }
      print("Error loading recommended: $e");
    }
  }

  Future<void> _checkLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('location_address');
    
    if (address == null || address.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
        if (res == true) _checkLocation();
      });
    } else {
      final locality = prefs.getString('location_locality');
      if (mounted) {
        setState(() {
          _userLocationLocality = locality ?? address.split(',').last.trim();
          _userLocationAddress = address;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeContent(),
              const SearchScreen(),
              const BookingsScreen(),
              const CartScreen(),
            ],
          ),
          if (MediaQuery.of(context).viewInsets.bottom == 0)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedIndex == 0) _buildCartSummary(),
                  const SizedBox(height: 12),
                  CustomFloatingNavbar(
                    selectedIndex: _selectedIndex,
                    onTabSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    return ValueListenableBuilder<int>(
      valueListenable: CartService.cartItemCount,
      builder: (context, count, __) {
        if (count == 0) return const SizedBox();
        
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: CartService.getCartItems(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            if (items.isEmpty) return const SizedBox();

            double total = 0;
            for (var item in items) {
              final price = item['price_per_day'] ?? item['price_per_hour'] ?? item['price'] ?? 0;
              total += (price is num) ? price : (double.tryParse(price.toString()) ?? 0);
            }

            return FadeInUp(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCA9AFF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCA9AFF).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$count Items in Cart', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(
                            '₹$total',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text('Review Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadRecommendedListings();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 24),
              _buildPromoBanner(),
              const SizedBox(height: 32),
              _buildSectionHeader('Explore Categories'),
              const SizedBox(height: 16),
              _buildCategories(),
              const SizedBox(height: 32),
              _buildProcessGuide(),
              const SizedBox(height: 32),
              _buildSectionHeader('Recommend for you (Recent)'),
              const SizedBox(height: 16),
              _buildRecommendedList(),
              const SizedBox(height: 150), // Extra space for cart summary + floating nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: Row(
        children: [
          const Icon(Icons.near_me, color: Color(0xFF9C27B0), size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
                if (res == true) _checkLocation();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _userLocationLocality,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 20),
                    ],
                  ),
                  Text(
                    _userLocationAddress,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4), // Alignment tweak
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chips Row ─────────────────────────────────────────
  Widget _buildFilterChips() {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final isToday = _filterDate.day == now.day && _filterDate.month == now.month && _filterDate.year == now.year;
    final dateLabel = isToday ? 'Today, ${_filterDate.day} ${months[_filterDate.month - 1]}' : '${_filterDate.day} ${months[_filterDate.month - 1]}';
    
    String formattedTime = _filterTime;
    final hourParts = _filterTime.split(':');
    if (hourParts.length == 2) {
      final hh = int.tryParse(hourParts[0]) ?? 10;
      final mm = int.tryParse(hourParts[1]) ?? 0;
      final ampm = hh < 12 ? 'AM' : 'PM';
      final h12 = hh % 12 == 0 ? 12 : hh % 12;
      formattedTime = '$h12:${mm.toString().padLeft(2, '0')} $ampm';
    }
    
    final timeLabel = '$formattedTime • $_filterCount ${_filterRentalType == 'Hourly' ? 'hrs' : 'days'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: Row(
        children: [
          _filterChip(
            icon: Icons.calendar_today_outlined,
            label: dateLabel,
            onTap: () => _showRentalDetailsSheet(context),
          ),
          const SizedBox(width: 10),
          _filterChip(
            icon: Icons.access_time_rounded,
            label: timeLabel,
            onTap: () => _showRentalDetailsSheet(context),
          ),
          const SizedBox(width: 10),
          _filterChip(
            icon: Icons.folder_open_outlined,
            label: _filterCategory,
            onTap: () => _showRentalDetailsSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _filterApplied ? const Color(0xFFCA9AFF).withOpacity(0.5) : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: _filterApplied ? const Color(0xFFCA9AFF) : Colors.white54),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _filterApplied ? Colors.white : Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rental Details Bottom Sheet ───────────────────────────────
  void _showRentalDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BookingPeriodSheet(
          title: 'Rental Details',
          showCategorySelector: true,
          initialRentalType: _filterRentalType,
          initialCategory: _filterCategory,
          initialCount: _filterCount,
          initialDate: _filterDate,
          initialTime: _filterTime,
          buttonText: 'Confirm Booking Period',
          onApply: (rentalType, category, count, date, time) async {
            Navigator.pop(ctx);
            // Apply filter back to home screen state
            setState(() {
              _filterRentalType = rentalType;
              _filterCategory = category;
              _filterCount = count;
              _filterDate = date;
              _filterTime = time;
              _filterApplied = true;
            });
            await _saveFiltersToSharedPrefs();

            // Navigate to the appropriate list screen
            if (category == 'Equipment') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipmentListScreen()));
            } else if (category == 'Manpower') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManpowerListScreen()));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioListScreen()));
            }
          },
        );
      },
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
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white54, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: FadeInUp(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 55,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textHint),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Search for studio, equipment, manpower',
                  style: TextStyle(color: AppColors.textHint),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    final banners = [
      _buildSingleBanner(
        title: 'Book studios, equipment &\nmanpower - all in one place',
        buttonText: 'Book Now',
        gradientColors: [const Color(0xFFCE93D8), const Color(0xFFCA9AFF)],
        icon: Icons.app_registration,
        showIcon: true,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioListScreen())),
      ),
      _buildSingleBanner(
        title: 'Only Verified Vendors on Z01',
        buttonText: 'Rent Now',
        gradientColors: [const Color(0xFFef4444), const Color(0xFFdc2626)],
        icon: FontAwesomeIcons.shieldHalved,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipmentListScreen())),
      ),
      _buildSingleBanner(
        title: 'Every booking earns you\nSuper Coins',
        buttonText: 'Book Now',
        gradientColors: [const Color(0xFF6b21a8), const Color(0xFF4c1d95)],
        icon: FontAwesomeIcons.coins,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManpowerListScreen())),
      ),
    ];

    return FadeInRight(
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 150.0,
              viewportFraction: 0.9,
              enableInfiniteScroll: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              onPageChanged: (index, reason) {
                setState(() => _currentBannerIndex = index);
              },
            ),
            items: banners,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: banners.asMap().entries.map((entry) {
              return Container(
                width: 6.0,
                height: 6.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentBannerIndex == entry.key
                      ? AppColors.primary
                      : Colors.white24,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBanner({
    required String title,
    required String buttonText,
    required List<Color> gradientColors,
    required IconData icon,
    bool showIcon = true,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(100, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(buttonText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      if (buttonText == 'EXPLORE MORE') const SizedBox(width: 4),
                      if (buttonText == 'EXPLORE MORE') const Icon(Icons.arrow_forward_outlined, size: 14, color: Colors.black),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showIcon)
            Positioned(
              right: 15,
              bottom: 15,
              child: Icon(
                icon,
                size: 70,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioListScreen())),
            child: _buildCategoryCard(
              title: 'Studios',
              subtitle: 'Find The Perfect Shooting Space',
              color: const Color(0xFF4FC3F7),
              icon: Icons.screenshot_monitor, // Closest to light icon in image
              isFullWidth: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipmentListScreen())),
                  child: _buildCategoryCard(
                    title: 'Equipment',
                    subtitle: 'Cameras, Lights, Audio & More',
                    color: const Color(0xFFFF5252),
                    icon: Icons.camera_alt_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManpowerListScreen())),
                  child: _buildCategoryCard(
                    title: 'Manpower',
                    subtitle: 'Photographers, Editors, Crew',
                    color: const Color(0xFFFF9800),
                    icon: Icons.groups_outlined,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      width: double.infinity,
      height: isFullWidth ? 110 : 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: isFullWidth ? 80 : 60,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: isFullWidth ? 200 : null,
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessGuide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Book now in 3 simple steps!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep(1, 'Choose a service\nfor you production', Icons.videocam),
              _buildStep(2, 'Choose location &\ntime slot', Icons.storefront),
              _buildStep(3, 'Secure booking', Icons.payments),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text, IconData icon) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFFCA9AFF), size: 28),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Step $number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedList() {
    if (_isLoadingRecommended) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_recommendedListings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text("New listings coming soon!", style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
        itemCount: _recommendedListings.length > 5 ? 5 : _recommendedListings.length,
        itemBuilder: (context, index) {
          final listing = _recommendedListings[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => StudioDetailScreen(studio: listing))
              );
            },
            child: Container(
              width: 200,
              height: 270,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: (listing.images != null && listing.images.isNotEmpty)
                              ? Image.network(
                                  listing.images[0],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: Icon(Icons.image, color: Colors.white24),
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 10),
                                const SizedBox(width: 2),
                                Text(
                                  listing.avgRating.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.listingTitle, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                listing.subCategory,
                                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "₹${listing.pricePerDay ?? listing.pricePerHour ?? '0'}",
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFCA9AFF), fontSize: 14),
                              ),
                              WishlistButtonWidget(
                                listing: listing,
                                size: 20,
                                inactiveColor: Colors.white38,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
