import 'package:flutter/material.dart';
import '../../services/wishlist_service.dart';
import '../../models/listing_model.dart';

class WishlistButtonWidget extends StatefulWidget {
  final ListingModel listing;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const WishlistButtonWidget({
    super.key,
    required this.listing,
    this.size = 22,
    this.activeColor = Colors.redAccent,
    this.inactiveColor = Colors.white,
  });

  @override
  State<WishlistButtonWidget> createState() => _WishlistButtonWidgetState();
}

class _WishlistButtonWidgetState extends State<WishlistButtonWidget> {
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final wishlisted = await WishlistService.isWishlisted(widget.listing.id);
    if (mounted) {
      setState(() {
        _isWishlisted = wishlisted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isWishlisted ? Icons.favorite : Icons.favorite_border,
        color: _isWishlisted ? widget.activeColor : widget.inactiveColor,
        size: widget.size,
      ),
      onPressed: () async {
        await WishlistService.toggleWishlist(widget.listing);
        _checkWishlistStatus();
      },
    );
  }
}
