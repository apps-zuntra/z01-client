import 'package:flutter/material.dart';
import '../studio/studio_detail_screen.dart';
import '../studio/studio_list_screen.dart';
import '../equipment/equipment_list_screen.dart';
import '../manpower/manpower_list_screen.dart';
import '../checkout/checkout_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants.dart';
import '../../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _selectedCategoryForCheckout;

  void _resetCheckout() {
    setState(() {
      _selectedCategoryForCheckout = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: Stack(
        children: [
          _buildCartList(context),
          _buildTopHeader(context),
        ],
      ),
    );
  }


  Widget _buildTopHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Shopping Cart',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            IconButton(
              onPressed: () => _showClearCartDialog(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: CartService.cartStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFBA68C8)),
          );
        }

        final cartItems = snapshot.data ?? [];

        if (cartItems.isEmpty) {
          return Center(
            child: FadeInDown(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_bag_outlined,
                        size: 100, color: Colors.white.withOpacity(0.05)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Your cart is feeling light',
                      style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Add some items to get started!',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
          );
        }

        // Group items by category
        Map<String, List<Map<String, dynamic>>> groupedItems = {};
        for (var item in cartItems) {
          String cat = item['category'] ?? 'Other';
          if (!groupedItems.containsKey(cat)) {
            groupedItems[cat] = [];
          }
          groupedItems[cat]!.add(item);
        }

        // Filtering if a category is selected for checkout
        final displayedCategories = _selectedCategoryForCheckout != null 
            ? groupedItems.entries.where((e) => (e.key == 'Studio' && _selectedCategoryForCheckout == 'Studios') || 
                                                (e.key == 'Equipment' && _selectedCategoryForCheckout == 'Equipment') || 
                                                (e.key == 'Manpower' && _selectedCategoryForCheckout == 'Manpower') ||
                                                (e.key == _selectedCategoryForCheckout)).toList()
            : groupedItems.entries.toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            if (_selectedCategoryForCheckout == null) ...[
              if (groupedItems.containsKey('Studio'))
                _buildCategorySection(context, 'Studios', groupedItems['Studio']!, const Color(0xFF4FC3F7)),
              if (groupedItems.containsKey('Equipment'))
                _buildCategorySection(context, 'Equipment', groupedItems['Equipment']!, const Color(0xFFFF5252)),
              if (groupedItems.containsKey('Manpower'))
                _buildCategorySection(context, 'Manpower', groupedItems['Manpower']!, const Color(0xFFFFB74D)),
              ...groupedItems.entries
                  .where((e) => e.key != 'Studio' && e.key != 'Equipment' && e.key != 'Manpower')
                  .map((e) => _buildCategorySection(context, e.key, e.value, const Color(0xFFBA68C8))),
            ] else ...[
              // Show only the selected category section with order summary
              ...displayedCategories.map((e) {
                String title = e.key;
                if (title == 'Studio') title = 'Studios';
                return Column(
                  children: [
                    _buildCategorySection(context, title, e.value, _getCategoryColor(title)),
                    _buildOrderSummary(e.value),
                    const SizedBox(height: 24),
                    _buildProceedToCheckoutButton(e.value),
                  ],
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCategorySection(BuildContext context, String title, List<Map<String, dynamic>> items, Color bannerColor) {
    double total = 0;
    for (var item in items) {
      final price = item['price_per_day'] ?? item['price_per_hour'] ?? item['price'] ?? 0;
      total += (price is num) ? price : (double.tryParse(price.toString()) ?? 0);
    }

    final isSelected = _selectedCategoryForCheckout == title;

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelected)
              Row(
                children: [
                  IconButton(
                    onPressed: _resetCheckout,
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Text('(${items.length} Items)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                ],
              )
            else
              Text('View Cart for $title (${items.length})',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (!isSelected)
              Text('Total Cart Value: ₹$total',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            // Super coins banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bannerColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bannerColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: bannerColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will get 100 super coins on this booking',
                      style: TextStyle(color: bannerColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Items List
            ...items.map((item) => _buildProductRow(context, item)),
            const SizedBox(height: 20),
            // Checkout Button
            if (!isSelected)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryForCheckout = title;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA68C8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: Text('Proceed to Rent $title',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                ),
              ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  if (title == 'Studios') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StudioListScreen()));
                  } else if (title == 'Equipment') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EquipmentListScreen()));
                  } else if (title == 'Manpower') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ManpowerListScreen()));
                  }
                },
                child: Text('Continue shopping on $title',
                    style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String title) {
    if (title == 'Studios') return const Color(0xFF4FC3F7);
    if (title == 'Equipment') return const Color(0xFFFF5252);
    if (title == 'Manpower') return const Color(0xFFFFB74D);
    return const Color(0xFFBA68C8);
  }

  Widget _buildOrderSummary(List<Map<String, dynamic>> items) {
    double totalMRP = 0;
    for (var item in items) {
      final price = item['price_per_day'] ?? item['price_per_hour'] ?? item['price'] ?? 0;
      totalMRP += (price is num) ? price : (double.tryParse(price.toString()) ?? 0);
    }
    double discount = totalMRP * 0.06; // Mock 6% discount
    double platformFee = 10;
    double rentalTotal = totalMRP - discount + platformFee;
    double securityDeposit = 3000;
    double totalAmount = platformFee + securityDeposit; // Simplified payable now

    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Unlock Coupon Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2B2B),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                   const Icon(Icons.check_circle_outline, color: Colors.tealAccent, size: 20),
                   const SizedBox(width: 12),
                   const Expanded(
                     child: Text(
                       'UNLOCK COUPON',
                       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                     ),
                   ),
                   TextButton(
                     onPressed: () {},
                     style: TextButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                       backgroundColor: Colors.teal.withOpacity(0.2),
                       minimumSize: Size.zero,
                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                     ),
                     child: const Text('Claim Now', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryRow('Total MRP', '₹${totalMRP.toStringAsFixed(0)}'),
            _buildSummaryRow('Discount on MRP', '-₹${discount.toStringAsFixed(0)}', isDiscount: true),
            _buildSummaryRow('Platform Fee', '₹${platformFee.toStringAsFixed(0)}'),
            const Divider(color: Colors.white10, height: 24),
            _buildSummaryRow('Rental Total', '₹${rentalTotal.toStringAsFixed(0)}', isBold: true),
            _buildSummaryRow('Security Deposit', '₹${securityDeposit.toStringAsFixed(0)}', showInfo: true),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('(Payable Now)',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                  ],
                ),
                Text('₹${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Balance Payment',
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text(
                          'The remaining rental balance is to be paid directly to the studio/vendor at the time of pickup.',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isBold = false, bool showInfo = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  )),
              if (showInfo) ...[
                const SizedBox(width: 4),
                Icon(Icons.info_outline, color: Colors.white.withOpacity(0.3), size: 14),
              ],
            ],
          ),
          Text(value,
              style: TextStyle(
                color: isDiscount ? Colors.greenAccent : (isBold ? Colors.white : Colors.white),
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildProceedToCheckoutButton(List<Map<String, dynamic>> items) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFBA68C8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CheckoutScreen(items: items)),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Proceed to Checkout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, Map<String, dynamic> item) {
    final price = item['price_per_day'] ?? item['price_per_hour'] ?? item['price'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (item['image_1'] != null && item['image_1'].toString().isNotEmpty)
                    ? Image.network(item['image_1'], width: 90, height: 90, fit: BoxFit.cover)
                    : Container(
                        width: 90,
                        height: 90,
                        color: Colors.white10,
                        child: const Icon(Icons.image, color: Colors.white24)),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Upcoming',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['listing_title'] ?? 'N/A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA68C8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('₹$price/day',
                          style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.4), size: 14),
                    const SizedBox(width: 4),
                    Text(item['location_address'] ?? 'Nearby',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.white.withOpacity(0.6), size: 12),
                      const SizedBox(width: 6),
                      Text('Next Week (Selected)',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Delete button
          IconButton(
            onPressed: () async {
              await CartService.removeFromCart(item['id'], item['category']);
              setState(() {});
            },
            icon: Icon(Icons.close, color: Colors.white.withOpacity(0.2), size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Empty your cart?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This will remove all items from your shopping cart.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep them', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              await CartService.clearCart();
              if (mounted) setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
