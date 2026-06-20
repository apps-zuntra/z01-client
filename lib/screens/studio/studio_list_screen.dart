import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import 'package:animate_do/animate_do.dart';
import '../studio/studio_detail_screen.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/listing_model.dart';
import '../../widgets/wishlist_button_widget.dart';
import '../../widgets/category_watermark_painters.dart';

class StudioListScreen extends StatefulWidget {
  final String? initialSubCategory;
  const StudioListScreen({super.key, this.initialSubCategory});

  @override
  State<StudioListScreen> createState() => _StudioListScreenState();
}

class _StudioListScreenState extends State<StudioListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _subCategories = [
    {'title': 'Green Screen', 'colors': [const Color(0xFFEF5350), const Color(0xFFB71C1C)], 'watermark': 'backdrop'},
    {'title': 'Photography', 'colors': [const Color(0xFFE57373), const Color(0xFFC62828)], 'watermark': 'camera'},
    {'title': 'Recording', 'colors': [const Color(0xFFCA9AFF), const Color(0xFF6A1B9A)], 'watermark': 'sound'},
    {'title': 'Podcast', 'colors': [const Color(0xFF7986CB), const Color(0xFF1A237E)], 'watermark': 'sound'},
    {'title': 'Event', 'colors': [const Color(0xFF4FC3F7), const Color(0xFF1B5E20)], 'watermark': 'backdrop'},
    {'title': 'Rehearsal', 'colors': [const Color(0xFF4CAF50), const Color(0xFF0277BD)], 'watermark': 'sound'},
    {'title': 'Fashion Shoot', 'colors': [const Color(0xFFFFB74D), const Color(0xFFE65100)], 'watermark': 'camera'},
    {'title': 'AR/VR Capture', 'colors': [const Color(0xFFFF7043), const Color(0xFFBF360C)], 'watermark': 'drone'},
  ];

  List<ListingModel> _allStudios = [];
  List<ListingModel> _filteredStudios = [];
  bool _isSortingByProximity = false;
  bool _isLoading = true;
  double? _userLat;
  double? _userLng;
  String _searchQuery = '';

  // Filter state
  static const Color _accent = Color(0xFFFF527B);
  static const Color _purple = Color(0xFFCA9AFF);
  double _maxPrice = 50000;
  double _filterMinPrice = 0;
  double _filterMaxPrice = 50000;
  String? _filterStudioType;
  String _filterLocation = '';
  DateTime? _filterDate;
  String? _filterStartTime;
  List<String> _filterAmenities = [];
  List<String> _filterRatings = [];
  int _activeFilterCount = 0;

  final List<String> _studioTypes = ['All Types', 'Photography', 'Videography', 'Podcast', 'Event Space', 'Green Screen', 'White Cyclorama', 'Home / Lifestyle Studio'];
  final List<String> _amenityOptions = ['Air Conditioning', 'WiFi', 'Parking', 'Makeup Room', 'Washroom', 'Green Room'];
  final List<String> _timeSlots = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00'];
  final List<String> _ratingOptions = ['3-4 Ratings', '4-4.5 Ratings', '4.5-5 Ratings'];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadRecentStudios();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _applyFilters();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<ListingModel> result = List.from(_allStudios);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) =>
        e.listingTitle.toLowerCase().contains(q) ||
        e.subCategory.toLowerCase().contains(q) ||
        (e.brand?.toLowerCase().contains(q) ?? false) ||
        (e.locationAddress?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    result = result.where((e) {
      final price = e.pricePerDay ?? e.pricePerHour ?? 0;
      return price >= _filterMinPrice && price <= _filterMaxPrice;
    }).toList();
    if (_filterStudioType != null && _filterStudioType != 'All Types') {
      result = result.where((e) => e.subCategory.toLowerCase().contains(_filterStudioType!.toLowerCase())).toList();
    }
    if (_filterLocation.isNotEmpty) {
      result = result.where((e) => (e.locationAddress?.toLowerCase().contains(_filterLocation.toLowerCase()) ?? false)).toList();
    }
    if (_filterAmenities.isNotEmpty) {
      result = result.where((e) => _filterAmenities.every((a) => (e.amenities?.map((x) => x.toLowerCase()).contains(a.toLowerCase()) ?? false))).toList();
    }
    if (_filterRatings.isNotEmpty) {
      result = result.where((e) {
        for (final r in _filterRatings) {
          if (r == '3-4 Ratings' && e.avgRating >= 3 && e.avgRating < 4) return true;
          if (r == '4-4.5 Ratings' && e.avgRating >= 4 && e.avgRating < 4.5) return true;
          if (r == '4.5-5 Ratings' && e.avgRating >= 4.5) return true;
        }
        return false;
      }).toList();
    }
    if (_filterDate != null) {
      final dateStr = "\${_filterDate!.year}-\${_filterDate!.month.toString().padLeft(2, '0')}-\${_filterDate!.day.toString().padLeft(2, '0')}";
      result = result.where((e) => e.blockedDates == null || !e.blockedDates!.contains(dateStr)).toList();
    }
    int count = 0;
    if (_filterStudioType != null && _filterStudioType != 'All Types') count++;
    if (_filterLocation.isNotEmpty) count++;
    if (_filterDate != null) count++;
    if (_filterStartTime != null) count++;
    if (_filterMinPrice > 0 || _filterMaxPrice < _maxPrice) count++;
    if (_filterAmenities.isNotEmpty) count++;
    if (_filterRatings.isNotEmpty) count++;
    setState(() { _filteredStudios = result; _activeFilterCount = count; });
  }

  Future<void> _loadUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('location_lat');
    final lng = prefs.getDouble('location_lng');
    if (lat != null && lng != null) {
      if (mounted) setState(() { _userLat = lat; _userLng = lng; });
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
      if (mounted) setState(() { _userLat = pos.latitude; _userLng = pos.longitude; });
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  String _getDistance(ListingModel item) {
    if (_userLat == null || _userLng == null) return "📍 Locating...";
    final lat = item.latitude;
    final lng = item.longitude;
    if (lat == null || lng == null) return "N/A";
    final d = Geolocator.distanceBetween(_userLat!, _userLng!, lat, lng);
    return d < 1000 ? "${d.toStringAsFixed(0)} m" : "${(d / 1000).toStringAsFixed(1)} Km";
  }

  void _sortListings() {
    if (_userLat == null || _userLng == null) return;
    setState(() {
      _isSortingByProximity = !_isSortingByProximity;
      if (_isSortingByProximity) {
        _filteredStudios.sort((a, b) {
          if (a.latitude == null || a.longitude == null) return 1;
          if (b.latitude == null || b.longitude == null) return -1;
          final dA = Geolocator.distanceBetween(_userLat!, _userLng!, a.latitude!, a.longitude!);
          final dB = Geolocator.distanceBetween(_userLat!, _userLng!, b.latitude!, b.longitude!);
          return dA.compareTo(dB);
        });
      } else {
        _applyFilters();
      }
    });
  }

  bool _matchesCategory(ListingModel item, String selectedCategory) {
    final subCat = item.subCategory.toLowerCase();
    final selected = selectedCategory.toLowerCase();
    return subCat.contains(selected);
  }

  Future<void> _loadRecentStudios() async {
    try {
      final response = await ApiService.getStudios();
      List<ListingModel> filtered = response;
      if (widget.initialSubCategory != null && widget.initialSubCategory!.isNotEmpty) {
        filtered = filtered.where((e) => _matchesCategory(e, widget.initialSubCategory!)).toList();
      }
      double maxP = 5000;
      for (final e in filtered) {
        final p = e.pricePerDay ?? e.pricePerHour ?? 0;
        if (p > maxP) maxP = p;
      }
      if (mounted) {
        setState(() {
          _allStudios = filtered;
          _filteredStudios = filtered;
          _maxPrice = maxP + 1000;
          _filterMaxPrice = maxP + 1000;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading studios: $e");
    }
  }

  void _showFilterSheet() {
    final locCtrl = TextEditingController(text: _filterLocation);
    final minPriceCtrl = TextEditingController(text: _filterMinPrice > 0 ? _filterMinPrice.toStringAsFixed(0) : '');
    final maxPriceCtrl = TextEditingController(text: _filterMaxPrice < _maxPrice ? _filterMaxPrice.toStringAsFixed(0) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          void updateFilter(VoidCallback fn) {
            fn();
            setS(() {});
            setState(() {
              _applyFilters();
            });
          }

          final now = _filterDate ?? DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekDays = List.generate(5, (i) => weekStart.add(Duration(days: i)));
          final dayNames = ['MON','TUE','WED','THU','FRI'];

          Widget sectionLabel(String text) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          );

          Widget filterChip(String label, bool selected, VoidCallback onTap) => GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? _purple : const Color(0xFF444444)),
              ),
              child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          );

          Widget checkRow(String label, bool checked, VoidCallback onTap) => GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: checked ? _purple : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: checked ? _purple : const Color(0xFF555555), width: 1.5),
                    ),
                    child: checked ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 10),
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          );

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollCtrl) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  decoration: const BoxDecoration(color: Color(0xFF141414), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: Text('Filters', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                      TextButton(
                        onPressed: () => updateFilter(() {
                          _filterStudioType = null; _filterLocation = ''; _filterDate = null;
                          _filterStartTime = null; _filterMinPrice = 0; _filterMaxPrice = _maxPrice;
                          _filterAmenities.clear(); _filterRatings.clear();
                          locCtrl.clear(); minPriceCtrl.clear(); maxPriceCtrl.clear();
                        }),
                        child: const Text('Reset', style: TextStyle(color: _purple, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    children: [
                      // SELECT CATEGORY
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          sectionLabel('SELECT CATEGORY'),
                          const Text('Choose what you want to book', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                      Wrap(spacing: 8, children: [
                        _catChip('Studios', true, null),
                        _catChip('Equipment', false, () => Navigator.pop(ctx)),
                        _catChip('Manpower', false, () => Navigator.pop(ctx)),
                      ]),
                      const SizedBox(height: 20),

                      // LOCATION
                      sectionLabel('LOCATION'),
                      Container(
                        height: 46,
                        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF444444))),
                        padding: const EdgeInsets.only(left: 12, right: 8), child: Row(children: [Expanded(child: TextField(controller: locCtrl, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: const InputDecoration(hintText: 'Enter location', hintStyle: TextStyle(color: Colors.white38, fontSize: 13), border: InputBorder.none), onChanged: (v) => updateFilter(() => _filterLocation = v),)), GestureDetector(onTap: () async { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching location...'), duration: Duration(seconds: 1))); try { final pos = await Geolocator.getCurrentPosition(); final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude); if (placemarks.isNotEmpty) { final p = placemarks.first; final loc = [p.locality, p.administrativeArea].where((e) => e != null && e.isNotEmpty).join(', '); locCtrl.text = loc; updateFilter(() => _filterLocation = loc); } } catch (e) { debugPrint('Location error: $e'); } }, child: const Icon(Icons.my_location, color: _purple, size: 20),)],),
                      ),
                      const SizedBox(height: 20),

                      // STUDIO TYPE
                      sectionLabel('STUDIO TYPE'),
                      Wrap(children: _studioTypes.map((t) {
                        String currentType = _filterStudioType ?? 'All Types';
                        return filterChip(t, currentType == t, () => updateFilter(() => _filterStudioType = t == 'All Types' ? null : t));
                      }).toList()),
                      const SizedBox(height: 8),

                      // SELECT DATE
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        sectionLabel('SELECT DATE'),
                        GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _filterDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (ctx, child) => Theme(
                                data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _purple, surface: Color(0xFF222222))),
                                child: child!,
                              ),
                            );
                            if (d != null) updateFilter(() => _filterDate = d);
                          },
                          child: Row(
                            children: [
                              Text('${_monthName(now.month)} ${now.year}', style: const TextStyle(color: _purple, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ]),
                      Row(
                        children: List.generate(5, (i) {
                          final d = weekDays[i];
                          final isSel = _filterDate != null && _filterDate!.day == d.day && _filterDate!.month == d.month;
                          return Expanded(child: GestureDetector(
                            onTap: () => updateFilter(() => _filterDate = d),
                            child: Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSel ? _purple : const Color(0xFF333333)),
                              ),
                              child: Column(children: [
                                Text(dayNames[i], style: TextStyle(color: isSel ? Colors.white : Colors.white38, fontSize: 9, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('${d.day}', style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          ));
                        }),
                      ),
                      const SizedBox(height: 10),
                      Row(children: ['Today', 'This Week', 'This Month'].map((lbl) {
                        final isSel = (lbl == 'Today' && _filterDate != null && _isSameDay(_filterDate!, DateTime.now())) ||
                            (lbl == 'This Week' && _filterDate == null);
                        return GestureDetector(
                          onTap: () => updateFilter(() {
                            if (lbl == 'Today') _filterDate = DateTime.now();
                            else if (lbl == 'This Week') _filterDate = null;
                            else _filterDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSel ? _purple : const Color(0xFF444444)),
                            ),
                            child: Text(lbl, style: TextStyle(color: isSel ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 20),

                      // SELECT START TIME
                      sectionLabel('SELECT START TIME'),
                      GridView.count(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8,
                        children: _timeSlots.map((t) {
                          final isSel = _filterStartTime == t;
                          return GestureDetector(
                            onTap: () => updateFilter(() => _filterStartTime = isSel ? null : t),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSel ? _purple : const Color(0xFF444444)),
                              ),
                              child: Center(child: Text(t, style: TextStyle(color: isSel ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w600))),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      const Text('Note: Greyed out slots are unavailable for this item.', style: TextStyle(color: Colors.white24, fontSize: 10)),
                      const SizedBox(height: 20),

                      // PRICE RANGE
                      sectionLabel('PRICE RANGE'),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('₹${_filterMinPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        Text('₹${_filterMaxPrice.toStringAsFixed(0)}${_filterMaxPrice == _maxPrice ? '+' : ''}', style: const TextStyle(color: _purple, fontSize: 11)),
                      ]),
                      RangeSlider(
                        values: RangeValues(_filterMinPrice, _filterMaxPrice), min: 0, max: _maxPrice,
                        activeColor: _purple, inactiveColor: Colors.white12,
                        onChanged: (v) => updateFilter(() { _filterMinPrice = v.start; _filterMaxPrice = v.end; }),
                      ),
                      Row(children: [
                        Expanded(child: _priceInput('Min', minPriceCtrl, (v) => updateFilter(() => _filterMinPrice = double.tryParse(v) ?? 0))),
                        const SizedBox(width: 12),
                        Expanded(child: _priceInput('Max', maxPriceCtrl, (v) => updateFilter(() => _filterMaxPrice = double.tryParse(v) ?? _maxPrice))),
                      ]),
                      const SizedBox(height: 20),

                      // AMENITIES
                      sectionLabel('AMENITIES'),
                      Wrap(children: _amenityOptions.map((a) =>
                        filterChip(a, _filterAmenities.contains(a),
                          () => updateFilter(() {
                            if (_filterAmenities.contains(a)) { _filterAmenities.remove(a); }
                            else { _filterAmenities.add(a); }
                          })
                        )
                      ).toList()),
                      const SizedBox(height: 8),

                      // RATINGS
                      sectionLabel('RATINGS'),
                      ..._ratingOptions.map((r) => checkRow(r, _filterRatings.contains(r),
                        () => updateFilter(() => _filterRatings.contains(r) ? _filterRatings.remove(r) : _filterRatings.add(r))
                      )),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: const BoxDecoration(color: Color(0xFF141414), border: Border(top: BorderSide(color: Colors.white12))),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => updateFilter(() {
                          _filterStudioType = null; _filterLocation = ''; _filterDate = null;
                          _filterStartTime = null; _filterMinPrice = 0; _filterMaxPrice = _maxPrice;
                          _filterAmenities.clear(); _filterRatings.clear();
                          locCtrl.clear(); minPriceCtrl.clear(); maxPriceCtrl.clear();
                        }),
                        style: OutlinedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _purple, side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _catChip(String label, bool selected, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _purple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _purple : const Color(0xFF444444)),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _priceInput(String hint, TextEditingController ctrl, ValueChanged<String> onChanged) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF444444))),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: ctrl, keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 13), border: InputBorder.none),
        onChanged: onChanged,
      ),
    );
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  children: [
                    if (widget.initialSubCategory == null || widget.initialSubCategory!.isEmpty)
                      _buildCategoryGrid()
                    else
                      _buildVerticalListSection(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: CustomFloatingNavbar(
            selectedIndex: AppNavigation.selectedTabIndex.value,
            onTabSelected: (index) {},
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool isListView = widget.initialSubCategory != null && widget.initialSubCategory!.isNotEmpty;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF527B), Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: 52, right: 16, child: Opacity(opacity: 0.18, child: const Icon(Icons.videocam_outlined, color: Colors.white, size: 56))),
          Positioned(top: 52, left: 56, child: Opacity(opacity: 0.15, child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 44))),
          Positioned(bottom: 16, left: 16, child: Opacity(opacity: 0.14, child: const Icon(Icons.movie_outlined, color: Colors.white, size: 44))),
          Positioned(
            bottom: 8, right: 12,
            child: Opacity(opacity: 0.14, child: SizedBox(width: 70, height: 70,
              child: CustomPaint(painter: StudioBackdropPainter(color: Colors.white, strokeWidth: 1.5)),
            )),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 56, left: 16, right: 16,
              bottom: isListView ? 20 : 36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: isListView
                                ? 'Search ${widget.initialSubCategory}...'
                                : 'Search for studio',
                            hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
                if (!isListView) ...[
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Pro studio,\nAnytime You\nNeed It!!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.25, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
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
        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.35,
      ),
      itemCount: _subCategories.length,
      itemBuilder: (context, index) {
        final cat = _subCategories[index];
        final List<Color> colors = cat['colors'] as List<Color>;
        final String watermarkType = cat['watermark'] as String;
        return FadeInUp(
          delay: Duration(milliseconds: index * 60),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudioListScreen(initialSubCategory: cat['title']),
              ));
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: -6, right: -6,
                    child: Opacity(
                      opacity: 0.18,
                      child: SizedBox(width: 88, height: 88,
                        child: CustomPaint(
                          painter: watermarkType == 'sound'
                              ? SoundSystemPainter(color: Colors.white, strokeWidth: 1.2)
                              : watermarkType == 'drone'
                                  ? DronePainter(color: Colors.white, strokeWidth: 1.2)
                                  : watermarkType == 'camera'
                                      ? CameraBodyPainter(color: Colors.white, strokeWidth: 1.2)
                                      : StudioBackdropPainter(color: Colors.white, strokeWidth: 1.2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      cat['title'] as String,
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.1,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
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
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: _accent),
      ));
    }
    if (_filteredStudios.isEmpty) {
      return Container(
        height: 200, alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? "No results for '$_searchQuery'"
                  : "No studio found for '${widget.initialSubCategory}'",
              style: const TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Column(
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
                    "${widget.initialSubCategory} studio",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${_filteredStudios.length} available",
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _sortListings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isSortingByProximity ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isSortingByProximity ? Colors.transparent : Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(Icons.near_me, color: _isSortingByProximity ? Colors.white : Colors.white60, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _isSortingByProximity ? "Nearest" : "Sort",
                      style: TextStyle(
                        color: _isSortingByProximity ? Colors.white : Colors.white60,
                        fontSize: 12, fontWeight: FontWeight.bold,
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
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredStudios.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (ctx, index) => FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: _buildstudioCard(_filteredStudios[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildstudioCard(ListingModel studio) {
    final amenities = studio.amenities;
    final double price = studio.pricePerDay ?? studio.pricePerHour ?? 0;
    final bool isPerHour = studio.pricePerDay == null && studio.pricePerHour != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => StudioDetailScreen(studio: studio)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 1.75,
                    child: (studio.images.isNotEmpty)
                        ? Image.network(
                            studio.images[0], fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) => progress == null
                                ? child
                                : Container(color: Colors.grey[900],
                                    child: const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))),
                            errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image),
                          )
                        : _placeholder(Icons.image),
                  ),
                ),
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF00B341), borderRadius: BorderRadius.circular(6)),
                    child: const Text("Available", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                    child: WishlistButtonWidget(listing: studio, size: 20),
                  ),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(_getDistance(studio),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        const Text("Away location", style: TextStyle(color: Colors.white60, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(studio.listingTitle,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 3),
                          Text(studio.avgRating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(studio.brand ?? studio.subCategory,
                          style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(children: [
                          const TextSpan(text: '₹', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                          TextSpan(text: '${price.toStringAsFixed(0)}/${isPerHour ? 'hr' : 'day'}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white38, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(studio.locationAddress ?? 'Location N/A',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (amenities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: amenities.length > 6 ? 6 : amenities.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (ctx, i) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _accent.withOpacity(0.35), width: 1),
                          ),
                          child: Text(amenities[i].toString(),
                            style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(IconData icon) => Container(
    color: Colors.grey[900],
    child: Center(child: Icon(icon, color: Colors.white24, size: 40)),
  );
}



