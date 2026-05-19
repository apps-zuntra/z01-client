import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class CartService {
  static final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);

  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> init() async {
    final items = await getCartItems();
    cartItemCount.value = items.length;
  }

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final userId = await _getUserId();
    if (userId == null) return [];
    
    try {
      final items = await ApiService.getCart(userId);
      cartItemCount.value = items.length;
      return items;
    } catch (e) {
      print("Error getting remote cart: $e");
      return [];
    }
  }

  static Future<void> addToCart(Map<String, dynamic> item) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await ApiService.addToCart(userId, item);
    final items = await getCartItems();
    cartItemCount.value = items.length;
  }

  static Future<void> removeFromCart(Map<String, dynamic> itemToRemove) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await ApiService.removeFromCart(userId, itemToRemove['id'] ?? itemToRemove['cart_item_id'], itemToRemove['category']);
    final items = await getCartItems();
    cartItemCount.value = items.length;
  }

  static Future<void> clearCart() async {
    final userId = await _getUserId();
    if (userId == null) return;

    await ApiService.clearCart(userId);
    cartItemCount.value = 0;
  }

  static Stream<List<Map<String, dynamic>>> get cartStream async* {
    while (true) {
      yield await getCartItems();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
