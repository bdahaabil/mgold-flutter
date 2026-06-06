import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/env.dart';
import '../core/providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/lots/lot_detail_screen.dart';
import '../features/lots/lots_screen.dart';
import '../features/partners/cashout_screen.dart';
import '../features/partners/partners_screen.dart';
import '../features/pnl/pnl_screen.dart';
import '../features/sales/sales_screen.dart';
import '../features/suppliers/supplier_detail_screen.dart';
import '../features/suppliers/suppliers_screen.dart';
import 'shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(isAuthenticatedProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      if (!auth && Env.isConfigured && !loggingIn) return '/login';
      if (auth && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/lots', builder: (_, __) => const LotsScreen()),
          GoRoute(
            path: '/lots/:id',
            builder: (_, state) =>
                LotDetailScreen(lotId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (_, __) => const SuppliersScreen(),
          ),
          GoRoute(
            path: '/suppliers/:id',
            builder: (_, state) =>
                SupplierDetailScreen(supplierId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/sales', builder: (_, __) => const SalesScreen()),
          GoRoute(path: '/pnl', builder: (_, __) => const PnlScreen()),
          GoRoute(
            path: '/partners',
            builder: (_, __) => const PartnersScreen(),
          ),
          GoRoute(
            path: '/partners/cashout',
            builder: (_, __) => const CashoutScreen(),
          ),
        ],
      ),
    ],
  );
});
