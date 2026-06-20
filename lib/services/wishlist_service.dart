import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/listing_model.dart';
import 'api_service.dart'; // To reuse getUserId and baseUrl

class WishlistService {
  static String get baseUrl => ApiService.baseUrl;

  static Future<List<ListingModel>> getWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return [];

    try {
      final response = await http.get(Uri.parse('$baseUrl/wishlist/$userId'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> decodedList = jsonDecode(response.body);
        return decodedList.map((item) => ListingModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching wishlist from backend: $e');
      return [];
    }
  }

  static Future<bool> isWishlisted(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return false;

    try {
      final response = await http.get(Uri.parse('$baseUrl/wishlist/check/$userId/$listingId'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isWishlisted'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking wishlist status: $e');
      return false;
    }
  }

  static Future<void> toggleWishlist(ListingModel listing) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final isCurrentlyWishlisted = await isWishlisted(listing.id);
    
    try {
      if (isCurrentlyWishlisted) {
        await http.post(
          Uri.parse('$baseUrl/wishlist/remove'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'listingId': int.tryParse(listing.id) ?? 0,
          }),
        ).timeout(const Duration(seconds: 10));
      } else {
        await http.post(
          Uri.parse('$baseUrl/wishlist/add'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'listingId': int.tryParse(listing.id) ?? 0,
          }),
        ).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      print('Error toggling wishlist on backend: $e');
    }
  }
}

