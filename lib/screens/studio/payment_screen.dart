import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import '../../services/api_service.dart';
import 'package:animate_do/animate_do.dart';

import '../../models/listing_model.dart';

class PaymentScreen extends StatelessWidget {
  final ListingModel studio;
  const PaymentScreen({super.key, required this.studio});

  @override
  Widget build(BuildContext context) {
    num getBasePrice() {
      final pDay = studio.pricePerDay;
      final pHour = studio.pricePerHour;
      
      num val = 0;
      if (pDay != null) {
        val = pDay;
      } else if (pHour != null) {
        val = pHour;
      }
      return val;
    }

    final double basePrice = getBasePrice().toDouble();
    final double serviceFee = basePrice > 0 ? 250 : 0;
    final double gst = (basePrice + serviceFee) * 0.18;
    final double total = basePrice + serviceFee + gst;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  child: const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentMethod(Icons.credit_card, 'Credit / Debit Card', true),
                const SizedBox(height: 12),
                _buildPaymentMethod(Icons.account_balance_wallet_outlined, 'UPI / Wallet', false),
                const SizedBox(height: 12),
                _buildPaymentMethod(Icons.account_balance, 'Net Banking', false),
                const SizedBox(height: 32),
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(studio.listingTitle, '₹${basePrice.toStringAsFixed(2)}'),
                _buildSummaryRow('Service Fee', '₹${serviceFee.toStringAsFixed(2)}'),
                _buildSummaryRow('GST (18%)', '₹${gst.toStringAsFixed(2)}'),
                const Divider(height: 32, color: Colors.white10),
                _buildSummaryRow('Total Amount', '₹${total.toStringAsFixed(2)}', isTotal: true),
                const Spacer(),
                FadeInUp(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await ApiService.createBooking({
                          'listing_id': studio.id,
                          'pickup_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                          'return_date': DateTime.now().add(const Duration(days: 4)).toIso8601String(),
                          'total_price': total,
                        });
                        
                        if (success) {
                          _showSuccessDialog(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to create booking. Please try again.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA68C8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm & Pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 120), // Navbar space
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: CustomFloatingNavbar(
              selectedIndex: AppNavigation.selectedTabIndex.value,
              onTabSelected: (index) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(IconData icon, String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFFBA68C8) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? const Color(0xFFBA68C8) : Colors.white54),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
          const Spacer(),
          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFBA68C8), size: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6))),
          Text(value, style: TextStyle(
            color: isTotal ? const Color(0xFFBA68C8) : Colors.white,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 14,
          )),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Booking Successful', style: TextStyle(color: Colors.white)),
        content: const Text('Your booking has been confirmed.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFBA68C8))),
          ),
        ],
      ),
    );
  }
}
