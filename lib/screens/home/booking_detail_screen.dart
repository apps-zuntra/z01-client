import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import 'package:animate_do/animate_do.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Map<String, dynamic>? _listingWithVendor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final Map<String, dynamic> data = {}; 
    if (mounted) {
      setState(() {
        _listingWithVendor = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status'] ?? 'upcoming';
    final orderNum = widget.booking['order_number'] ?? '#00000';
    final pickup = DateTime.parse(widget.booking['pickup_date']);
    final returnDate = DateTime.parse(widget.booking['return_date']);
    final totalPrice = (widget.booking['total_price'] as num).toDouble();
    
    final List<dynamic> items = widget.booking['items'] as List? ?? [];
    
    final listing = _listingWithVendor;
    final vendor = listing?['vendors'];

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
        title: Text(
          'Booking $orderNum',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFBA68C8)))
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Hero Image
            FadeInUp(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.network(
                      listing?['image_1'] ?? 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?q=80&w=800&auto=format&fit=crop',
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: Text(items.isEmpty ? '1 Items' : '${items.length} Items', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            // Items List
            if (items.isEmpty)
              _buildItemRow(listing?['listing_title'] ?? 'Product', '× 1')
            else
              ...items.map((item) => _buildItemRow(item['name'] ?? '', '× ${item['quantity'] ?? 1}')),
            
            const SizedBox(height: 32),
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
            
            const SizedBox(height: 40),
            const Text('Timeline & Location', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Timeline Detail Card
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildTimelineRow(true, 'PICK UP', DateFormat('MMM dd, yyyy').format(pickup), DateFormat('hh:mm a').format(pickup)),
                    const SizedBox(height: 16),
                    _buildTimelineRow(false, 'RETURN', DateFormat('MMM dd, yyyy').format(returnDate), DateFormat('hh:mm a').format(returnDate)),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?q=80&w=600&auto=format&fit=crop', // Map placeholder
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
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
                              Text(listing?['listing_title'] ?? 'Pro-Voice Setup', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(listing?['location_address'] ?? 'Perungudi, Chennai', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
            
            const SizedBox(height: 40),
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
                          Text(vendor?['company_name'] ?? vendor?['contact_person'] ?? 'Stephen James', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          if (vendor?['phone'] != null)
                            Text(vendor?['phone'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.phone_outlined, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Text('Payment Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Payment Breakdown Card
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    _buildPaymentRow('Order Amount', '₹${totalPrice.toStringAsFixed(0)}'),
                    _buildPaymentRow('Booking charges (incl. of GST)', '₹550'),
                    _buildPaymentRow('Supercoins Redeemed (30)', '-₹300'),
                    const Divider(height: 32, color: Colors.white10),
                    _buildPaymentRow('To be Paid', '₹${(totalPrice + 550 - 300).toStringAsFixed(0)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
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

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white60, fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
              const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white24),
            ],
          ),
          Text(value, style: TextStyle(color: isTotal ? const Color(0xFFBA68C8) : Colors.white70, fontSize: isTotal ? 20 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold)),
        ],
      ),
    );
  }
}
