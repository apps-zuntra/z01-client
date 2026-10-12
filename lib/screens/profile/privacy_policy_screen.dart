import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                'DPDP ACT, 2023 & IT ACT, 2000',
                style: TextStyle(color: purpleAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Privacy Policy — Z01 / Bidly',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Last Updated: October 2026',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildText(
              'This Privacy Policy describes how [Bidly Legal Entity Name], a subsidiary of Zuntra ("Company", "we", "us", or "our") collects, uses, and protects personal data of users of the Z01 & Bidly marketplace platform. Published under the Digital Personal Data Protection Act, 2023 and the Information Technology Act, 2000.',
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('1. Definitions'),
            _buildText('• "Personal Data": Any data about an individual who is identifiable by or in relation to such data.'),
            _buildText('• "Data Principal": You, the individual using the Platform (Renter, Bidder, Vendor, or visitor).'),
            _buildText('• "Data Fiduciary": The Company, which determines the purpose and means of data processing.'),
            _buildText('• "Listing": An item, studio, equipment, manpower, or service posted on the Platform.'),

            _buildSectionHeader('2. Information We Collect'),
            _buildBulletPoint('Account Information: Name, email, mobile phone number, login credentials.'),
            _buildBulletPoint('Identity & Verification (KYC): Government IDs (PAN, Aadhaar) for identity verification and anti-fraud.'),
            _buildBulletPoint('Bookings & Bids: Bookings scheduled, bids placed, order history, timestamps.'),
            _buildBulletPoint('Transactions: Payment IDs and payout details handled securely via RBI-authorized payment gateways.'),
            _buildBulletPoint('Location: GPS coordinates (with your explicit permission) to discover studios and equipment near you.'),

            _buildSectionHeader('3. Sensitive Data & Payment Safety'),
            _buildText(
              'Identity documents and payout details are collected solely for KYC, fraud prevention, and disbursement. Payment transactions are processed directly by certified payment gateways (Razorpay). Full credit/debit card numbers or passwords are never stored on our servers.',
            ),

            _buildSectionHeader('4. How We Use Information'),
            _buildBulletPoint('Create and manage accounts and authenticate identities.'),
            _buildBulletPoint('Enable booking studios, renting equipment, hiring talent, and placing bids.'),
            _buildBulletPoint('Process payments, refunds, security deposits, and payouts.'),
            _buildBulletPoint('Deliver push notifications, OTPs, and booking confirmations.'),
            _buildBulletPoint('Detect and prevent fraud, shill bidding, and unauthorized access.'),

            _buildSectionHeader('5. Sharing & Disclosure'),
            _buildText(
              'We never sell your Personal Data. Necessary contact information is shared between renter and vendor strictly to fulfill confirmed bookings. Data is also shared with trusted cloud hosting, payment gateways, and statutory authorities when mandated by law.',
            ),

            _buildSectionHeader('6. Your Rights Under DPDP Act'),
            _buildBulletPoint('Right to Access a summary of personal data held about you.'),
            _buildBulletPoint('Right to Correction and erasure of outdated personal data.'),
            _buildBulletPoint('Right of Grievance Redressal and Nomination.'),

            _buildSectionHeader('7. Grievance Officer & Contact'),
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
                  Text('Email: privacy@zuntra.com / support@zuntra.com', style: TextStyle(color: purpleAccent, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Complaints will be acknowledged within 24 hours and addressed within 15 days.', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
