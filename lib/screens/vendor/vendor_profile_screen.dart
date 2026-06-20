import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../studio/studio_detail_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/listing_model.dart';

class VendorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> vendor;
  const VendorProfileScreen({super.key, required this.vendor});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  List<ListingModel> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorListings();
  }

  Future<void> _loadVendorListings() async {
    try {
      final response = await ApiService.getVendorListings(widget.vendor['id'].toString());
      final List<ListingModel> models = (response as List).map((l) => ListingModel.fromJson(l)).toList();
      if (mounted) {
        setState(() {
          _listings = models;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error loading vendor listings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.vendor['name'] ?? 'Vendor Shop', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFCA9AFF)))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVendorHeader(),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("All Listings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: _listings.isEmpty 
                  ? const Center(child: Text("No listings found for this vendor", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _listings.length,
                      itemBuilder: (context, index) => _buildListingCard(_listings[index]),
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildVendorHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFCA9AFF).withOpacity(0.2),
            child: Text(
              (widget.vendor['name'] ?? 'V')[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFFCA9AFF), fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vendor['name'] ?? 'Unknown Vendor',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.vendor['business_type'] ?? 'Professional Service',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    return FadeInUp(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudioDetailScreen(studio: listing)),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  (listing.images != null && listing.images.isNotEmpty) ? listing.images[0] : '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white10, width: 80, height: 80, child: const Icon(Icons.image, color: Colors.white24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.listingTitle,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.category,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹${listing.pricePerDay ?? listing.pricePerHour}/unit",
                      style: const TextStyle(color: Color(0xFFCA9AFF), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Builder(
                      builder: (ctx) {
                        List<String> tags = [];
                        if (listing.category == 'Equipment') {
                          tags = listing.equipments.isNotEmpty ? listing.equipments : (listing.amenities ?? []);
                        } else if (listing.category == 'Manpower') {
                          tags = listing.manpower.isNotEmpty ? listing.manpower : (listing.amenities ?? []);
                        } else {
                          tags = listing.amenities ?? [];
                        }
                        if (tags.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 24,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: tags.length > 3 ? 3 : tags.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 6),
                                itemBuilder: (context, i) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCA9AFF).withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCA9AFF).withOpacity(0.35), width: 1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      tags[i].toString(),
                                      style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
  }
}
