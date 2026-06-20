import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class CartService {
  static final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);

  // Use a proper StreamController so we push updates only when something changes
  static final StreamController<List<Map<String, dynamic>>> _cartController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  static Stream<List<Map<String, dynamic>>> get cartStream => _cartController.stream;

  static List<Map<String, dynamic>> _cachedItems = [];

  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// Call this once at app startup to seed initial data and open the stream.
  static Future<void> init() async {
    await refresh();
  }

  /// Fetch latest cart from backend, update cache + stream + badge count.
  static Future<List<Map<String, dynamic>>> refresh() async {
    final userId = await _getUserId();
    if (userId == null) {
      _cachedItems = [];
      cartItemCount.value = 0;
      if (!_cartController.isClosed) {
        _cartController.add(_cachedItems);
      }
      return _cachedItems;
    }

    try {
      final items = await ApiService.getCart(userId);
      _cachedItems = items;
      cartItemCount.value = items.length;
      if (!_cartController.isClosed) {
        _cartController.add(_cachedItems);
      }
      return _cachedItems;
    } catch (e) {
      print("Error refreshing cart: $e");
      return _cachedItems;
    }
  }

  /// Returns the current cached list (no network call).
  static List<Map<String, dynamic>> get cachedItems => List.unmodifiable(_cachedItems);

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    return await refresh();
  }

  static Future<void> addToCart(Map<String, dynamic> item) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await ApiService.addToCart(userId, item);
    await refresh();
  }

  static Future<void> removeFromCart(Map<String, dynamic> itemToRemove) async {
    final userId = await _getUserId();
    if (userId == null) return;

    final id = itemToRemove['id'] ?? itemToRemove['cart_item_id'];
    final category = itemToRemove['category'];
    final intListingId = id is int ? id : (int.tryParse(id.toString()) ?? 0);
    await ApiService.removeFromCart(userId, intListingId, category);
    await refresh();
  }

  static Future<void> updateCartItemQuantity(Map<String, dynamic> item, int quantity) async {
    final userId = await _getUserId();
    if (userId == null) return;

    final id = item['id'] ?? item['listing_id'] ?? item['cart_item_id'];
    final category = item['category'];
    if (id != null && category != null) {
      final intListingId = id is int ? id : (int.tryParse(id.toString()) ?? 0);
      await ApiService.updateCartItemQuantity(userId, intListingId, category.toString(), quantity);
      await refresh();
    }
  }

  static Future<void> clearCart() async {
    final userId = await _getUserId();
    if (userId == null) return;

    await ApiService.clearCart(userId);
    _cachedItems = [];
    cartItemCount.value = 0;
    if (!_cartController.isClosed) {
      _cartController.add(_cachedItems);
    }
  }
}
