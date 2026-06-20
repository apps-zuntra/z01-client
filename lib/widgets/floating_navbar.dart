import 'package:flutter/material.dart';
import '../core/navigation.dart';

class CustomFloatingNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const CustomFloatingNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppNavigation.selectedTabIndex,
      builder: (context, currentIdx, _) {
        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(context, 0, Icons.home, 'Home', currentIdx),
              _buildNavItem(context, 1, Icons.search, 'Search', currentIdx),
              _buildNavItem(context, 2, Icons.calendar_today_outlined, 'Bookings', currentIdx),
              _buildNavItem(context, 3, Icons.shopping_cart_outlined, 'Cart', currentIdx),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, int currentIdx) {
    bool isSelected = currentIdx == index;
    return GestureDetector(
      onTap: () {
        AppNavigation.switchTab(index, context);
        onTabSelected(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFFCA9AFF) : Colors.white70,
                  size: 26,
                ),
                if (index == 3) // Cart badge
                  ValueListenableBuilder<int>(
                    valueListenable: ValueNotifier<int>(0) /* TODO: Replace with new API */,
                    builder: (context, _, __) {
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: Stream.empty() /* TODO: Replace with new API */,
                        builder: (context, snapshot) {
                          final itemCount = snapshot.data?.length ?? 0;
                          if (itemCount == 0) return const SizedBox();
                          return Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFCA9AFF),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                '$itemCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFCA9AFF) : Colors.white70,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
