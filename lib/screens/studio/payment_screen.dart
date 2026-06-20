import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/constants.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import '../../services/api_service.dart';

import '../../models/listing_model.dart';

class PaymentScreen extends StatefulWidget {
  final ListingModel studio;
  const PaymentScreen({super.key, required this.studio});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Verify payment on backend
    final verificationResult = await ApiService.verifyPayment({
      'razorpay_order_id': response.orderId,
      'razorpay_payment_id': response.paymentId,
      'razorpay_signature': response.signature,
    });

    setState(() => _isProcessing = false);

    if (verificationResult['success'] == true && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment verification failed: ${verificationResult['error'] ?? 'Unknown Error'}')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet selected: ${response.walletName}')),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Create booking in backend
      bool bookingCreated = await ApiService.createBooking({
        'listing_id': widget.studio.id,
        'start_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 4)).toIso8601String(),
        'total_amount': _getDepositAmount(), // Send vendor deposit amount, backend calculates 10% fee
        'deposit_amount': _getDepositAmount(),
      });

      if (!bookingCreated) {
        throw 'Failed to create booking';
      }

      // We need the booking ID. For this implementation, assume createBooking
      // is modified or we fetch the latest booking. Since createBooking just returns bool,
      // let's fetch the user's latest booking to get the ID.
      // This is a temporary workaround. Ideally createBooking should return the booking ID.
      final bookings = await ApiService.getUserBookings();
      if (bookings.isEmpty) throw 'No booking found';
      final latestBooking = bookings.first;
      final bookingId = latestBooking['id'].toString();

      // 2. Create Razorpay order
      final orderResponse = await ApiService.createPaymentOrder(bookingId);
      if (orderResponse == null || !orderResponse['success']) {
        throw 'Failed to create payment order';
      }

      // 3. Open Razorpay Checkout
      var options = {
        'key': 'rzp_live_SRoJY9zxg1WtPH', // Using the provided live key
        'amount': orderResponse['amount'],
        'name': 'Z01 Services',
        'description': 'Deposit for ${widget.studio.listingTitle}',
        'order_id': orderResponse['orderId'],
        'prefill': {
          'contact': '',
          'email': ''
        },
        'theme': {
          'color': '#BA68C8'
        }
      };

      _razorpay.open(options);

    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  double _getBasePrice() {
    final pDay = widget.studio.pricePerDay;
    final pHour = widget.studio.pricePerHour;
    
    num val = 0;
    if (pDay != null) {
      val = pDay;
    } else if (pHour != null) {
      val = pHour;
    }
    return val.toDouble();
  }

  double _getDepositAmount() {
    // If the vendor specified a flat deposit amount, use it. Otherwise fallback to base price.
    if (widget.studio.depositAmount != null && widget.studio.depositAmount! > 0) {
      return widget.studio.depositAmount!;
    }
    return _getBasePrice();
  }

  double _getPlatformFee() {
    return _getDepositAmount() * 0.10;
  }

  double _getTotalAmount() {
    return _getDepositAmount() + _getPlatformFee();
  }

  @override
  Widget build(BuildContext context) {
    final depositAmount = _getDepositAmount();
    final platformFee = _getPlatformFee();
    final total = _getTotalAmount();

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
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                _buildPaymentMethod(Icons.credit_card, 'Razorpay (Cards, UPI, NetBanking)', true),
                const SizedBox(height: 32),
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Deposit Amount', '₹${depositAmount.toStringAsFixed(2)}'),
                _buildSummaryRow('Platform Fee (10%)', '₹${platformFee.toStringAsFixed(2)}'),
                const Divider(height: 32, color: Colors.white10),
                _buildSummaryRow('Total Payable Now', '₹${total.toStringAsFixed(2)}', isTotal: true),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCA9AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm & Pay Deposit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        border: Border.all(color: isSelected ? const Color(0xFFCA9AFF) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? const Color(0xFFCA9AFF) : Colors.white54),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.white))),
          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFCA9AFF), size: 20),
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
            color: isTotal ? const Color(0xFFCA9AFF) : Colors.white,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 14,
          )),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Payment Successful', style: TextStyle(color: Colors.white)),
        content: const Text('Your deposit has been paid and booking is confirmed.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFCA9AFF))),
          ),
        ],
      ),
    );
  }
}
