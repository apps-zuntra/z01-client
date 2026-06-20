import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/floating_navbar.dart';
import '../../core/navigation.dart';
import '../../services/api_service.dart';
import '../../services/cart_service.dart';
import 'payment_success_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

  // Selected filters loaded from home screen
  DateTime? _sharedFilterDate;
  int? _sharedFilterCount;
  String? _sharedFilterRentalType;

  bool _isProcessingPayment = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadFilters();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verificationResult = await ApiService.verifyPayment({
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });

      if (verificationResult['success'] == true) {
        await CartService.clearCart();
        if (mounted) {
          setState(() => _isProcessingPayment = false);

          double totalMRP = 0;
          for (var item in widget.items) {
            final priceValue = item['price'] ?? item['price_per_day'] ?? item['price_per_hour'] ?? 0;
            final double doublePrice = (priceValue is num) ? priceValue.toDouble() : (double.tryParse(priceValue.toString()) ?? 0.0);
            totalMRP += doublePrice * (item['quantity'] ?? 1);
          }

          double securityDeposit = widget.items.fold(0.0, (sum, item) {
            final dep = item['deposit_amount'];
            final val = (dep is num) ? dep.toDouble() : (double.tryParse(dep?.toString() ?? '0') ?? 0.0);
            return sum + (val * (item['quantity'] ?? 1));
          });
          
          double platformFee = securityDeposit * 0.10;
          double totalAmountPaid = securityDeposit + platformFee;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                orderReference: response.orderId ?? 'Z01-ORDER',
                pickupDate: _sharedFilterDate ?? DateTime.now().add(const Duration(days: 1)),
                remainingAmount: totalMRP,
                securityDeposit: securityDeposit,
                totalPaid: totalAmountPaid,
              ),
            ),
          );
        }
      } else {
        throw verificationResult['error'] ?? 'Verification failed on server';
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment verification failed: $e')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response.message}')),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet selected: ${response.walletName}')),
      );
    }
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('filter_date');
    final countVal = prefs.getInt('filter_count');
    final rentalTypeVal = prefs.getString('filter_rental_type');
    if (mounted) {
      setState(() {
        if (dateStr != null) {
          _sharedFilterDate = DateTime.tryParse(dateStr);
        }
        _sharedFilterCount = countVal;
        _sharedFilterRentalType = rentalTypeVal;
      });
    }
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
              backgroundColor: const Color(0xFFCA9AFF),
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
    _razorpay.clear();
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
      final priceValue = item['price'] ?? item['price_per_day'] ?? item['price_per_hour'] ?? 0;
      final double doublePrice = (priceValue is num) ? priceValue.toDouble() : (double.tryParse(priceValue.toString()) ?? 0.0);
      totalMRP += doublePrice * (item['quantity'] ?? 1);
    }

    // Dynamically sum security deposits from items
    double securityDeposit = widget.items.fold(0.0, (sum, item) {
      final dep = item['deposit_amount'];
      final val = (dep is num) ? dep.toDouble() : (double.tryParse(dep?.toString() ?? '0') ?? 0.0);
      return sum + (val * (item['quantity'] ?? 1));
    });

    double platformFee = securityDeposit * 0.10; // 10% of security deposit
    double totalAmount = securityDeposit + platformFee; // Payable now strictly security deposit + platform fee

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
                    style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                _buildOrderSummaryCard(totalMRP, platformFee, securityDeposit, totalAmount),
                _buildPickupWarningCard(totalMRP, securityDeposit),
                const SizedBox(height: 32),
                _buildSectionHeader('Credit & Debit Cards'),
                const SizedBox(height: 16),
                _buildAddOption(0, 'Add New Card', Icons.credit_card),
                const SizedBox(height: 32),
                _buildSectionHeader('Pay by apps & UPI'),
                const SizedBox(height: 16),
                _buildUPIMethod(1, 'Google pay', 'https://img.icons8.com/color/48/google-pay.png', Icons.account_balance_wallet, color: Colors.blue),
                _buildUPIMethod(2, 'Paytm', 'https://img.icons8.com/color/48/paytm.png', Icons.account_balance_wallet, color: Colors.lightBlue),
                _buildUPIMethod(3, 'PhonePe', 'https://img.icons8.com/color/48/phonepe.png', Icons.account_balance_wallet, color: const Color(0xFFCA9AFF)),
                _buildAddOption(4, 'Add New UPI', Icons.add),
                const SizedBox(height: 180),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 100,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCA9AFF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : () {
                  String method = _selectedPaymentIndex == 0 ? 'card' : 'upi';
                  _processPayment(method: method);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCA9AFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFFCA9AFF).withOpacity(0.6),
                ),
                child: _isProcessingPayment
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
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
        ],
      ),
    );
  }

  Future<void> _processPayment({String? method}) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      bool allSuccess = true;
      for (var item in widget.items) {
        final listingId = item['id'] ?? item['listing_id'] ?? item['cart_item_id'];
        final priceValue = item['price'] ?? item['price_per_day'] ?? item['price_per_hour'] ?? 0;
        final double doublePrice = (priceValue is num) ? priceValue.toDouble() : (double.tryParse(priceValue.toString()) ?? 0.0);
        final int qty = item['quantity'] ?? 1;
        final double itemTotal = doublePrice * qty;

        // Since cart items don't have explicit dates, generate default dates for the booking
        final startDate = DateTime.now().add(const Duration(days: 1));
        final endDate = startDate.add(const Duration(days: 3));

        final success = await ApiService.createBooking({
          'listing_id': listingId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'total_amount': itemTotal,
          'status': 'pending',
          'deposit_amount': (double.tryParse(item['deposit_amount']?.toString() ?? '0') ?? 0.0) * qty,
        });
        if (!success) {
          allSuccess = false;
        }
      }
      
      if (allSuccess) {
        final bookings = await ApiService.getUserBookings();
        if (bookings.isEmpty) throw 'No bookings found after creation';
        
        final latestBookings = bookings.take(widget.items.length);
        final bookingIds = latestBookings.map((b) => b['id'].toString()).join(',');

        final orderResponse = await ApiService.createPaymentOrder(bookingIds);
        if (orderResponse == null || !orderResponse['success']) {
          throw 'Failed to create payment order';
        }

        var options = {
          'key': 'rzp_live_SRoJY9zxg1WtPH',
          'amount': orderResponse['amount'],
          'name': 'Z01 Equipment',
          'description': 'Deposit for Cart Items',
          'order_id': orderResponse['orderId'],
          'prefill': {
            'contact': '',
            'email': '',
            if (method != null) 'method': method,
          },
          'theme': {
            'color': '#BA68C8'
          }
        };

        _razorpay.open(options);
      } else {
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process some items in your booking.')),
          );
        }
      }
    } catch (e) {
      print("Checkout error: $e");
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
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
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCA9AFF),
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

  Widget _buildPickupWarningCard(double rentalTotal, double securityDeposit) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2442),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCA9AFF).withOpacity(0.3), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFCA9AFF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Balance Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      height: 1.45,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      const TextSpan(text: 'The remaining rental balance of '),
                      TextSpan(
                        text: '₹${rentalTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const TextSpan(text: ' is to be paid directly to the studio/ vendor at the time of pickup.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(double totalMRP, double platformFee, double securityDeposit, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCA9AFF).withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSummaryRow('Total MRP', '₹${totalMRP.toStringAsFixed(0)}'),
          _buildSummaryRow('Platform Fee', '₹${platformFee.toStringAsFixed(0)}'),
          const Divider(color: Colors.white10, height: 24),
          _buildSummaryRow('Security Deposit', '₹${securityDeposit.toStringAsFixed(0)}', showInfo: true, isBold: true),
          const Divider(color: Colors.white10, height: 24),
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
                  style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 24, fontWeight: FontWeight.w900)),
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
                color: isDiscount ? const Color(0xFF2EC4B6) : Colors.white,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAddOption(int index, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFCA9AFF), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFCA9AFF),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(
              _selectedPaymentIndex == index ? Icons.radio_button_checked : Icons.radio_button_unchecked, 
              color: _selectedPaymentIndex == index ? const Color(0xFFCA9AFF) : Colors.white54, 
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIMethod(int index, String title, String iconUrl, IconData fallbackIcon, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  iconUrl,
                  errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: color, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Icon(
              _selectedPaymentIndex == index ? Icons.radio_button_checked : Icons.radio_button_unchecked, 
              color: _selectedPaymentIndex == index ? const Color(0xFFCA9AFF) : Colors.white54, 
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
