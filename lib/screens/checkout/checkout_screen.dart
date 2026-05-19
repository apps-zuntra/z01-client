import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import '../../services/api_service.dart';
import '../../services/cart_service.dart';
import 'dart:async';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int? _selectedPaymentIndex = 0; // Default to first card
  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer?.cancel();
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Session Timeout', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Your checkout session has timed out. Would you like to continue and refresh the timer?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to cart
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA68C8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _resetTimer();
            },
            child: const Text('Continue', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _resetTimer() {
    if (mounted) {
      setState(() {
        _secondsRemaining = 300;
      });
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = (seconds ~/ 60);
    int secs = (seconds % 60);
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double totalMRP = 0;
    for (var item in widget.items) {
      final priceValue = item['price'] ?? 0;
      totalMRP += (priceValue is num) ? priceValue : (double.tryParse(priceValue.toString()) ?? 0);
    }

    double discount = totalMRP * 0.06;
    double platformFee = 10;
    double rentalTotal = totalMRP - discount + platformFee;
    double securityDeposit = 3000;
    double totalAmount = platformFee + securityDeposit; // Payable now

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Checkout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Center(
                  child: Text(
                    'Complete your booking in ${_formatTime(_secondsRemaining)} mins',
                    style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                _buildOrderSummaryCard(totalMRP, discount, platformFee, rentalTotal, securityDeposit, totalAmount),
                const SizedBox(height: 32),
                _buildSectionHeader('Credit & Debit Cards'),
                const SizedBox(height: 16),
                _buildPaymentOption(0, 'ICCI Bank Card **** 3006', Icons.credit_card, isVisa: true),
                _buildAddOption('Add New Card'),
                const SizedBox(height: 32),
                _buildSectionHeader('Pay by apps & UPI'),
                const SizedBox(height: 16),
                _buildUPIMethod(1, 'Google pay', 'https://img.icons8.com/color/48/google-pay.png', Icons.account_balance_wallet, color: Colors.blue),
                _buildUPIMethod(2, 'Paytm', 'https://img.icons8.com/color/48/paytm.png', Icons.account_balance_wallet, color: Colors.lightBlue),
                _buildAddOption('Add New UPI'),
                const SizedBox(height: 180),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 100,
            child: FadeInUp(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBA68C8).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _showPaymentProcessing(context, totalAmount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA68C8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 18),
                      const SizedBox(width: 8),
                      Text('Secure Payment ₹${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentProcessing(BuildContext context, double totalAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFBA68C8)),
            const SizedBox(height: 24),
            const Text('Processing Payment...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Please do not close the app', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () async {
      bool allSuccessful = true;
      
      // Create bookings in backend
      for (var item in widget.items) {
        final price = item['price'] ?? 0;
        final success = await ApiService.createBooking({
          'listing_id': item['id'],
          'start_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'end_date': DateTime.now().add(const Duration(days: 8)).toIso8601String(),
          'total_amount': (price is num) ? price : (double.tryParse(price.toString()) ?? 0),
          'status': 'confirmed'
        });
        
        if (success) {
          await CartService.removeFromCart(item);
        } else {
          allSuccessful = false;
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        if (allSuccessful) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Some bookings failed to create. Please check your internet.')),
          );
        }
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Payment Successful!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your booking has been confirmed.', 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Return to home and clear stack
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA68C8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(double totalMRP, double discount, double platformFee, double rentalTotal, double securityDeposit, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4FC3F7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSummaryRow('Total MRP', '₹${totalMRP.toStringAsFixed(0)}'),
          _buildSummaryRow('Discount on MRP', '-₹${discount.toStringAsFixed(0)}', isDiscount: true),
          _buildSummaryRow('Platform Fee', '₹${platformFee.toStringAsFixed(0)}'),
          const Divider(color: Colors.white10, height: 24),
          _buildSummaryRow('Rental Total', '₹${rentalTotal.toStringAsFixed(0)}', isBold: true),
          _buildSummaryRow('Security Deposit', '₹${securityDeposit.toStringAsFixed(0)}', showInfo: true),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Amount',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('(Payable Now)',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                ],
              ),
              Text('₹${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isBold = false, bool showInfo = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  )),
              if (showInfo) ...[
                const SizedBox(width: 4),
                Icon(Icons.info_outline, color: Colors.white.withOpacity(0.3), size: 14),
              ],
            ],
          ),
          Text(value,
              style: TextStyle(
                color: isDiscount ? Colors.greenAccent : Colors.white,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaymentOption(int index, String title, IconData icon, {bool isVisa = false}) {
    bool isSelected = _selectedPaymentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFBA68C8).withOpacity(0.5) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isVisa ? Colors.blue : Colors.white54, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFFBA68C8) : Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIMethod(int index, String title, String logoUrl, IconData fallbackIcon, {Color? color}) {
    bool isSelected = _selectedPaymentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFBA68C8).withOpacity(0.5) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Image.network(
                logoUrl,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: color ?? Colors.white54, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFFBA68C8) : Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.add, color: Color(0xFFBA68C8), size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(color: Color(0xFFBA68C8), fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
