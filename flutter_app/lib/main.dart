import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OrderManagementApp(),
    ),
  );
}

class OrderManagementApp extends ConsumerWidget {
  const OrderManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Gestão de Encomendas',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
