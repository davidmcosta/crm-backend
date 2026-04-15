import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'brand_logo.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth     = ref.watch(authProvider);
    final user     = auth.user;
    final location = GoRouterState.of(context).uri.toString();

    return Drawer(
      backgroundColor: AppTheme.cardColor,
      child: Column(
        children: [
          // ── Cabeçalho ─────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: AppTheme.primary),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo da empresa
                const CasaDasCampasLogoHorizontal(light: true, iconSize: 26),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: Colors.white24, height: 1),
                ),

                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.gold.withOpacity(0.25),
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 22,
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(user?.email ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.gold.withOpacity(0.4)),
                  ),
                  child: Text(
                    AppTheme.roleLabel(user?.role ?? ''),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Navegação ─────────────────────────────────────────────────────
          _DrawerItem(
            icon: Icons.home_outlined,
            label: 'Início',
            route: '/dashboard',
            currentLocation: location,
          ),

          _DrawerSection('OPERACIONAL'),
          _DrawerItem(
            icon: Icons.inventory_2_outlined,
            label: 'Encomendas',
            route: '/orders',
            currentLocation: location,
          ),
          _DrawerItem(
            icon: Icons.people_outline,
            label: 'Clientes',
            route: '/customers',
            currentLocation: location,
          ),

          _DrawerSection('CATÁLOGO'),
          _DrawerItem(
            icon: Icons.category_outlined,
            label: 'Produtos',
            route: '/products',
            currentLocation: location,
          ),

          if (user?.isAdmin == true) ...[
            _DrawerSection('ADMINISTRAÇÃO'),
            _DrawerItem(
              icon: Icons.manage_accounts_outlined,
              label: 'Utilizadores',
              route: '/users',
              currentLocation: location,
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Configurações',
              route: '/settings',
              currentLocation: location,
            ),
          ],

          const Spacer(),
          const Divider(indent: 16, endIndent: 16),

          // ── Logout ────────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Sair',
                style: TextStyle(color: AppTheme.error)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String label;
  const _DrawerSection(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Row(children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppTheme.gold,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Divider(
            color: AppTheme.border,
            height: 1,
            thickness: 1,
          ),
        ),
      ]),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentLocation;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentLocation == route ||
        (route != '/dashboard' && currentLocation.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon,
            color: isActive ? AppTheme.gold : AppTheme.textMuted,
            size: 22),
        title: Text(label,
            style: TextStyle(
              color: isActive ? AppTheme.primary : AppTheme.textMuted,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.normal,
            )),
        selected: isActive,
        selectedTileColor: AppTheme.gold.withOpacity(0.1),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
      ),
    );
  }
}
