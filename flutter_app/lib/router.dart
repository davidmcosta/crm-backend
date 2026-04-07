import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/orders/models/order_model.dart';
import 'features/orders/screens/orders_list_screen.dart';
import 'features/orders/screens/order_detail_screen.dart';
import 'features/orders/screens/create_order_screen.dart';
import 'features/customers/models/customer_model.dart';
import 'features/customers/screens/customers_list_screen.dart';
import 'features/customers/screens/create_customer_screen.dart';
import 'features/customers/screens/edit_customer_screen.dart';
import 'features/users/screens/users_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn  = authState.isAuthenticated;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/dashboard';
      return null;
    },
    routes: [
      // ── Login ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ── Dashboard ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),

      // ── Encomendas ─────────────────────────────────────────────────────────
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
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) {
                  final order = state.extra as OrderModel?;
                  return CreateOrderScreen(initialOrder: order);
                },
              ),
            ],
          ),
        ],
      ),

      // ── Clientes ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/customers',
        builder: (_, __) => const CustomersListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const CreateCustomerScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (_, state) {
              final customer = state.extra as CustomerModel;
              return EditCustomerScreen(customer: customer);
            },
          ),
        ],
      ),

      // ── Utilizadores ───────────────────────────────────────────────────────
      GoRoute(
        path: '/users',
        builder: (_, __) => const UsersListScreen(),
      ),
    ],
  );
});
