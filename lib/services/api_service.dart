import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/listing_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    // 10.0.2.2 is only for the Android Emulator. 
    // For a physical phone, use your laptop's local IP address.
    return 'http://192.168.1.45:3000'; 
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'password': password,
          'required_role': 'customer'
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', data['data']['id'].toString());
          await prefs.setString('user_email', data['data']['email']);
          await prefs.setString('user_name', data['data']['name']);
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name, 
          'email': email, 
          'password': password,
          'user_type': 'customer'
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', data['data']['id'].toString());
          await prefs.setString('user_email', data['data']['email']);
          await prefs.setString('user_name', data['data']['name']);
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Register Error: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<List<ListingModel>> getStudios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/studios'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List? ?? [];
        return list.map((e) => ListingModel.fromJson(e)).toList();
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
        return list.map((e) => ListingModel.fromJson(e)).toList();
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
        return list.map((e) => ListingModel.fromJson(e)).toList();
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
      
      bookingData['user_id'] = int.parse(userId);
      
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingData),
      );
      
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
      return response.statusCode == 201;
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
}
