import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  final List<String> _recentSearches = [];
  List<ListingModel> _recentListings = [];
  List<ListingModel> _searchResults = [];
  bool _isLoadingRecent = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadUserLocation();
    _loadAllRecentListings();
    _searchController.addListener(_onSearchChanged);
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
          _searchResults = response;
          _isSearching = false;
        });
      }
    } catch (e) {
      print("Error performing search: $e");
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) _recentSearches.removeLast();
    });
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
          _recentListings = response;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRecent = false);
      print("Error loading search page items: $e");
    }
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFFBA68C8)));
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
                      child: item.images.isNotEmpty
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
                            const Icon(Icons.location_on, color: Color(0xFFBA68C8), size: 14),
                            const SizedBox(width: 4),
                            Text(_getDistance(item), 
                                style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 12, fontWeight: FontWeight.bold)),
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
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 20),
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
      itemCount: _recentListings.length,
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
                    child: item.images.isNotEmpty
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
