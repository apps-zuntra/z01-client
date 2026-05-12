import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:animate_do/animate_do.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool pauseAll = false;
  bool bookingConfirmation = true;
  bool rentalReminders = true;
  bool messages = true;
  bool reviews = false;

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
          'Notification Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSectionHeader('GLOBAL CONTROL'),
            const SizedBox(height: 16),
            _buildSettingTile(
              'Pause all notifications',
              'Temporarily mute push & email',
              pauseAll,
              (val) => setState(() => pauseAll = val),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader('RENTALS & BOOKINGS'),
            const SizedBox(height: 16),
            _buildSettingTile(
              'Booking Confirmation',
              'New Requests and approvals',
              bookingConfirmation,
              (val) => setState(() => bookingConfirmation = val),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              'Rental Reminders',
              'Pick up and return alerts',
              rentalReminders,
              (val) => setState(() => rentalReminders = val),
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              'Messages',
              'Chats from vendors and renters',
              messages,
              (val) => setState(() => messages = val),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader('COMMUNITY'),
            const SizedBox(height: 16),
            _buildSettingTile(
              'Reviews & Feedback',
              'New Requests and approvals',
              reviews,
              (val) => setState(() => reviews = val),
            ),
            
            const SizedBox(height: 80),
            FadeInUp(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    // Reset to defaults
                    setState(() {
                      pauseAll = false;
                      bookingConfirmation = true;
                      rentalReminders = true;
                      messages = true;
                      reviews = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF311B92).withOpacity(0.3),
                    foregroundColor: const Color(0xFFBA68C8),
                    side: const BorderSide(color: Color(0xFFBA68C8), width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildSettingTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFBA68C8),
            activeTrackColor: const Color(0xFFBA68C8).withOpacity(0.3),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
