import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'design/tokens.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.child});

  final Widget child;

  int _index(String location) {
    if (location.startsWith('/lots')) return 1;
    if (location.startsWith('/suppliers')) return 2;
    if (location.startsWith('/sales')) return 3;
    if (location.startsWith('/pnl')) return 4;
    if (location.startsWith('/partners')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        height: 72.h,
        selectedIndex: _index(location),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
            case 1:
              context.go('/lots');
            case 2:
              context.go('/suppliers');
            case 3:
              context.go('/sales');
            case 4:
              context.go('/pnl');
            case 5:
              context.go('/partners');
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: AppTokens.navIconSize),
            selectedIcon: Icon(Icons.dashboard, size: AppTokens.navIconSize),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined, size: AppTokens.navIconSize),
            selectedIcon: Icon(Icons.inventory_2, size: AppTokens.navIconSize),
            label: 'Lots',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined, size: AppTokens.navIconSize),
            selectedIcon: Icon(Icons.store, size: AppTokens.navIconSize),
            label: 'Suppliers',
          ),
          NavigationDestination(
            icon: Icon(Icons.sell_outlined, size: AppTokens.navIconSize),
            selectedIcon: Icon(Icons.sell, size: AppTokens.navIconSize),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined, size: AppTokens.navIconSize),
            selectedIcon: Icon(Icons.analytics, size: AppTokens.navIconSize),
            label: 'P&L',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, size: AppTokens.navIconSize),
            selectedIcon: Icon(Icons.people, size: AppTokens.navIconSize),
            label: 'Partners',
          ),
        ],
      ),
    );
  }
}
