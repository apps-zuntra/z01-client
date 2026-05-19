import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'package:animate_do/animate_do.dart';

class CancelBookingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const CancelBookingScreen({super.key, required this.booking});

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  String? _selectedReason;
  final TextEditingController _reasonController = TextEditingController();
  bool _isCanceling = false;

  final List<String> _reasons = [
    'Change of plans',
    'Found a better alternative',
    'Price is too high',
    'Booked by mistake',
    'Other'
  ];

  Future<void> _cancelBooking() async {
    if (_selectedReason == null && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or provide a reason for cancellation')),
      );
      return;
    }

    setState(() {
      _isCanceling = true;
    });

    final reason = _selectedReason ?? 'Other';
    final details = _reasonController.text.trim();
    final finalReason = details.isNotEmpty ? '$reason: $details' : reason;

    final success = await ApiService.cancelBooking(widget.booking['id'].toString(), finalReason);

    if (mounted) {
      setState(() {
        _isCanceling = false;
      });
      if (success) {
        Navigator.pop(context, true); // Return true to indicate successful cancellation
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel booking. Please try again later.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime pickup = DateTime.now();
    DateTime returnDate = DateTime.now().add(const Duration(days: 1));
    if (widget.booking['start_date'] != null) {
      pickup = DateTime.tryParse(widget.booking['start_date'].toString()) ?? pickup;
    }
    if (widget.booking['end_date'] != null) {
      returnDate = DateTime.tryParse(widget.booking['end_date'].toString()) ?? returnDate;
    }

    int days = returnDate.difference(pickup).inDays;
    if (days == 0) days = 1;
    
    final totalPrice = double.tryParse(widget.booking['total_amount']?.toString() ?? '0') ?? 0.0;

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
          'Cancel Booking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product card
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.booking['image_1'] != null 
                        ? Image.network(widget.booking['image_1'], width: 80, height: 80, fit: BoxFit.cover) 
                        : Container(width: 80, height: 80, color: Colors.white10, child: const Icon(Icons.image, color: Colors.white54)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.booking['listing_name'] ?? 'Product', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Expanded(child: Text(widget.booking['location_address'] ?? 'Location', style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(color: const Color(0xFFBA68C8), borderRadius: BorderRadius.circular(10)),
                           child: Text('₹${totalPrice.toStringAsFixed(0)}/day', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                         )
                      ],
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            // Cancellation Policies
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Cancellation Polices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 6),
                          Text('You can cancel your booking up to 8 hours before the start time.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: const Text('Reason for Canceling', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF1E1E1E),
                    isExpanded: true,
                    hint: const Text('Select a Reason', style: TextStyle(color: Colors.white54)),
                    value: _selectedReason,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                    items: _reasons.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedReason = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: const Text('Tell us more', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: TextField(
                controller: _reasonController,
                maxLines: 5,
                maxLength: 500,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add additional details...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: const TextStyle(color: Colors.white54),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Refund will be processed to your original payment method within 5-7 business days.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            FadeInUp(
              delay: const Duration(milliseconds: 700),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFBA68C8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keep Booking', style: TextStyle(color: Color(0xFFBA68C8), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCanceling ? null : _cancelBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFBA68C8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isCanceling 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Cancel Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
