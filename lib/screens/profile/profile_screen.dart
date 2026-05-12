import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import 'personal_info_screen.dart';
import 'super_coins_screen.dart';
import 'notification_settings_screen.dart';
import 'faq_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'User';
  String _userEmail = 'user@example.com';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _userEmail = prefs.getString('user_email') ?? 'user@example.com';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String username = _userEmail.split('@').first;

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
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBA68C8)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Header
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF262626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 40, color: Colors.white54),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '@$username',
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Menu Items
                  _buildMenuItem(
                    context,
                    Icons.person_outline,
                    'Personal Info',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.stars_outlined,
                    'Super Coins',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperCoinsScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.notifications_outlined,
                    'Notifications',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.help_outline,
                    'FAQ',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen())),
                  ),
                  _buildMenuItem(context, Icons.description_outlined, 'Terms of Service', () {}),
                  _buildMenuItem(context, Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
                  
                  const SizedBox(height: 40),
                  
                  // Logout Button
                  FadeInUp(
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          await ApiService.logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF311B92).withOpacity(0.3),
                          foregroundColor: const Color(0xFFBA68C8),
                          side: const BorderSide(color: Color(0xFFBA68C8), width: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 18),
                            SizedBox(width: 10),
                            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120), // Space for navbar
                ],
              ),
            ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.white70, size: 24),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
