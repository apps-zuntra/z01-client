import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:animate_do/animate_do.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = null /* TODO: Replace with new API */;
    _fullNameController.text = user?.userMetadata?['full_name'] ?? 'Lina Morgan';
    _emailController.text = user?.email ?? 'linamorgan@gmail.com';
    _phoneController.text = '986789023'; // Example placeholder
    _addressController.text = '2972 Westheimer Rd. Santa Ana, Illinois 85486';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

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
          'Personal Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSectionHeader('IDENTITY DETAILS'),
            const SizedBox(height: 8),
            _buildInputField('Full Name', _fullNameController, Icons.person_outline),
            
            const SizedBox(height: 24),
            _buildSectionHeader('CONTACT DETAILS'),
            const SizedBox(height: 8),
            _buildInputField('Email Address', _emailController, Icons.email_outlined),
            const SizedBox(height: 16),
            _buildInputField('Phone Number', _phoneController, Icons.phone_outlined),
            const SizedBox(height: 16),
            _buildInputField('Address', _addressController, Icons.near_me_outlined),
            
            const SizedBox(height: 32),
            _buildSectionHeaderWithBadge('VERIFICATION STATUS (KYC)', 'Approved'),
            const SizedBox(height: 8),
            _buildVerificationCard(context, Icons.phone_android_outlined, 'Phone Verification', 'Secure OTP Check'),
            const SizedBox(height: 12),
            _buildVerificationCard(context, Icons.badge_outlined, 'Govt ID', 'Secure OTP Check'),
            const SizedBox(height: 12),
            _buildVerificationCard(context, Icons.face_outlined, 'Face Verification', 'Bio-metric match'),
            
            const SizedBox(height: 48),
            FadeInUp(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    // Logic to update user metadata
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF311B92).withOpacity(0.3),
                    foregroundColor: const Color(0xFFBA68C8),
                    side: const BorderSide(color: Color(0xFFBA68C8), width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
    );
  }

  Widget _buildSectionHeaderWithBadge(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.withOpacity(0.3))),
          child: Text(badge, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFBA68C8), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard(BuildContext context, IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFBA68C8), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ],
      ),
    );
  }
}
