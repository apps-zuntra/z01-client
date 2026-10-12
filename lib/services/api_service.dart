import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../models/listing_model.dart';

class ApiService {
  static String get baseUrl {
    return 'https://zo1backend.vercel.app';
  }

  static const List<String> demoPhones = [
    '9999999999',
    '9876543210',
    '1234567890',
    '8888888888',
    '0000000000',
  ];

  static bool isDemoNumber(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    return demoPhones.contains(last10);
  }

  static Future<Map<String, dynamic>> loginAsDemoReviewer() async {
    final demoUser = {
      'id': '999999',
      'name': 'Google Play Reviewer',
      'email': 'playstore@zuntra.com',
      'phone': '9999999999',
      'user_type': 'customer',
      'role': 'customer',
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', demoUser['id']!);
    await prefs.setString('user_name', demoUser['name']!);
    await prefs.setString('user_email', demoUser['email']!);
    await prefs.setString('user_phone', demoUser['phone']!);
    return demoUser;
  }

  static Future<bool> sendOtp(String mobile, {bool isRegister = false}) async {
    // Play Store Reviewer bypass
    if (isDemoNumber(mobile)) {
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'is_register': isRegister,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          throw data['message'];
        }
        return false;
      }
    } catch (e) {
      if (e is String) rethrow;
      print('Send OTP Error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> verifyOtp(
      String mobile, 
      String otp, 
      {
        String requiredRole = 'customer', 
        String userType = 'customer',
        bool isRegister = false,
        String? name,
        String? email,
      }) async {
    // Play Store Reviewer bypass
    if (isDemoNumber(mobile) && (otp == '123456' || otp == '000000' || otp == '111111')) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'mobile': mobile,
            'otp': otp,
            'required_role': requiredRole,
            'user_type': userType,
            'is_register': isRegister,
            'name': name ?? 'Google Play Reviewer',
            'email': email ?? 'playstore@zuntra.com',
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['data'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', data['data']['id'].toString());
            if (data['data']['email'] != null) await prefs.setString('user_email', data['data']['email']);
            if (data['data']['name'] != null) await prefs.setString('user_name', data['data']['name']);
            if (data['data']['phone'] != null) await prefs.setString('user_phone', data['data']['phone']);
            try { OneSignal.login(data['data']['id'].toString()); } catch (_) {}
            return data['data'];
          }
        }
      } catch (_) {}
      return await loginAsDemoReviewer();
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'otp': otp,
          'required_role': requiredRole,
          'user_type': userType,
          'is_register': isRegister,
          'name': name,
          'email': email,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', data['data']['id'].toString());
          if (data['data']['email'] != null) {
             await prefs.setString('user_email', data['data']['email']);
          }
          if (data['data']['name'] != null) {
             await prefs.setString('user_name', data['data']['name']);
          }
          if (data['data']['phone'] != null) {
             await prefs.setString('user_phone', data['data']['phone']);
          }
          
          OneSignal.login(data['data']['id'].toString());
          
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Verify OTP Error: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    OneSignal.logout();
  }

  static Future<void> submitKyc(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) throw Exception('Not logged in');

      data['user_id'] = userId;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kyc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Backend error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to submit KYC details: ${response.body}');
      }
    } catch (e) {
      print('Error submitting KYC: $e');
      rethrow;
    }
  }

  static Future<void> updatePersonalInfo(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) throw Exception('Not logged in');

      data['user_id'] = userId;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update personal info');
      }
    } catch (e) {
      print('Error updating personal info: $e');
      rethrow;
    }
  }

  static Future<List<ListingModel>> getStudios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/studios'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List? ?? [];
        return list.map((e) {
          if (e is Map<String, dynamic>) {
             e['category'] = e['category']?.toString().isNotEmpty == true ? e['category'] : 'Studio';
          }
          return ListingModel.fromJson(e as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting studios: $e');
      return [];
    }
  }

  static Future<List<ListingModel>> getEquipment() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/equipment'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List? ?? [];
        return list.map((e) {
          if (e is Map<String, dynamic>) {
             e['category'] = e['category']?.toString().isNotEmpty == true ? e['category'] : 'Equipment';
          }
          return ListingModel.fromJson(e as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting equipment: $e');
      return [];
    }
  }

  static Future<List<ListingModel>> getManpower() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/manpower'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List? ?? [];
        return list.map((e) {
          if (e is Map<String, dynamic>) {
             e['category'] = e['category']?.toString().isNotEmpty == true ? e['category'] : 'Manpower';
          }
          return ListingModel.fromJson(e as Map<String, dynamic>);
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting manpower: $e');
      return [];
    }
  }

  static Future<bool> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) return false;
      
      bookingData['user_id'] = userId;
      
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingData),
      ).timeout(const Duration(seconds: 15));
      
      return response.statusCode == 201;
    } catch (e) {
      print('Error creating booking: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getUserBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) return [];
      
      final response = await http.get(Uri.parse('$baseUrl/bookings/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/bookings/detail/$bookingId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createPaymentOrder(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bookingId': bookingId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error creating payment order: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Server returned ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      print('Error verifying payment: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<bool> completeBooking(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/complete'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error completing booking: $e');
      return false;
    }
  }

  static Future<bool> updateLocation(String userId, String address, double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/update-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'address': address,
          'lat': lat,
          'lng': lng,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  static Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error canceling booking: $e');
      return false;
    }
  }

  static Future<List<ListingModel>> searchListings(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/listings/search?q=$query'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List? ?? [];
        return list.map((e) => ListingModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching listings: $e');
      return [];
    }
  }

  static Future<List<ListingModel>> getAllRecentListings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/listings/recent'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List? ?? [];
        return list.map((e) => ListingModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting recent listings: $e');
      return [];
    }
  }

  static Future<ListingModel?> getListingDetail(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/studios/$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final item = data['data'] as Map<String, dynamic>;
          if (item['category'] == null || item['category'].toString().isEmpty) {
            item['category'] = 'Studio';
          }
          return ListingModel.fromJson(item);
        }
      }
      return null;
    } catch (e) {
      print('Error getting listing detail: $e');
      return null;
    }
  }



  static Future<List<dynamic>> getReviews(int listingId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reviews/$listingId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  static Future<bool> postReview(Map<String, dynamic> reviewData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reviewData),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error posting review: $e');
      return false;
    }
  }

  static Future<String?> uploadImage(dynamic imageSource) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/image'));
      
      if (imageSource is String) {
        request.files.add(await http.MultipartFile.fromPath('image', imageSource));
      } else if (imageSource is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes(
          'image', 
          imageSource,
          filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ));
      }
      
      var response = await request.send();
      if (response.statusCode == 201 || response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        return data['url'];
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getVendorListings(String vendorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/listings/vendor/$vendorId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List?) ?? [];
      }
      return [];
    } catch (e) {
      print('Error getting vendor listings: $e');
      return [];
    }
  }

  static String getSafeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    String trimmed = url.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      if (trimmed.startsWith('/')) {
        trimmed = trimmed.substring(1);
      }
      trimmed = '$baseUrl/$trimmed';
    }
    // Automatically route cloudflare R2 and Supabase images through our proxy on Web to bypass CORS!
    if (kIsWeb && (trimmed.contains('r2.dev') || trimmed.contains('cloudflarestorage.com') || trimmed.contains('supabase.co'))) {
      return '$baseUrl/upload/proxy?url=${Uri.encodeComponent(trimmed)}';
    }
    try {
      return Uri.encodeFull(trimmed);
    } catch (e) {
      return trimmed;
    }
  }

  static Future<List<Map<String, dynamic>>> getCart(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cart/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error getting cart: $e');
      return [];
    }
  }

  static Future<bool> addToCart(String userId, Map<String, dynamic> item) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'item': item}),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  static Future<bool> removeFromCart(String userId, int listingId, String category) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/remove'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'listingId': listingId, 'category': category}),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  static Future<bool> updateCartItemQuantity(String userId, int listingId, String category, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/update-quantity'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'listingId': listingId,
          'category': category,
          'quantity': quantity,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error updating cart item quantity: $e');
      return false;
    }
  }

  static Future<bool> clearCart(String userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/cart/clear/$userId'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  static Future<bool> submitReport(Map<String, dynamic> reportData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reportData),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error submitting report: $e');
      return false;
    }
  }
}

