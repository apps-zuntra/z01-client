import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'customer_confirm_delivery_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if we need to show the completion prompt (from Push Notification)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['showCompletionPrompt'] == true && args['bookingId'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCompletionDialog(args['bookingId'].toString());
        // Clear args so it doesn't show again on rebuild
        ModalRoute.of(context)?.settings.arguments == null;
      });
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final bookings = await ApiService.getUserBookings();
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  void _showCompletionDialog(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirm Completion', style: TextStyle(color: Colors.white)),
        content: const Text('Is your booking completed?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFCA9AFF))),
              );

              final success = await ApiService.completeBooking(bookingId);
              
              if (mounted) Navigator.pop(context); // pop loading

              if (success) {
                _loadBookings();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking marked as completed!')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to complete booking')),
                  );
                }
              }
            },
            child: const Text('Yes', style: TextStyle(color: Color(0xFFCA9AFF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Booking History', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFCA9AFF)))
          : _bookings.isEmpty
              ? const Center(child: Text('No bookings found', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                      final String rawStatus = booking['status']?.toString().toLowerCase().trim() ?? '';
                      String displayStatus = rawStatus;
                      if (rawStatus == 'paid' || rawStatus == 'pending') {
                        displayStatus = 'Upcoming';
                      } else if (rawStatus == 'confirmed' || rawStatus == 'approved' || rawStatus == 'accepted' || rawStatus == 'delivered') {
                        displayStatus = 'Ongoing';
                      } else if (rawStatus == 'completed') {
                        displayStatus = 'Completed';
                      }

                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(booking['listing_name'] ?? 'Booking #${booking['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Status: $displayStatus\nTotal: ₹${booking['total_amount']}', style: const TextStyle(color: Colors.white70)),
                          trailing: rawStatus == 'delivered' ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerConfirmDeliveryScreen(booking: booking),
                                ),
                              ).then((_) => _loadBookings());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCA9AFF),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Confirm Delivery', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ) : null,
                        ),
                      );
                  },
                ),
    );
  }
}
