import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);
  static const String _cartKey = 'user_cart_items';

  static Future<void> init() async {
    final items = await getCartItems();
    cartItemCount.value = items.length;
  }

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartStr = prefs.getString(_cartKey);
    if (cartStr == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(cartStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print("Error decoding cart: $e");
      return [];
    }
  }

  static Future<void> addToCart(Map<String, dynamic> item) async {
    final items = await getCartItems();
    
    // Check if item already exists (simplified)
    bool exists = items.any((i) => i['id'] == item['id'] && i['category'] == item['category']);
    if (!exists) {
      items.add(item);
      await _saveCart(items);
    }
  }

  static Future<void> removeFromCart(dynamic id, String category) async {
    final items = await getCartItems();
    items.removeWhere((i) => i['id'] == id && i['category'] == category);
    await _saveCart(items);
  }

  static Future<void> clearCart() async {
    await _saveCart([]);
  }

  static Future<void> _saveCart(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(items));
    cartItemCount.value = items.length;
  }

  static Stream<List<Map<String, dynamic>>> get cartStream async* {
    // This is a simple mock stream. Ideally, use a BehaviorSubject or similar.
    // For now, we'll yield the current value and then wait for changes.
    while (true) {
      yield await getCartItems();
      await Future.delayed(const Duration(seconds: 1)); // Poll for changes or use a proper notifier
    }
  }
}
