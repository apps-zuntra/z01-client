import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants.dart';
import 'package:animate_do/animate_do.dart';
import '../studio/studio_list_screen.dart';
import '../manpower/manpower_list_screen.dart';
import '../equipment/equipment_list_screen.dart';
import '../studio/studio_detail_screen.dart';
import 'dart:async';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/listing_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _selectedIndex = 1; // Search is selected
  late TextEditingController _searchController;
  String _searchQuery = '';
  Timer? _debounce;
  double? _userLat;
  double? _userLng;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'color': const Color(0xFFE53935)},
    {'label': 'Studios', 'color': const Color(0xFF1E88E5)},
    {'label': 'Manpower', 'color': const Color(0xFFFF8F00)},
    {'label': 'Equipment', 'color': const Color(0xFFD81B60)},
  ];

  List<String> _recentSearches = [];
  List<ListingModel> _allRecentListings = [];
  List<ListingModel> _recentListings = [];
  List<ListingModel> _allSearchResults = [];
  List<ListingModel> _searchResults = [];
  bool _isLoadingRecent = true;
  bool _isSearching = false;

  // Filter States
  String? _filterCategory;
  String _filterLocation = '';
  DateTime? _filterDate;
  String? _filterStartTime;
  double _filterMinPrice = 0;
  double _filterMaxPrice = 10000;
  final double _maxPrice = 10000;
  int _activeFilterCount = 0;
  
  final List<String> _timeSlots = [
    '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
    '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadRecentSearches();
    _loadUserLocation();
    _loadAllRecentListings();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSearches = prefs.getStringList('recent_searches') ?? [];
    if (mounted) {
      setState(() {
        _recentSearches = savedSearches;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
      print("Error getting location in search: $e");
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
          if (_searchQuery.isEmpty) {
            _allSearchResults = [];
            _searchResults = [];
            _isSearching = false;
          } else {
            _isSearching = true;
            _performSearch(_searchQuery);
          }
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final response = await ApiService.searchListings(query);
      
      if (mounted) {
        setState(() {
          _allSearchResults = response;
          _isSearching = false;
          _applyFilters();
        });
      }
    } catch (e) {
      print("Error performing search: $e");
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) _recentSearches.removeLast();
      
    if (mounted) {
      setState(() {});
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', _recentSearches);
    } catch (e) {
      print("Error saving recent searches: $e");
    }
  }

  String _getDistance(ListingModel item) {
    if (_userLat == null || _userLng == null) return "📍 Locating...";
    final lat = item.latitude;
    final lng = item.longitude;
    if (lat == null || lng == null) return "N/A";
    final m = Geolocator.distanceBetween(_userLat!, _userLng!, lat, lng);
    return m < 1000 ? "${m.toStringAsFixed(0)}m" : "${(m/1000).toStringAsFixed(1)}km";
  }

  Future<void> _loadAllRecentListings() async {
    try {
      final response = await ApiService.getAllRecentListings();
      
      if (mounted) {
        setState(() {
          _allRecentListings = response;
          _isLoadingRecent = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRecent = false);
      print("Error loading search page items: $e");
    }
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _monthName(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];

  void _applyFilters() {
    List<ListingModel> searchResult = List.from(_allSearchResults);
    List<ListingModel> recentResult = List.from(_allRecentListings);

    bool Function(ListingModel) filterFn = (item) {
      if (_filterCategory != null && _filterCategory != 'All') {
        if (!item.category.toLowerCase().contains(_filterCategory!.toLowerCase())) return false;
      }
      if (_filterLocation.isNotEmpty) {
        if (!(item.locationAddress?.toLowerCase().contains(_filterLocation.toLowerCase()) ?? false)) return false;
      }
      final price = item.pricePerHour ?? item.pricePerDay ?? 0;
      if (price < _filterMinPrice || price > _filterMaxPrice) return false;
      if (_filterDate != null) {
        final dateStr = "\${_filterDate!.year}-\${_filterDate!.month.toString().padLeft(2, '0')}-\${_filterDate!.day.toString().padLeft(2, '0')}";
        if (item.blockedDates != null && item.blockedDates!.contains(dateStr)) return false;
      }
      return true;
    };

    searchResult = searchResult.where(filterFn).toList();
    recentResult = recentResult.where(filterFn).toList();

    int count = 0;
    if (_filterCategory != null && _filterCategory != 'All') count++;
    if (_filterLocation.isNotEmpty) count++;
    if (_filterDate != null) count++;
    if (_filterStartTime != null) count++;
    if (_filterMinPrice > 0 || _filterMaxPrice < _maxPrice) count++;

    setState(() {
      _searchResults = searchResult;
      _recentListings = recentResult;
      _activeFilterCount = count;
    });
  }

  void _showFilterSheet() {
    final locCtrl = TextEditingController(text: _filterLocation);

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
                border: Border.all(color: selected ? const Color(0xFFCA9AFF) : const Color(0xFF444444)),
              ),
              child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
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
                          _filterCategory = null; _filterLocation = ''; _filterDate = null;
                          _filterStartTime = null; _filterMinPrice = 0; _filterMaxPrice = _maxPrice;
                          locCtrl.clear();
                        }),
                        child: const Text('Reset', style: TextStyle(color: Color(0xFFCA9AFF), fontWeight: FontWeight.bold)),
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
                          const Text('Choose what you want to search', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                      Wrap(spacing: 8, children: [
                        filterChip('All', (_filterCategory ?? 'All') == 'All', () => updateFilter(() => _filterCategory = 'All')),
                        filterChip('Studios', _filterCategory == 'Studios', () => updateFilter(() => _filterCategory = 'Studios')),
                        filterChip('Equipment', _filterCategory == 'Equipment', () => updateFilter(() => _filterCategory = 'Equipment')),
                        filterChip('Manpower', _filterCategory == 'Manpower', () => updateFilter(() => _filterCategory = 'Manpower')),
                      ]),
                      const SizedBox(height: 20),

                      // LOCATION
                      sectionLabel('LOCATION'),
                      Container(
                        height: 46,
                        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF444444))),
                        padding: const EdgeInsets.only(left: 12, right: 8), 
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: locCtrl, 
                                style: const TextStyle(color: Colors.white, fontSize: 13), 
                                decoration: const InputDecoration(hintText: 'Enter location', hintStyle: TextStyle(color: Colors.white38, fontSize: 13), border: InputBorder.none), 
                                onChanged: (v) => updateFilter(() => _filterLocation = v),
                              )
                            ), 
                            GestureDetector(
                              onTap: () async { 
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching location...'), duration: Duration(seconds: 1))); 
                                try { 
                                  final pos = await Geolocator.getCurrentPosition(); 
                                  final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude); 
                                  if (placemarks.isNotEmpty) { 
                                    final p = placemarks.first; 
                                    final loc = [p.locality, p.administrativeArea].where((e) => e != null && e.isNotEmpty).join(', '); 
                                    locCtrl.text = loc; 
                                    updateFilter(() => _filterLocation = loc); 
                                  } 
                                } catch (e) { 
                                  debugPrint('Location error: $e'); 
                                } 
                              }, 
                              child: const Icon(Icons.my_location, color: Color(0xFFCA9AFF), size: 20),
                            )
                          ]
                        ),
                      ),
                      const SizedBox(height: 20),

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
                                data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFCA9AFF), surface: Color(0xFF222222))),
                                child: child!,
                              ),
                            );
                            if (d != null) updateFilter(() => _filterDate = d);
                          },
                          child: Row(
                            children: [
                              Text('${_monthName(now.month)} ${now.year}', style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 12, fontWeight: FontWeight.w600)),
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
                                border: Border.all(color: isSel ? const Color(0xFFCA9AFF) : const Color(0xFF333333)),
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
                              border: Border.all(color: isSel ? const Color(0xFFCA9AFF) : const Color(0xFF444444)),
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
                                border: Border.all(color: isSel ? const Color(0xFFCA9AFF) : const Color(0xFF444444)),
                              ),
                              child: Center(child: Text(t, style: TextStyle(color: isSel ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w600))),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // PRICE RANGE
                      sectionLabel('PRICE RANGE'),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('₹${_filterMinPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        Text('₹${_filterMaxPrice.toStringAsFixed(0)}${_filterMaxPrice == _maxPrice ? '+' : ''}', style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 11)),
                      ]),
                      RangeSlider(
                        values: RangeValues(_filterMinPrice, _filterMaxPrice), min: 0, max: _maxPrice,
                        activeColor: const Color(0xFFCA9AFF), inactiveColor: Colors.white12,
                        onChanged: (v) => updateFilter(() { _filterMinPrice = v.start; _filterMaxPrice = v.end; }),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: const BoxDecoration(color: Color(0xFF141414), border: Border(top: BorderSide(color: Colors.white12))),
                  child: SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCA9AFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                      child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToCategory(String label) {
    switch (label) {
      case 'Studios':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudioListScreen()),
        );
        break;
      case 'Manpower':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManpowerListScreen()),
        );
        break;
      case 'Equipment':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EquipmentListScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            Expanded(
              child: _searchQuery.isEmpty 
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildCategoryChips(),
                        if (_recentSearches.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _buildSectionTitle('Your Recent Search'),
                          const SizedBox(height: 16),
                          _buildRecentSearches(),
                        ],
                        const SizedBox(height: 28),
                        _buildSectionTitle('Whats on your mind?'),
                        const SizedBox(height: 16),
                        _buildMindGrid(),
                        const SizedBox(height: 120), // Space for navbar
                      ],
                    ),
                  )
                : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFCA9AFF)));
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text('No results for "$_searchQuery"', style: const TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 40),
          child: GestureDetector(
            onTap: () {
              _addRecentSearch(_searchQuery);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudioDetailScreen(studio: item)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: (item.images != null && item.images.isNotEmpty)
                        ? Image.network(item.images[0], fit: BoxFit.cover)
                        : Container(color: Colors.white10),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.listingTitle, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(item.category, 
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFCA9AFF), size: 14),
                            const SizedBox(width: 4),
                            Text(_getDistance(item), 
                                style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _addRecentSearch(value.trim());
                    _performSearch(value.trim());
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search for Camera',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox();
                      return IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      );
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((cat) {
        return GestureDetector(
          onTap: () => _navigateToCategory(cat['label'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: cat['color'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              cat['label'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _recentSearches
          .map(
            (search) => GestureDetector(
              onTap: () {
                _searchController.text = search;
                // Listener will trigger search
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, color: Colors.white54, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      search,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMindGrid() {
    if (_isLoadingRecent) {
      return const Center(child: CircularProgressIndicator(color: Colors.white24));
    }

    if (_recentListings.isEmpty) {
      return const Center(
        child: Text("No items listed yet", style: TextStyle(color: Colors.white38)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: _recentListings.length > 9 ? 9 : _recentListings.length,
      itemBuilder: (context, index) {
        final item = _recentListings[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 60),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudioDetailScreen(studio: item),
                ),
              );
            },
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: (item.images != null && item.images.isNotEmpty)
                      ? Image.network(
                          item.images[0],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF333333),
                            child: const Icon(Icons.image, color: Colors.white24),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF333333),
                          child: const Icon(Icons.image, color: Colors.white24),
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.listingTitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
