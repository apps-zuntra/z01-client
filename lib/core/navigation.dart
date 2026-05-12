import 'package:flutter/material.dart';

class AppNavigation {
  static final ValueNotifier<int> selectedTabIndex = ValueNotifier<int>(0);

  static void switchTab(int index, BuildContext context) {
    selectedTabIndex.value = index;
    // If we are deep within a pushed route, pop back to the root (Home)
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }
}
