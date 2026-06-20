import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../home/home_screen.dart';
import '../home/bookings_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String orderReference;
  final DateTime pickupDate;
  final double remainingAmount;
  final double securityDeposit;
  final double totalPaid;

  const PaymentSuccessScreen({
    super.key,
    required this.orderReference,
    required this.pickupDate,
    required this.remainingAmount,
    required this.securityDeposit,
    required this.totalPaid,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0', 'en_IN');
    String displayId = orderReference.toUpperCase();
    if (displayId.length > 8) {
      displayId = displayId.substring(0, 8);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Payment Successful',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFCA9AFF).withOpacity(0.5), width: 1.5),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCA9AFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Deposit Successful',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 40),
                        
                        _buildRow('Order Reference', '#$displayId'),
                        _buildRow('Pickup Time', DateFormat('MMM d, hh:mm a').format(pickupDate)),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: Colors.white10),
                        ),
                        
                        _buildRow('Remaining to be paid', '₹${numberFormat.format(remainingAmount)}'),
                        _buildRow('Security Deposit', '₹${numberFormat.format(securityDeposit)}', showInfo: true, isBold: true),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: Colors.white10),
                        ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('(Paid)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                              ],
                            ),
                            Text('₹${numberFormat.format(totalPaid)}', style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 24, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('Remaining Balance', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'The remaining rental balance of ₹${numberFormat.format(remainingAmount)} is to be paid directly to the studio/ vendor at the time of pickup.',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookingsScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCA9AFF),
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('View Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFCA9AFF),
                            side: const BorderSide(color: Color(0xFFCA9AFF)),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Return to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, bool showInfo = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(color: isBold ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
              if (showInfo) ...[
                const SizedBox(width: 4),
                const Icon(Icons.info_outline, color: Colors.white38, size: 14),
              ],
            ],
          ),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
