import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:animate_do/animate_do.dart';

class SuperCoinsScreen extends StatelessWidget {
  const SuperCoinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Super Coins',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Coin Balance Card
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF311B92), Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        const Text('12', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                        const Text(' Coins', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Earn more coins by completing bookings', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.6,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(color: const Color(0xFFBA68C8), borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('8 more coins to unlock ₹100 Coupon', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Text(
              'Available Coupons',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildCouponCard('₹100 Off', '20 Coins ( Next Goal)', isUnlocked: false),
            const SizedBox(height: 12),
            _buildCouponCard('10% OFF', '50 Coins Required', isUnlocked: false),
            const SizedBox(height: 12),
            _buildCouponCard('Free Studio Hour', '100 Coins Required', isUnlocked: false),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(String title, String status, {bool isUnlocked = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.stars, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(status, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isUnlocked ? () {} : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isUnlocked ? const Color(0xFFBA68C8) : Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              disabledBackgroundColor: Colors.white.withOpacity(0.05),
              elevation: 0,
            ),
            child: Text(isUnlocked ? 'Redeem Now' : 'Locked', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
