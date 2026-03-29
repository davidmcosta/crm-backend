import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/orders/screens/orders_list_screen.dart';
import 'features/orders/screens/order_detail_screen.dart';
import 'features/orders/screens/create_order_screen.dart';
import 'features/customers/screens/customers_list_screen.dart';
import 'features/customers/screens/create_customer_screen.dart';
import 'shared/widgets/app_drawer.dart';

// Wrapper com Drawer para as páginas principais
class _ScaffoldWithDrawer extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithDrawer({required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const AppDrawer(),
        body: child,
      );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/orders',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/orders';
      return null;
    },
    routes: [
      // Login
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // Encomendas
      GoRoute(
        path: '/orders',
        builder: (_, __) => const OrdersListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const CreateOrderScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                OrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
        ],
      ),

      // Clientes
      GoRoute(
        path: '/customers',
        builder: (_, __) => const CustomersListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const CreateCustomerScreen(),
          ),
        ],
      ),
    ],
  );
});
