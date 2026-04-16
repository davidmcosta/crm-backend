import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/providers/auth_provider.dart';
import '../orders/providers/orders_provider.dart';
import '../customers/providers/customers_provider.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth      = ref.watch(authProvider);
    final user      = auth.user;
    final orders    = ref.watch(ordersProvider);
    final canSeeCustomers = user?.isManager == true;
    final customers = canSeeCustomers ? ref.watch(customersProvider) : null;

    const greeting = 'Bem-vindo';

    return Scaffold(
      appBar: AppBar(title: const Text('Início'), centerTitle: false),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Boas-vindas ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF3D3A35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CasaDasCampasLogoHorizontal(light: true, iconSize: 24),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 14),
                Text(
                  '$greeting, ${user?.name.split(' ').first ?? ''}!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _roleDescription(user?.role ?? ''),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Resumo rápido ──────────────────────────────────────────────────
          const Text('Resumo',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2_outlined,
                label: 'Encomendas',
                value: orders.isLoading ? '…' : '${orders.total}',
                color: AppTheme.primary,
                onTap: () => context.go('/orders'),
              ),
            ),
            if (canSeeCustomers) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.people_outline,
                  label: 'Clientes',
                  value: customers == null || customers.isLoading ? '…' : '${customers.total}',
                  color: AppTheme.gold,
                  onTap: () => context.go('/customers'),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _StatCard(
                icon: Icons.hourglass_empty_outlined,
                label: 'Pendentes',
                value: orders.isLoading
                    ? '…'
                    : '${orders.orders.where((o) => o.status == 'PENDING').length}',
                color: AppTheme.warning,
                onTap: () {
                  ref.read(ordersProvider.notifier).setFilter(
                    const OrdersFilter(status: 'PENDING'),
                  );
                  context.go('/orders');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.precision_manufacturing_outlined,
                label: 'Em progresso',
                value: orders.isLoading
                    ? '…'
                    : '${orders.orders.where((o) => o.status == 'IN_PRODUCTION').length}',
                color: const Color(0xFF8A5C2A),
                onTap: () {
                  ref.read(ordersProvider.notifier).setFilter(
                    const OrdersFilter(status: 'IN_PRODUCTION'),
                  );
                  context.go('/orders');
                },
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Acções rápidas ─────────────────────────────────────────────────
          const Text('Acções Rápidas',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          const SizedBox(height: 12),

          _QuickAction(
            icon: Icons.add_circle_outline,
            label: 'Nova Encomenda',
            description: 'Registar uma nova encomenda',
            color: AppTheme.gold,
            onTap: () => context.push('/orders/new'),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.inventory_2_outlined,
            label: 'Ver Encomendas',
            description: 'Consultar e gerir encomendas',
            color: AppTheme.primary,
            onTap: () => context.go('/orders'),
          ),
          if (canSeeCustomers) ...[
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.people_outline,
              label: 'Clientes',
              description: 'Gerir base de clientes',
              color: const Color(0xFF6B6355),
              onTap: () => context.go('/customers'),
            ),
          ],
          if (user?.isAdmin == true) ...[
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.manage_accounts_outlined,
              label: 'Utilizadores',
              description: 'Gerir contas de utilizador',
              color: const Color(0xFF8A5C2A),
              onTap: () => context.go('/users'),
            ),
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.settings_outlined,
              label: 'Configurações',
              description: 'Numeração, custos e anos visíveis',
              color: AppTheme.primary,
              onTap: () => context.go('/settings'),
            ),
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.bar_chart_outlined,
              label: 'Desempenho',
              description: 'Gráficos, estatísticas e faturação',
              color: AppTheme.gold,
              onTap: () => context.go('/analytics'),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _roleDescription(String role) {
    switch (role) {
      case 'ADMIN':    return 'Administrador · Acesso total';
      case 'MANAGER':  return 'Gestor · Gestão de encomendas e clientes';
      case 'OPERATOR': return 'Operador · Criação e edição de encomendas';
      default:         return 'Visualizador · Consulta de encomendas';
    }
  }
}

// ── Cartão de estatística ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppTheme.border),
                  ],
                ),
                const SizedBox(height: 12),
                Text(value,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ),
      );
}

// ── Acção rápida ──────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.primary)),
          subtitle: Text(description,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMuted)),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.border),
          onTap: onTap,
        ),
      );
}
