import 'package:flutter/material.dart';
import '../studio/studio_detail_screen.dart';
import '../studio/studio_list_screen.dart';
import '../equipment/equipment_list_screen.dart';
import '../manpower/manpower_list_screen.dart';
import '../checkout/checkout_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';
import '../../models/listing_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/navigation.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _selectedCategoryForCheckout;
  List<ListingModel> _recommendedProducts = [];
  bool _isLoadingRecommendations = true;
  int _userCoins = 0;
  int _coinsToNextReward = 200;

  // Cart state managed locally (no infinite stream polling)
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoadingCart = true;

  // Selected filters from home screen
  DateTime? _sharedFilterDate;
  int? _sharedFilterCount;
  String? _sharedFilterRentalType;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadRecommendations();
    // Listen to tab switching to refresh the cart items automatically when cart is selected
    AppNavigation.selectedTabIndex.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (AppNavigation.selectedTabIndex.value == 3) {
      _loadCart();
    }
  }

  @override
  void dispose() {
    AppNavigation.selectedTabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  Future<void> _loadCart() async {
    if (!mounted) return;
    setState(() => _isLoadingCart = true);
    
    // Load timing filter from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('filter_date');
    final countVal = prefs.getInt('filter_count');
    final rentalTypeVal = prefs.getString('filter_rental_type');
    
    final items = await CartService.getCartItems();
    if (mounted) {
      setState(() {
        _cartItems = items;
        if (dateStr != null) {
          _sharedFilterDate = DateTime.tryParse(dateStr);
        }
        _sharedFilterCount = countVal;
        _sharedFilterRentalType = rentalTypeVal;
        _isLoadingCart = false;
      });
    }
  }

  Future<void> _refreshCartItems() async {
    final items = await CartService.getCartItems();
    if (mounted) {
      setState(() {
        _cartItems = items;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final results = await Future.wait([
        ApiService.getStudios(),
        ApiService.getEquipment(),
        ApiService.getUserBookings(),
      ]);
      
      final List<ListingModel> loaded = [];
      final List<ListingModel> studios = results[0] as List<ListingModel>;
      final List<ListingModel> equipment = results[1] as List<ListingModel>;
      final List<dynamic> bookings = results[2] as List<dynamic>;

      loaded.addAll(studios);
      loaded.addAll(equipment);
      loaded.shuffle(); // Shuffle for variance

      final bookingCount = bookings.length;

      if (mounted) {
        setState(() {
          _recommendedProducts = loaded;
          _isLoadingRecommendations = false;
          _userCoins = bookingCount * 100;
          _coinsToNextReward = 200 - (_userCoins % 200);
          if (_coinsToNextReward == 0) _coinsToNextReward = 200;
        });
      }
    } catch (e) {
      print("Error loading recommendations: $e");
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  void _resetCheckout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedCategoryForCheckout = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: Stack(
        children: [
          _buildCartList(context),
          _buildTopHeader(context),
        ],
      ),
    );
  }


  Widget _buildTopHeader(BuildContext context) {
    final isCheckout = _selectedCategoryForCheckout != null;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isCheckout)
              Positioned(
                left: 0,
                child: IconButton(
                  onPressed: _resetCheckout,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            Text(
              isCheckout ? 'Cart' : 'My Shopping Cart',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            if (!isCheckout)
              Positioned(
                right: 0,
                child: IconButton(
                  onPressed: () => _showClearCartDialog(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(BuildContext context) {
    if (_isLoadingCart) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFCA9AFF)),
      );
    }

    // Inline builder using local state
    return _buildCartContent(context, _cartItems);
  }

  Widget _buildCartContent(BuildContext context, List<Map<String, dynamic>> cartItems) {
    if (cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  size: 100, color: Colors.white.withOpacity(0.05)),
            ),
            const SizedBox(height: 24),
            const Text('Your cart is feeling light',
                style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Add some items to get started!',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }

    // Group items by category
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in cartItems) {
      String rawCat = (item['category'] ?? 'Other').toString().toLowerCase();
      String cat = 'Other';
      if (rawCat == 'studio' || rawCat == 'studios') {
        cat = 'Studio';
      } else if (rawCat == 'equipment' || rawCat == 'equipments') {
        cat = 'Equipment';
      } else if (rawCat == 'manpower') {
        cat = 'Manpower';
      } else {
        cat = item['category'] ?? 'Other';
      }

      if (!groupedItems.containsKey(cat)) {
        groupedItems[cat] = [];
      }
      groupedItems[cat]!.add(item);
    }

    // Filtering if a category is selected for checkout
    final displayedCategories = _selectedCategoryForCheckout != null
        ? groupedItems.entries.where((e) =>
            (e.key == 'Studio' && _selectedCategoryForCheckout == 'Studios') ||
            (e.key == 'Equipment' && _selectedCategoryForCheckout == 'Equipment') ||
            (e.key == 'Manpower' && _selectedCategoryForCheckout == 'Manpower') ||
            (e.key == _selectedCategoryForCheckout)).toList()
        : groupedItems.entries.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        if (_selectedCategoryForCheckout == null) ...[
          if (groupedItems.containsKey('Studio'))
            _buildCategorySection(context, 'Studios', groupedItems['Studio']!, const Color(0xFF4FC3F7)),
          if (groupedItems.containsKey('Equipment'))
            _buildCategorySection(context, 'Equipment', groupedItems['Equipment']!, const Color(0xFFFF5252)),
          if (groupedItems.containsKey('Manpower'))
            _buildCategorySection(context, 'Manpower', groupedItems['Manpower']!, const Color(0xFFFFB74D)),
          ...groupedItems.entries
              .where((e) => e.key != 'Studio' && e.key != 'Equipment' && e.key != 'Manpower')
              .map((e) => _buildCategorySection(context, e.key, e.value, const Color(0xFFCA9AFF))),
        ] else ...[
          // Show only the selected category section with order summary
          for (var e in displayedCategories) ...[
            _buildCategorySection(
              context,
              e.key == 'Studio' ? 'Studios' : e.key,
              e.value,
              _getCategoryColor(e.key == 'Studio' ? 'Studios' : e.key),
            ),
            _buildSecurityDepositCard(context),
            _buildRecommendationsSection(context, e.value),
            const SizedBox(height: 24),
            _buildOrderSummary(e.value),
            const SizedBox(height: 24),
            _buildProceedToCheckoutButton(e.value),
            const SizedBox(height: 12),
            _buildRemainingBalanceDisclaimer(e.value),
          ],
        ],
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, String title, List<Map<String, dynamic>> items, Color bannerColor) {
    // ── Total ──────────────────────────────────────────────────────────
    double total = 0;
    for (final item in items) {
      final price = item['price_per_day'] ?? item['price_per_hour'] ?? item['price'] ?? 0;
      final double pv = (price is num) ? price.toDouble() : (double.tryParse(price.toString()) ?? 0.0);
      final int qty  = item['quantity'] ?? 1;
      total += pv * qty;
    }
    // ── Date / Time / Duration ─────────────────────────────────────────
    String dateDisplay     = '';
    String timeDisplay     = '';
    String durationDisplay = '';

    DateTime? startDt;
    if (items.isNotEmpty && items.first['start_date'] != null) {
      startDt = DateTime.tryParse(items.first['start_date'].toString());
    }
    startDt ??= _sharedFilterDate;

    if (startDt != null) {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      dateDisplay = '${startDt.day} ${months[startDt.month - 1]}';
      final h    = startDt.hour;
      final m    = startDt.minute;
      final ampm = h >= 12 ? 'PM' : 'AM';
      final h12  = h % 12 == 0 ? 12 : h % 12;
      timeDisplay = '$h12:${m.toString().padLeft(2, '0')} $ampm';
    }

    String? itemRentalType;
    if (items.isNotEmpty && items.first['rental_type'] != null) {
      itemRentalType = items.first['rental_type'].toString();
    }
    itemRentalType ??= _sharedFilterRentalType;

    if (items.isNotEmpty && items.first['end_date'] != null && startDt != null) {
      final endDt = DateTime.tryParse(items.first['end_date'].toString());
      if (endDt != null) {
        if (itemRentalType == 'Daily') {
          final days = endDt.difference(startDt).inDays;
          if (days > 0) {
            durationDisplay = '$days ${days == 1 ? "day" : "days"}';
          } else {
            final hrs = endDt.difference(startDt).inHours;
            durationDisplay = '$hrs hrs';
          }
        } else {
          final hrs = endDt.difference(startDt).inHours;
          if (hrs > 0) durationDisplay = '$hrs hrs';
        }
      }
    }
    if (durationDisplay.isEmpty && _sharedFilterCount != null) {
      durationDisplay = '${_sharedFilterCount} ${itemRentalType == 'Hourly' ? 'hrs' : 'days'}';
    }

    final bool hasDateTime = dateDisplay.isNotEmpty || timeDisplay.isNotEmpty || durationDisplay.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + total ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
            child: Text(
              'View Cart for $title (${items.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
            child: Text(
              'Total Cart Value: ₹${_formatAmount(total)}',
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
            ),
          ),

          // ── Super-coins banner ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E24AA), Color(0xFF29B6F6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                // Two overlapping coin circles
                SizedBox(
                  width: 28, height: 22,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0, top: 1,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFD54F),
                          ),
                          child: const Center(
                            child: Icon(Icons.star_rounded, color: Color(0xFFFF8F00), size: 11),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10, top: 0,
                        child: Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFB300),
                            border: Border.all(color: const Color(0xFF8E24AA), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.star_rounded, color: Colors.white, size: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      children: [
                        const TextSpan(text: 'You will get '),
                        TextSpan(
                          text: '${items.length * 100} super coins',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' on this booking'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Date / Time / Duration row ─────────────────────────────────
          if (hasDateTime)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (dateDisplay.isNotEmpty) ...[
                      const Icon(Icons.calendar_today_outlined, color: Color(0xFFCA9AFF), size: 16),
                      const SizedBox(width: 6),
                      Text(dateDisplay, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                    ],
                    if (timeDisplay.isNotEmpty) ...[
                      const Icon(Icons.access_time_rounded, color: Color(0xFFCA9AFF), size: 16),
                      const SizedBox(width: 6),
                      Text(timeDisplay, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                    ],
                    if (durationDisplay.isNotEmpty) ...[
                      const Icon(Icons.hourglass_top_rounded, color: Color(0xFFCA9AFF), size: 16),
                      const SizedBox(width: 6),
                      Text(durationDisplay, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        final rawCat = title.toLowerCase();
                        final sheetCat = rawCat.contains('studio') ? 'Studios'
                            : rawCat.contains('equipment') ? 'Equipment' : 'Manpower';
                        _showDateConfirmationSheet(context, sheetCat);
                      },
                      child: const Text('EDIT',
                          style: TextStyle(
                            color: Color(0xFFCA9AFF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          )),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 14),
          // ── Item cards ────────────────────────────────────────────────
          if (items.length > 2)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 440),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: items
                      .map((item) => Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                            child: _buildProductRow(context, item),
                          ))
                      .toList(),
                ),
              ),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: _buildProductRow(context, item),
                )),

          // ── Proceed button ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: ValueKey('proceed_rent_button_$title'),
                onPressed: () async {
                  setState(() => _selectedCategoryForCheckout = title);
                  await _loadCart();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCA9AFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: Text(
                  'Proceed to Rent $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1E1E1E), // Dark text for contrast
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFF444444)),

          // ── Continue shopping link ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: TextButton(
                onPressed: () {
                  if (title == 'Studios') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StudioListScreen()));
                  } else if (title == 'Equipment') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EquipmentListScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ManpowerListScreen()));
                  }
                },
                child: Text(
                  'Continue shopping on ${title == 'Equipment' ? 'Equipments' : title}',
                  style: const TextStyle(
                    color: Color(0xFFCA9AFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// Compact amount formatter: 9000 → "9,000"
  String _formatAmount(double v) {
    final int iv = v.toInt();
    final s = iv.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _buildSecurityDepositCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB574FF),
            Color(0xFF8F4CFA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB574FF).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Shield badge graphic
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E0E3D).withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E0E3D).withOpacity(0.15), width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF1E0E3D),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Header text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Refundable Deposit',
                          style: TextStyle(
                            color: Color(0xFF1E0E3D),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E0E3D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AD',
                            style: TextStyle(
                              color: Color(0xFFB574FF),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '100% safe & refundable security hold',
                      style: TextStyle(
                        color: const Color(0xFF1E0E3D).withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your deposit is returned after you give back the equipment and the vendor checks it. If there is no damage or delay, the full deposit will be refunded.',
            style: TextStyle(
              color: const Color(0xFF1E0E3D).withOpacity(0.85),
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Premium inline Learn More action button
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Security Deposit Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: const Text(
                        'To protect vendors, a temporary security deposit is held. This is completely refunded within 24 hours of returning the equipment in good condition.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it', style: TextStyle(color: Color(0xFFCA9AFF), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0E3D).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E0E3D).withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF1E0E3D), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Learn More',
                        style: TextStyle(
                          color: const Color(0xFF1E0E3D).withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Verified badge trust row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF1E0E3D), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Safe Booking',
                    style: TextStyle(
                      color: const Color(0xFF1E0E3D).withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? title) {
    if (title == null) return const Color(0xFFCA9AFF);
    final t = title.toLowerCase();
    if (t == 'studios' || t == 'studio') return const Color(0xFF4FC3F7);
    if (t == 'equipment' || t == 'equipments') return const Color(0xFFFF5252);
    if (t == 'manpower') return const Color(0xFFFFB74D);
    return const Color(0xFFCA9AFF);
  }


  Widget _buildOrderSummary(List<Map<String, dynamic>> items) {
    double totalMRP = 0;
    for (var item in items) {
      final price = item['price_per_day'] ?? item['price_per_hour'] ?? item['price'] ?? 0;
      final double priceVal = (price is num) ? price.toDouble() : (double.tryParse(price.toString()) ?? 0.0);
      final int qty = item['quantity'] ?? 1;
      totalMRP += priceVal * qty;
    }
    // Sum security deposit from items database records
    double securityDeposit = items.fold(0.0, (sum, item) {
      final dep = item['deposit_amount'];
      final val = (dep is num) ? dep.toDouble() : (double.tryParse(dep?.toString() ?? '0') ?? 0.0);
      final int qty = item['quantity'] ?? 1;
      return sum + (val * qty);
    });

    double platformFee = securityDeposit * 0.10; // 10% of security deposit
    double payableNow = securityDeposit + platformFee; // User pays deposit + 10% platform fee

    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Order Summary rows
            _buildSummaryRow('Total MRP', '₹${totalMRP.toStringAsFixed(0)}'),
            _buildSummaryRow('Platform Fee', '₹${platformFee.toStringAsFixed(0)}'),
            const Divider(color: Colors.white10, height: 24),
            _buildSummaryRow('Security Deposit', '₹${securityDeposit.toStringAsFixed(0)}', showInfo: true, isBold: true),
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '(Payable Now)',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  '₹${payableNow.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFCA9AFF), // Bold lilac/purple accent
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isBold = false, bool showInfo = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  )),
              if (showInfo) ...[
                const SizedBox(width: 4),
                Icon(Icons.info_outline, color: Colors.white.withOpacity(0.3), size: 14),
              ],
            ],
          ),
          Text(value,
              style: TextStyle(
                color: isDiscount ? const Color(0xFF2EC4B6) : (isBold ? Colors.white : Colors.white),
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildProceedToCheckoutButton(List<Map<String, dynamic>> items) {
    return Container(
      key: const ValueKey('proceed_checkout_container'),
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFB19FFB), // Gorgeous Lavender
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CheckoutScreen(items: items)),
          );
          // Reload cart when returning from checkout screen
          _loadCart();
        },
        borderRadius: BorderRadius.circular(18),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Proceed to Checkout',
                style: TextStyle(
                  color: Color(0xFF1E0E3D), // Deep dark violet/black text
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Color(0xFF1E0E3D), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemainingBalanceDisclaimer(List<Map<String, dynamic>> items) {
    double totalMRP = 0;
    for (var item in items) {
      final price = item['price_per_day'] ?? item['price_per_hour'] ?? item['price'] ?? 0;
      final double priceVal = (price is num) ? price.toDouble() : (double.tryParse(price.toString()) ?? 0.0);
      final int qty = item['quantity'] ?? 1;
      totalMRP += priceVal * qty;
    }
    double discount = totalMRP * 0.06;
    double platformFee = 10;
    double couponDiscount = 100.0;
    
    double threshold = 5000.0;
    if (totalMRP >= 5000.0) {
      threshold = 15000.0;
    }
    if (totalMRP >= 15000.0) {
      threshold = 30000.0;
    }
    final discountAmount = threshold * 0.08;
    final difference = threshold - totalMRP;
    final double extraDiscount = difference <= 0 ? discountAmount : 0.0;

    double rentalTotal = totalMRP - discount - extraDiscount - couponDiscount + platformFee;
    if (rentalTotal < 0) rentalTotal = 0;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16, left: 8, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The remaining rental balance of ₹${rentalTotal.toStringAsFixed(0)} is to be paid directly to the studio/vendor at the time of pickup.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(String? startStr, String? endStr) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    DateTime start;
    DateTime end;
    
    if (startStr != null) {
      start = DateTime.tryParse(startStr) ?? _sharedFilterDate ?? DateTime.now();
    } else {
      start = _sharedFilterDate ?? DateTime.now();
    }
    
    final durationDays = _sharedFilterRentalType == 'Daily' ? (_sharedFilterCount ?? 1) : 1;
    
    if (endStr != null) {
      end = DateTime.tryParse(endStr) ?? start.add(Duration(days: durationDays));
    } else {
      end = start.add(Duration(days: durationDays));
    }
    
    if (end.isBefore(start)) {
      end = start.add(Duration(days: durationDays));
    }
    
    final daysDiff = end.difference(start).inDays;
    final displayDays = daysDiff == 0 ? 1 : daysDiff;
    
    return "${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day} ($displayDays ${displayDays == 1 ? 'Day' : 'Days'})";
  }

  Widget _imgPlaceholder() => Container(
        width: 78, height: 78,
        decoration: BoxDecoration(
          color: const Color(0xFF444444),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 28),
      );

  Widget _buildProductRow(BuildContext context, Map<String, dynamic> item) {
    final price      = item['price_per_day'] ?? item['price_per_hour'] ?? item['price'] ?? 0;
    final double pv  = (price is num) ? price.toDouble() : (double.tryParse(price.toString()) ?? 0.0);
    final int qty    = item['quantity'] ?? 1;
    final double total = pv * qty;
    final bool isPerDay = item['price_per_day'] != null;
    final itemId = item['id'] ?? item['listing_id'] ?? item['cart_item_id'];
    
    // Fallback info
    final String title = item['listing_title'] ?? 'N/A';
    final String category = (item['category'] ?? '').toString();
    final String location = item['location_address'] ?? '';
    final String subtitle = '${category.isNotEmpty ? category : 'Item'}${location.isNotEmpty ? ' · $location' : ''}';
    final String durationLabel =
        '$qty ${isPerDay ? (qty == 1 ? 'day' : 'days') : (qty == 1 ? 'hr' : 'hrs')}';
    final String rateLabel     = '₹${_formatAmount(pv)}/${isPerDay ? 'day' : 'hr'}';

    return Dismissible(
      key: ValueKey('di_${itemId}_${item['start_date']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await CartService.removeFromCart(item);
        await _refreshCartItems();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            GestureDetector(
              onTap: () async {
                final listingId = item['id'] ?? item['listing_id'];
                if (listingId == null) return;
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                      child: CircularProgressIndicator(color: Color(0xFFCA9AFF))),
                );
                try {
                  final listing =
                      await ApiService.getListingDetail(listingId.toString());
                  if (context.mounted) Navigator.pop(context);
                  if (listing != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => StudioDetailScreen(studio: listing)),
                    );
                  }
                } catch (_) {
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (item['image_1'] != null && item['image_1'].toString().isNotEmpty)
                    ? Image.network(
                        ApiService.getSafeImageUrl(item['image_1']),
                        width: 84, height: 84, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
            ),
            const SizedBox(width: 14),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Stepper
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Stepper
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                bottomLeft: Radius.circular(6),
                              ),
                              onTap: () {
                                if (qty > 1) {
                                  setState(() {
                                    final index = _cartItems.indexWhere((x) => x['cart_item_id'] == item['cart_item_id']);
                                    if (index != -1) {
                                      _cartItems[index] = Map<String, dynamic>.from(_cartItems[index]);
                                      _cartItems[index]['quantity'] = qty - 1;
                                    }
                                  });
                                  CartService.updateCartItemQuantity(item, qty - 1).then((_) {
                                    _refreshCartItems();
                                  }).catchError((e) {
                                    print("Error updating quantity: $e");
                                    _refreshCartItems();
                                  });
                                } else {
                                  setState(() {
                                    _cartItems.removeWhere((x) => x['cart_item_id'] == item['cart_item_id']);
                                  });
                                  CartService.removeFromCart(item).then((_) {
                                    _refreshCartItems();
                                  }).catchError((e) {
                                    print("Error removing item: $e");
                                    _refreshCartItems();
                                  });
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(Icons.remove, color: Colors.white54, size: 14),
                              ),
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            InkWell(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                              onTap: () {
                                setState(() {
                                  final index = _cartItems.indexWhere((x) => x['cart_item_id'] == item['cart_item_id']);
                                  if (index != -1) {
                                    _cartItems[index] = Map<String, dynamic>.from(_cartItems[index]);
                                    _cartItems[index]['quantity'] = qty + 1;
                                  }
                                });
                                CartService.updateCartItemQuantity(item, qty + 1).then((_) {
                                  _refreshCartItems();
                                }).catchError((e) {
                                  print("Error updating quantity: $e");
                                  _refreshCartItems();
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(Icons.add, color: Color(0xFFCA9AFF), size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Location/Subtitle
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Duration & Rate
                  Text(
                    '$durationLabel · $rateLabel',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Total and Edit/Remove Buttons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Total
                      Text(
                        '₹${_formatAmount(total)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // EDIT
                      GestureDetector(
                        onTap: () {
                          final rawCat = (item['category'] ?? '').toString().toLowerCase();
                          final sheetCat =
                              (rawCat.contains('studio')) ? 'Studios'
                              : (rawCat.contains('equipment')) ? 'Equipment'
                              : 'Manpower';
                          _showDateConfirmationSheet(context, sheetCat, itemToEdit: item);
                        },
                        child: const Text(
                          'EDIT',
                          style: TextStyle(
                            color: Color(0xFFCA9AFF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // REMOVE
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _cartItems.removeWhere((x) => x['cart_item_id'] == item['cart_item_id']);
                          });
                          CartService.removeFromCart(item).then((_) {
                            _refreshCartItems();
                          }).catchError((e) {
                            print("Error removing item: $e");
                            _refreshCartItems();
                          });
                        },
                        child: const Text(
                          'REMOVE',
                          style: TextStyle(
                            color: Colors.red, // Vibrant red color as requested
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Empty your cart?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This will remove all items from your shopping cart.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep them', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              await CartService.clearCart();
              await _loadCart();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context, List<Map<String, dynamic>> cartItems) {
    if (_isLoadingRecommendations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFCA9AFF)),
        ),
      );
    }

    final recommendations = _recommendedProducts.take(3).toList();
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate cart total dynamically
    double cartTotal = 0;
    for (var item in cartItems) {
      final price = item['price_per_day'] ?? item['price_per_hour'] ?? item['price'] ?? 0;
      final double priceVal = (price is num) ? price.toDouble() : (double.tryParse(price.toString()) ?? 0.0);
      final int qty = item['quantity'] ?? 1;
      cartTotal += priceVal * qty;
    }

    double threshold = 5000.0;
    if (cartTotal >= 5000.0) {
      threshold = 15000.0;
    }
    if (cartTotal >= 15000.0) {
      threshold = 30000.0;
    }
    final discountAmount = threshold * 0.08;
    final difference = threshold - cartTotal;
    final bannerText = difference > 0
        ? 'Add ₹${difference.toStringAsFixed(0)} worth items to get ₹${discountAmount.toStringAsFixed(0)} extra off'
        : 'Congratulations! You unlocked a ₹${discountAmount.toStringAsFixed(0)} extra discount!';

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1E1035), // Deep Obsidian Purple
              Color(0xFF110722), // Very Dark Violet
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFFCA9AFF).withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          children: [
            // Top Pill-Shaped Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFCA9AFF),
                    Color(0xFF9C27B0),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                bannerText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Horizontal list of camera cards
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final listing = recommendations[index];
                  String title = listing.listingTitle;
                  if (index == 0) {
                    title = "RED Digital Cinema";
                  }
                  
                  final price = listing.pricePerDay ?? listing.pricePerHour ?? 0;
                  final double priceVal = (price is num) ? price.toDouble() : (double.tryParse(price.toString()) ?? 0.0);
                  
                  String priceLabel = "₹${priceVal.toStringAsFixed(0)}/day";
                  if (index == 0) {
                    priceLabel = "₹7,500/day";
                  } else if (index == 1) {
                    priceLabel = "₹4,500/day";
                  }
                  
                  final image = (listing.images != null && listing.images.isNotEmpty) ? ApiService.getSafeImageUrl(listing.images.first) : '';
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudioDetailScreen(studio: listing),
                        ),
                      );
                    },
                    child: Container(
                      width: 155,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525), // Solid dark grey card background
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                child: AspectRatio(
                                  aspectRatio: 1.3,
                                  child: image.isNotEmpty
                                      ? Image.network(
                                          image,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.white10,
                                            child: const Icon(Icons.broken_image_outlined, color: Colors.white24, size: 24),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.white10,
                                          child: const Icon(Icons.image, color: Colors.white24, size: 24),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'CAMERA',
                                    style: TextStyle(color: Color(0xFFCA9AFF), fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  priceLabel,
                                  style: const TextStyle(
                                    color: Color(0xFFCA9AFF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      '4.8 (24)',
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
  }

  void _showDateConfirmationSheet(BuildContext context, String category, {Map<String, dynamic>? itemToEdit}) {
    // Local state inside the sheet, loaded from state or SharedPreferences defaults
    String rentalType = _sharedFilterRentalType ?? 'Hourly';
    int count = _sharedFilterCount ?? (rentalType == 'Hourly' ? 4 : 1);
    DateTime date = _sharedFilterDate ?? DateTime.now();
    String time = '10:00'; // Default start time

    if (itemToEdit != null) {
      rentalType = itemToEdit['rental_type'] ?? 'Hourly';
      count = itemToEdit['duration_count'] ?? itemToEdit['quantity'] ?? 1;
      if (itemToEdit['start_date'] != null) {
        try {
          final parsed = DateTime.parse(itemToEdit['start_date'].toString());
          date = parsed;
          final h = parsed.hour.toString().padLeft(2, '0');
          final m = parsed.minute.toString().padLeft(2, '0');
          time = '$h:$m';
        } catch (_) {}
      }
    } else if (_sharedFilterDate != null) {
      final h = _sharedFilterDate!.hour.toString().padLeft(2, '0');
      final m = _sharedFilterDate!.minute.toString().padLeft(2, '0');
      time = '$h:$m';
    }

    final List<String> timeSlots = [
      '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            // Generate 7 consecutive days starting from today (including weekends)
            final List<DateTime> days = [];
            DateTime d = DateTime.now();
            for (int i = 0; i < 7; i++) {
              days.add(d);
              d = d.add(const Duration(days: 1));
            }

            // If selected date is outside of 7 days, append it and sort
            bool dateExists = false;
            for (var day in days) {
              if (day.day == date.day && day.month == date.month && day.year == date.year) {
                dateExists = true;
                break;
              }
            }
            if (!dateExists) {
              days.add(date);
              days.sort((a, b) => a.compareTo(b));
            }

            final dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

            // Booking summary calculations
            final startHour = int.tryParse(time.split(':')[0]) ?? 10;
            final startMinute = int.tryParse(time.split(':')[1]) ?? 0;
            final startDT = DateTime(date.year, date.month, date.day, startHour, startMinute);
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

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
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
                          'Confirm Date & Time',
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
                                        // Update default count when switching toggles
                                        count = tab == 'Hourly' ? 4 : 1;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: sel ? const Color(0xFF9C27B0) : Colors.transparent,
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
                              Text(
                                rentalType == 'Hourly' ? 'Max 12 hours' : 'Max 30 days',
                                style: const TextStyle(color: Color(0xFF9C27B0), fontSize: 11),
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
                          // Quick duration selection chips (supports 2hrs, 3hrs, 4hrs, etc.)
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
                                      // Update custom picked date return timing inside sheet automatically
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel ? const Color(0xFF9C27B0) : const Color(0xFF2A2A2A),
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
                                    initialDate: date.isBefore(DateTime.now()) ? DateTime.now() : date,
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
                                      date = pickedDate;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9C27B0).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_month, color: Color(0xFFCA9AFF), size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${months[date.month - 1]} ${date.day}',
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
                                  final sel = d.day == date.day && d.month == date.month;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () => setSheet(() => date = d),
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
                                // Full Calendar picker button card at the end of the ribbon
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: date.isBefore(DateTime.now()) ? DateTime.now() : date,
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
                                          date = pickedDate;
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 60,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9C27B0).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.calendar_month_outlined, color: Color(0xFFCA9AFF), size: 18),
                                          SizedBox(height: 4),
                                          Text(
                                            'More...',
                                            style: TextStyle(
                                              color: Color(0xFFCA9AFF),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Start Time Selection Wrap
                          Text(
                            rentalType == 'Hourly'
                                ? (category == 'Equipment' ? 'SELECT PICKUP TIME'
                                    : category == 'Manpower' ? 'SELECT SERVICE START TIME'
                                    : 'SELECT START TIME')
                                : 'SELECT PICKUP TIME',
                            style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
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
                                    color: sel ? const Color(0xFF9C27B0).withOpacity(0.15) : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: sel ? const Color(0xFF9C27B0) : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    slot,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: sel ? const Color(0xFF9C27B0) : Colors.white54,
                                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Booking Summary preview card
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'BOOKING SUMMARY',
                                style: TextStyle(color: Color(0xFF9C27B0), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
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
                                    Expanded(child: _summaryTile(Icons.category_outlined, 'CATEGORY', category)),
                                    Expanded(child: _summaryTile(Icons.calendar_today_outlined, 'DATE', fmt(date))),
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

                  // Apply & Checkout Action Button
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).padding.bottom + 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);

                          final startHour = int.tryParse(time.split(':')[0]) ?? 10;
                          final startMinute = int.tryParse(time.split(':')[1]) ?? 0;
                          final startDT = DateTime(date.year, date.month, date.day, startHour, startMinute);
                          final endDT = rentalType == 'Hourly'
                              ? startDT.add(Duration(hours: count))
                              : startDT.add(Duration(days: count));

                          // 1. Immediately update local storage (SharedPreferences)
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('filter_date', startDT.toIso8601String());
                          await prefs.setInt('filter_count', count);
                          await prefs.setString('filter_rental_type', rentalType);
                          await prefs.setString('filter_time', time);
                          await prefs.setString('filter_category', category);

                          // 2. Instantly update UI state and cache for real-time visual response
                          if (mounted) {
                            setState(() {
                              _sharedFilterDate = startDT;
                              _sharedFilterCount = count;
                              _sharedFilterRentalType = rentalType;

                              // Update ALL items in this category to have the new timing/dates/quantity locally
                              for (int i = 0; i < _cartItems.length; i++) {
                                final itemCat = (_cartItems[i]['category'] ?? '').toString().toLowerCase();
                                final isMatch = (category == 'Studios' && itemCat.contains('studio')) ||
                                                (category == 'Equipment' && itemCat.contains('equipment')) ||
                                                (category == 'Manpower' && itemCat.contains('manpower')) ||
                                                (itemCat == category.toLowerCase());
                                if (isMatch) {
                                  _cartItems[i] = Map<String, dynamic>.from(_cartItems[i]);
                                  _cartItems[i]['quantity'] = count;
                                  _cartItems[i]['start_date'] = startDT.toIso8601String();
                                  _cartItems[i]['end_date'] = endDT.toIso8601String();
                                  _cartItems[i]['rental_type'] = rentalType;
                                  _cartItems[i]['duration_count'] = count;
                                }
                              }
                            });
                          }

                          // 3. Perform network synchronization asynchronously in the background
                          // Find all items in this category to update on backend
                          final itemsToSync = _cartItems.where((item) {
                            final itemCat = (item['category'] ?? '').toString().toLowerCase();
                            return (category == 'Studios' && itemCat.contains('studio')) ||
                                   (category == 'Equipment' && itemCat.contains('equipment')) ||
                                   (category == 'Manpower' && itemCat.contains('manpower')) ||
                                   (itemCat == category.toLowerCase());
                          }).toList();

                          Future.forEach(itemsToSync, (Map<String, dynamic> item) async {
                            try {
                              await CartService.removeFromCart(item);
                              final updatedItem = Map<String, dynamic>.from(item);
                              updatedItem['start_date'] = startDT.toIso8601String();
                              updatedItem['end_date'] = endDT.toIso8601String();
                              updatedItem['rental_type'] = rentalType;
                              updatedItem['duration_count'] = count;
                              updatedItem['quantity'] = count;
                              await CartService.addToCart(updatedItem);
                            } catch (e) {
                              print("Error syncing item in background: $e");
                            }
                          }).then((_) {
                            _refreshCartItems();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCA9AFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: Text(
                          itemToEdit != null ? 'Update Time' : 'Proceed to Checkout',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
}

