import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../core/navigation.dart';
import 'booking_detail_screen.dart';
import 'cancel_booking_screen.dart';
import '../bookings/customer_confirm_delivery_screen.dart';

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
    
    // Listen for tab switches to instantly refresh bookings when navigating here
    AppNavigation.selectedTabIndex.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (AppNavigation.selectedTabIndex.value == 2) {
      _fetchBookings();
    }
  }

  @override
  void dispose() {
    AppNavigation.selectedTabIndex.removeListener(_onTabChanged);
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
      backgroundColor: const Color(0xFF121212),
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
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFCA9AFF)))
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
      color: const Color(0xFFCA9AFF),
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
              backgroundColor: const Color(0xFFCA9AFF).withOpacity(0.1),
              foregroundColor: const Color(0xFFCA9AFF),
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
    final pricePerDay = (totalPrice / days).toStringAsFixed(0); 

    final rawImage = booking['image_1'] ?? booking['listing_image'];
    final imageUrl = ApiService.getSafeImageUrl(rawImage);
    final status = (booking['status'] ?? '').toString().toLowerCase();
    final paymentStatus = (booking['payment_status'] ?? '').toString().toLowerCase();

    Color statusColor = const Color(0xFF22C55E); // Green
    String statusLabel = 'Upcoming';
    
    if (status == 'canceled' || status == 'cancelled' || status == 'cancel') {
      statusColor = const Color(0xFFEF4444); // Red
      statusLabel = 'Canceled';
    } else if (status == 'completed' || status == 'returned') {
      statusColor = const Color(0xFF9CA3AF); // Gray
      statusLabel = 'Completed';
    } else if (status == 'accepted' || status == 'confirmed' || status == 'approved' || status == 'delivered') {
      statusColor = const Color(0xFFCA9AFF);
      statusLabel = 'Ongoing';
    } else if (paymentStatus == 'paid' || paymentStatus == 'true' || paymentStatus == 'success' || status == 'paid') {
      statusColor = const Color(0xFF22C55E);
      statusLabel = 'Upcoming';
    } else if (status == 'pending') {
      statusColor = Colors.orange;
      statusLabel = 'Pending Payment';
    }

    final isUpcoming = statusLabel == 'Upcoming' || statusLabel == 'Pending Payment';
    final isOngoing = statusLabel == 'Ongoing';
    final isCompleted = statusLabel == 'Completed';
    final isCanceled = statusLabel == 'Canceled';

    final String title = booking['listing_name'] ?? 'Booking Item';
    final String location = booking['location_address'] ?? 'Chennai';
    final String dateString = '${DateFormat('MMM d').format(pickup)}-${DateFormat('MMM d').format(returnDate)}($days Days)';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with top badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl.isNotEmpty 
                              ? Image.network(
                                  imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 100, height: 100, color: Colors.white10,
                                    child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 28),
                                  ),
                                ) 
                              : Container(
                                  width: 100, height: 100, color: Colors.white10,
                                  child: const Icon(Icons.image, color: Colors.white24, size: 28),
                                ),
                          ),
                          // Status Badge overlaid at the top of the image
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [statusColor, statusColor.withOpacity(0.6), Colors.transparent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Details section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 28), // push down below price pill
                            Text(
                              title,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Calendar Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B2D59),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateString,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
                // Price Pill (Top Right Corner)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4B4FF),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      '₹$pricePerDay/day',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Action Banner (Remaining payment) for upcoming
            if (isUpcoming)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFF6B21A8), // Vibrant Purple
                alignment: Alignment.center,
                child: const Text(
                  'Remaining payment need to be paid',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                          foregroundColor: const Color(0xFFD4B4FF),
                          side: const BorderSide(color: Color(0xFFD4B4FF), width: 1.5),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (isCompleted) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showReviewBottomSheet(context, booking),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54, width: 1.5),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text('Leave Review', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (status == 'delivered') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerConfirmDeliveryScreen(booking: booking)));
                          if (result == true) _fetchBookings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCA9AFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
                        backgroundColor: const Color(0xFFD4B4FF),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('user_id');
                        final userName = prefs.getString('user_name') ?? 'Customer';

                        final reviewData = {
                          'listing_id': int.tryParse(listingId) ?? 1,
                          'rating': localRating,
                          'comment': reviewController.text,
                          'user_id': userId,
                          'user_name': userName,
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
                    backgroundColor: const Color(0xFFCA9AFF),
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
