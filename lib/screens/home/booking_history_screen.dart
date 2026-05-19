import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/api_service.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import 'booking_detail_screen.dart';
import 'cancel_booking_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
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
      backgroundColor: AppColors.background,
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
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _fetchBookings(),
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _buildBookingList(),
    );
  }

  Widget _buildBookingList() {
    if (_bookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _fetchBookings(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Discover Services'),
          )
        ],
      ),
    );
  }

  String _getSafeImageUrl(String? url) {
    return ApiService.getSafeImageUrl(url);
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
    if (days == 0) days = 1;
    
    final totalPrice = double.tryParse(booking['total_amount']?.toString() ?? '0') ?? 0.0;
    final rawImage = booking['image_1'] ?? booking['listing_image'];
    final imageUrl = _getSafeImageUrl(rawImage);
    final status = (booking['status'] ?? '').toString().toLowerCase();

    Color statusColor = Colors.green;
    String statusLabel = 'Confirmed';
    
    if (status == 'pending') {
      statusColor = Colors.orange;
      statusLabel = 'Pending';
    } else if (status == 'canceled' || status == 'cancelled' || status == 'cancel') {
      statusColor = Colors.red;
      statusLabel = 'Canceled';
    } else if (status == 'completed' || status == 'returned') {
      statusColor = Colors.blue;
      statusLabel = 'Completed';
    }

    // Fix for RangeError and proper truncating
    String displayId = (booking['id'] ?? '').toString();
    if (displayId.length > 8) {
      displayId = displayId.substring(0, 8).toUpperCase();
    } else {
      displayId = displayId.toUpperCase();
    }

    final isUpcoming = status == 'confirmed' || status == 'upcoming' || status == 'pending';
    final isCompleted = status == 'completed' || status == 'returned';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white.withOpacity(0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ID: #$displayId',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'history_booking_${booking['id']}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl.isNotEmpty 
                          ? Image.network(
                              imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 100, height: 100, color: Colors.white.withOpacity(0.05),
                                child: const Icon(Icons.image_not_supported_outlined, color: Colors.white10),
                              ),
                            ) 
                          : Container(
                              width: 100, height: 100, color: Colors.white.withOpacity(0.05),
                              child: const Icon(Icons.image_not_supported_outlined, color: Colors.white10),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking['listing_name'] ?? 'Product Name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (booking['listing_type'] != null && booking['listing_type'].toString().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
                                ),
                                child: Text(
                                  booking['listing_type'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: AppColors.primary.withOpacity(0.7), size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking['location_address'] ?? 'Location not specified',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: Colors.white38, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${DateFormat('MMM d').format(pickup)} - ${DateFormat('MMM d').format(returnDate)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  if (status == 'confirmed')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_rounded, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Payment required on your pickup date.',
                              style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL AMOUNT', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUpcoming)
                            TextButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CancelBookingScreen(booking: booking)),
                                );
                                if (result == true) {
                                  _fetchBookings();
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          if (isCompleted)
                            TextButton(
                              onPressed: () => _showReviewBottomSheet(context, booking),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)),
                              );
                              if (result == true) {
                                _fetchBookings();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              minimumSize: const Size(0, 0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ),
                        ],
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
                    backgroundColor: AppColors.primary,
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
