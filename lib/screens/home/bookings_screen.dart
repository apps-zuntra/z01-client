import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/api_service.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import 'booking_detail_screen.dart';
import 'cancel_booking_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _fetchBookings(isPolling: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBookings({bool isPolling = false}) async {
    try {
      final data = await ApiService.getUserBookings();
      if (mounted) {
        setState(() {
          _bookings = data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isPolling) {
        setState(() {
          _bookings = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
        title: const Text(
          'Booking History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFBA68C8)))
        : _buildBookingList(),
    );
  }

  Widget _buildBookingList() {
    if (_bookings.isEmpty) {
      return _buildEmptyState();
    }

    // Sort by most recent start_date
    _bookings.sort((a, b) {
      final dateA = DateTime.tryParse(a['start_date']?.toString() ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['start_date']?.toString() ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA); // Descending
    });

    return RefreshIndicator(
      onRefresh: () => _fetchBookings(),
      color: const Color(0xFFBA68C8),
      backgroundColor: const Color(0xFF2C2C2E),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: _buildBookingCard(booking),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, size: 48, color: Colors.white24),
          ),
          const SizedBox(height: 20),
          const Text(
            'You have no booking history',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA68C8).withOpacity(0.1),
              foregroundColor: const Color(0xFFBA68C8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Discover Services'),
          )
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    DateTime pickup = DateTime.now();
    DateTime returnDate = DateTime.now().add(const Duration(days: 1));
    if (booking['start_date'] != null) {
      pickup = DateTime.tryParse(booking['start_date'].toString()) ?? pickup;
    }
    if (booking['end_date'] != null) {
      returnDate = DateTime.tryParse(booking['end_date'].toString()) ?? returnDate;
    }
    int days = returnDate.difference(pickup).inDays;
    if (days <= 0) days = 1;
    
    final totalPrice = double.tryParse(booking['total_amount']?.toString() ?? '0') ?? 0.0;
    // Attempt to calculate a per-day price if not provided, otherwise just use total
    final pricePerDay = (totalPrice / days).toStringAsFixed(0); 

    final rawImage = booking['image_1'] ?? booking['listing_image'];
    final imageUrl = ApiService.getSafeImageUrl(rawImage);
    final status = (booking['status'] ?? '').toString().toLowerCase();

    Color statusColor = Colors.green;
    String statusLabel = 'Upcoming';
    
    if (status == 'pending' || status == 'confirmed' || status == 'upcoming') {
      statusColor = Colors.green;
      statusLabel = 'Upcoming';
    } else if (status == 'canceled' || status == 'cancelled' || status == 'cancel') {
      statusColor = const Color(0xFFF44336); // Red
      statusLabel = 'Canceled';
    } else if (status == 'completed' || status == 'returned') {
      statusColor = Colors.grey.shade600;
      statusLabel = 'Completed';
    }

    final isUpcoming = statusLabel == 'Upcoming';
    final isCompleted = statusLabel == 'Completed';
    final isCanceled = statusLabel == 'Canceled';

    final String title = booking['listing_name'] ?? 'Booking Item';
    final String location = booking['location_address'] ?? 'Chennai';
    final String dateString = '${DateFormat('MMM d').format(pickup)}-${DateFormat('MMM d').format(returnDate)}($days Days)';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Section: Image and Details
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with Status Badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl.isNotEmpty 
                            ? Image.network(
                                imageUrl,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 90, height: 90, color: Colors.white10,
                                  child: const Icon(Icons.image_not_supported, color: Colors.white24),
                                ),
                              ) 
                            : Container(
                                width: 90, height: 90, color: Colors.white10,
                                child: const Icon(Icons.image, color: Colors.white24),
                              ),
                        ),
                        // Status Badge overlapping image
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24), // Push down to align with price pill
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month_outlined, color: Colors.white70, size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  dateString,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Price Pill
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA68C8),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    '₹$pricePerDay/day',
                    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
          
          // Action Banner (Remaining payment) for upcoming
          if (isUpcoming)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: const Color(0xFFBA68C8).withOpacity(0.15),
              alignment: Alignment.center,
              child: const Text(
                'Remaining payment need to be paid',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
            
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (isUpcoming) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CancelBookingScreen(booking: booking)));
                        if (result == true) _fetchBookings();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBA68C8),
                        side: const BorderSide(color: Color(0xFFBA68C8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (isCompleted) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showReviewBottomSheet(context, booking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Leave Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)));
                      if (result == true) _fetchBookings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA68C8),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewBottomSheet(BuildContext context, Map<String, dynamic> booking) {
    int localRating = 5;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
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
                controller: reviewController,
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (reviewController.text.isNotEmpty) {
                      setModalState(() => isSubmitting = true);
                      try {
                        final listingId = booking['listing_id']?.toString() ?? booking['id']?.toString() ?? '1';
                        final reviewData = {
                          'listing_id': int.tryParse(listingId) ?? 1,
                          'rating': localRating,
                          'comment': reviewController.text,
                          'user_name': 'Customer',
                          'images': [],
                          'created_at': DateTime.now().toIso8601String(),
                        };
                        
                        final success = await ApiService.postReview(reviewData);
                        if (!success) throw Exception("Failed to post review");
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Review published successfully!"), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                        );
                      } finally {
                        setModalState(() => isSubmitting = false);
                      }
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please write a review comment"), backgroundColor: Colors.orange),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA68C8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text("Publish Review", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
