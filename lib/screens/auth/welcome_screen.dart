import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../services/api_service.dart';
import '../home/home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color purpleColor = Color(0xFFC490FF); // Light purple from UI
    const Color darkColor = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkColor,
      body: Stack(
        children: [
          // Bottom Left Dark Area with login1.png
          Positioned(
            bottom: -5,
            left: -15,
            child: FadeIn(
              delay: const Duration(milliseconds: 600),
              child: Image.asset(
                'assets/login1.png',
                width: 200, // Adjust size based on image
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Purple Curved Background with login.png pattern
          Positioned.fill(
            child: ClipPath(
              clipper: _WelcomeClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: purpleColor),
                  Image.asset(
                    'assets/login.png',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(1.55), // Subtle pattern overlay
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 120),
                  FadeInDown(
                    child: const Text(
                      'Z01 title',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 2,
                    color: const Color(0xFF1A1A1A),
                  ),
                  const SizedBox(height: 20),
                  FadeInLeft(
                    child: const Text(
                      'BOOK STUDIOS, RENT\nGEAR, AND HIRE\nTALENT',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.3,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: const Text(
                      'Everything Starts here',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF222222),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF262626),
                        foregroundColor: purpleColor,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF262626), 
                        side: const BorderSide(color: Color(0xFF262626), width: 1.2),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Signup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF262626))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          await ApiService.loginAsDemoReviewer();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.verified_user_outlined, color: Colors.white70, size: 16),
                        label: const Text(
                          'Play Store Reviewer / Demo Access',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.9, size.height);
    // Quadratic bezier curve from bottom-rightish to mid-left
    path.quadraticBezierTo(
      size.width * 0.2, size.height * 0.95,
      0, size.height * 0.65
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
