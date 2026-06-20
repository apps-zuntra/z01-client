import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/bookings/booking_history_screen.dart'; // Make sure this exists

import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("8ba49c7c-97fb-4410-8354-ccb8dd2abfb5");
  OneSignal.Notifications.requestPermission(true);

  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    if (data != null && data['action'] == 'BOOKING_COMPLETED_CHECK') {
      final bookingId = data['bookingId'];
      if (bookingId != null) {
        // Navigate to booking history screen and pass arguments
        navigatorKey.currentState?.pushNamed('/booking_history', arguments: {'bookingId': bookingId, 'showCompletionPrompt': true});
      }
    }
  });

  // Fire-and-forget ping to wake up the Render backend from sleep
  // This drastically reduces the wait time when the user hits "Login"
  http.get(Uri.parse('https://z01-user-backend.onrender.com/')).catchError((_) => http.Response('', 200));

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  
  runApp(MyApp(isLoggedIn: userId != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Studio Rental App',
      theme: AppTheme.darkTheme,
      home: isLoggedIn ? const HomeScreen() : const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/booking_history': (context) => const BookingHistoryScreen(), // Requires the screen to be implemented
      },
    );
  }
}
