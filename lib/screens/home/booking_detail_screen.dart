import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'cancel_booking_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Map<String, dynamic>? _bookingDetail;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Poll every 5 seconds for real-time updates
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchData(isPolling: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getSafeImageUrl(String? url) {
    return ApiService.getSafeImageUrl(url);
  }


  Future<void> _fetchData({bool isPolling = false}) async {
    try {
      final data = await ApiService.getBooking(widget.booking['id'].toString());
      if (mounted) {
        setState(() {
          _bookingDetail = data ?? widget.booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isPolling) {
        setState(() {
          _bookingDetail = widget.booking;
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProgressBar(String status) {
    status = status.toLowerCase();
    if (status == 'canceled' || status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Booking Cancelled', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('This booking has been successfully cancelled.', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Order ID: #Z01-${_bookingDetail?['id'] ?? '0000'}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      );
    }

    int currentIndex = 0;
    if (status == 'packed') currentIndex = 1;
    if (status == 'ready') currentIndex = 2;
    if (status == 'returned' || status == 'completed') currentIndex = 3;

    final steps = ['Confirmed', 'Packed', 'Ready', 'Returned'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        children: [
          const Text('Order ID', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text('#Z01-${_bookingDetail?['id'] ?? '0000'}', style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final isActive = index <= currentIndex;
              return Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: isActive ? const Color(0xFFBA68C8) : Colors.white24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _bookingDetail ?? widget.booking;
    final status = booking['status'] ?? 'upcoming';
    
    // Parse dates carefully handling nulls
    DateTime pickup = DateTime.now();
    DateTime returnDate = DateTime.now().add(const Duration(days: 1));
    if (booking['start_date'] != null) {
      pickup = DateTime.tryParse(booking['start_date'].toString()) ?? pickup;
    }
    if (booking['end_date'] != null) {
      returnDate = DateTime.tryParse(booking['end_date'].toString()) ?? returnDate;
    }
    
    final totalPrice = double.tryParse(booking['total_amount']?.toString() ?? '0') ?? 0.0;
    
    // Assuming we have items array or we use listing name
    final List<dynamic> items = booking['items'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFBA68C8)))
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            FadeInUp(
              child: _buildProgressBar(status),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rented items', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${items.isEmpty ? 1 : items.length} Items', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            // Items List
            if (items.isEmpty)
              _buildProductCard(
                booking['listing_name'] ?? 'Product', 
                booking['location_address'] ?? 'Perungudi, Chennai',
                pickup, returnDate,
                booking['image_1'],
                totalPrice,
                booking['listing_type']
              )
            else
              ...items.map((item) => _buildProductCard(
                item['name'] ?? '', 
                booking['location_address'] ?? 'Chennai',
                pickup, returnDate,
                item['image'],
                totalPrice,
                item['listing_type'] ?? booking['listing_type']
              )),
            
            const SizedBox(height: 24),
            // Important Information Banner
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFFBA68C8).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Important Information', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint('Bookings cannot be extended once confirmed'),
                    _buildBulletPoint('Equipment must be returned in original condition'),
                    _buildBulletPoint('Refund timeline varies by vendor'),
                    _buildBulletPoint('Late returns will be charged at hourly rate'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Timeline & Location', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Timeline Detail Card
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              double.tryParse(booking['latitude']?.toString() ?? '') ?? 12.9716, 
                              double.tryParse(booking['longitude']?.toString() ?? '') ?? 77.5946
                            ),
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('vendor_location'),
                              position: LatLng(
                                double.tryParse(booking['latitude']?.toString() ?? '') ?? 12.9716, 
                                double.tryParse(booking['longitude']?.toString() ?? '') ?? 77.5946
                              ),
                            )
                          },
                          zoomControlsEnabled: true,
                          myLocationButtonEnabled: true,
                          scrollGesturesEnabled: true,
                          mapType: MapType.normal,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking['listing_name'] ?? 'Pro-Voice Setup', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(booking['location_address'] ?? 'Perungudi, Chennai', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Row(
                            children: [
                              Text('Direction ', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              Icon(Icons.near_me, color: Colors.blueAccent, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            // Vendor Card
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12), 
                      child: Image.network(
                        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=100', // Still placeholder for avatar but name and data is real
                        width: 60, height: 60, fit: BoxFit.cover
                      )
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VENDOR', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
                          Text(booking['vendor_company_name'] ?? booking['vendor_contact_person'] ?? 'Stephen James', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Report', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Order Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Payment Breakdown Card
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('UNLOCK COUPON', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                            child: const Text('Claim Now', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentRow('Total MRP', '₹${totalPrice.toStringAsFixed(0)}'),
                    _buildPaymentRow('Discount on MRP', '-₹798', isDiscount: true),
                    _buildPaymentRow('Platform Fee', '₹10'),
                    const SizedBox(height: 12),
                    _buildPaymentRow('Rental Total', '₹${(totalPrice - 798 + 10).toStringAsFixed(0)}'),
                    _buildPaymentRow('Security Deposit', '₹3,000'),
                    const Divider(height: 32, color: Colors.white10),
                    _buildPaymentRow('Total Amount', '₹${(totalPrice - 798 + 10 + 3000).toStringAsFixed(0)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: (status.toLowerCase() != 'canceled' && status.toLowerCase() != 'cancelled' && status.toLowerCase() != 'completed' && status.toLowerCase() != 'returned')
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CancelBookingScreen(booking: booking),
                    ),
                  );
                  if (result == true) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking successfully canceled.')),
                      );
                      Navigator.pop(context, true); // Pop out of detail screen
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA68C8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProductCard(String name, String address, DateTime pickup, DateTime returnDate, String? image, double price, String? type) {
    int days = returnDate.difference(pickup).inDays;
    if (days == 0) days = 1;
    final imageUrl = _getSafeImageUrl(image);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16)
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty 
                ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.white10,
                      child: const Icon(Icons.image, color: Colors.white54),
                    ),
                  ) 
                : Container(width: 80, height: 80, color: Colors.white10, child: const Icon(Icons.image, color: Colors.white54)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (type != null && type.toString().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
                        ),
                        child: Text(
                          type.toString().toUpperCase(),
                          style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text(address, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 12),
                    const SizedBox(width: 4),
                    Text('${DateFormat('MMM d').format(pickup)} - ${DateFormat('d').format(returnDate)} ($days Days)', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(color: const Color(0xFFBA68C8), borderRadius: BorderRadius.circular(10)),
                 child: Text('₹${price.toStringAsFixed(0)}/day', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
               )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildItemRow(String name, String quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white70, fontSize: 14))),
          Text(quantity, style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(bool isPickUp, String label, String date, String time) {
    return Row(
      children: [
        Column(
          children: [
            Icon(Icons.circle, color: isPickUp ? const Color(0xFFBA68C8) : Colors.white24, size: 10),
            if (isPickUp) Container(width: 1, height: 20, color: Colors.white10),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.1)),
            Row(
              children: [
                Text(date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('  •  ', style: TextStyle(color: Colors.white24)),
                Text(time, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white60, fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
              if (!isTotal && !isDiscount && label != 'Platform Fee')
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white24),
                ),
            ],
          ),
          Text(value, style: TextStyle(color: isTotal ? const Color(0xFFBA68C8) : isDiscount ? Colors.green : Colors.white70, fontSize: isTotal ? 20 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold)),
        ],
      ),
    );
  }
}
