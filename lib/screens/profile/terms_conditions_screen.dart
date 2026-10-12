import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color purpleAccent = Color(0xFFCA9AFF);

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
          'Terms & Conditions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: purpleAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: purpleAccent.withOpacity(0.3)),
              ),
              child: const Text(
                'IT ACT, 2000 & INTERMEDIARY RULES',
                style: TextStyle(color: purpleAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'User Agreement — Z01 / Bidly',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Last Updated: October 2026',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildText(
              'This document is an electronic record under the Information Technology Act, 2000 and applicable intermediary rules. These Terms constitute a binding legal agreement between [Bidly Legal Entity Name], a subsidiary of Zuntra ("Company") and users of the Platform.',
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('1. Nature of Services & Intermediary Status'),
            _buildText(
              'The Platform acts as an intermediary online marketplace enabling Vendors and Renters/Bidders to discover, book, and transact. The Company is not the direct seller, owner, or auctioneer of listings posted by third-party vendors.',
            ),

            _buildSectionHeader('2. Account Eligibility & Responsibilities'),
            _buildBulletPoint('You must be at least 18 years of age to register and transact.'),
            _buildBulletPoint('You must provide authentic details during registration and KYC verification.'),
            _buildBulletPoint('You are solely responsible for maintaining credentials confidentiality and activity on your account.'),

            _buildSectionHeader('3. Bidding & Booking Rules'),
            _buildBulletPoint('A bid or booking request is a binding commitment to purchase or rent at the agreed terms upon confirmation.'),
            _buildBulletPoint('Cancellations are subject to the specific cancellation policy stated on each listing.'),
            _buildBulletPoint('Shill bidding, price manipulation, and automated bidding scripts are strictly prohibited.'),

            _buildSectionHeader('4. Vendor & Seller Obligations'),
            _buildBulletPoint('Vendors must describe studio amenities and equipment condition accurately.'),
            _buildBulletPoint('Vendors must hold verified rights/ownership to list equipment and facilities.'),
            _buildBulletPoint('Vendors must fulfill confirmed bookings promptly as scheduled.'),

            _buildSectionHeader('5. Payments, Fees & Security Deposits'),
            _buildText(
              'All transactions are handled via authorized payment gateways (Razorpay). Users agree to pay listed rental fees, platform convenience fees, and applicable GST. Security deposits are refunded upon safe return of equipment and studio check-out inspection.',
            ),

            _buildSectionHeader('6. Prohibited Conduct'),
            _buildBulletPoint('Do not attempt to take transactions offline to circumvent platform fees.'),
            _buildBulletPoint('Do not post illegal, counterfeit, or infringing listings.'),
            _buildBulletPoint('Do not upload fraudulent reviews or harass other members.'),

            _buildSectionHeader('7. Limitation of Liability & Dispute Resolution'),
            _buildText(
              'These Terms are governed by the laws of India. Any disputes will be subject to arbitration under the Arbitration and Conciliation Act, 1996 in India.',
            ),

            _buildSectionHeader('8. Grievance Redressal'),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E28),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grievance Officer: [Grievance Officer Name]', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 6),
                  Text('Entity: [Bidly Legal Entity Name], subsidiary of Zuntra', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Email: grievance@zuntra.com / support@zuntra.com', style: TextStyle(color: purpleAccent, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('All queries will be acknowledged within 24 hours and addressed within 15 days.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFFCA9AFF), fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFCA9AFF), fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45)),
          ),
        ],
      ),
    );
  }
}
