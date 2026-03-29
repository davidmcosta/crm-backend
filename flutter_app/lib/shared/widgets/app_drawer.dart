import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final location = GoRouterState.of(context).uri.toString();

    return Drawer(
      child: Column(
        children: [
          // Cabeçalho com dados do utilizador
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E40AF)),
            accountName: Text(user?.name ?? ''),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.bold),
              ),
            ),
            otherAccountsPictures: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppTheme.roleLabel(user?.role ?? ''),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),

          // Itens de navegação
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
          if (user?.isAdmin == true) ...[
            const Divider(),
            _DrawerItem(
              icon: Icons.manage_accounts_outlined,
              label: 'Utilizadores',
              route: '/users',
              currentLocation: location,
            ),
          ],

          const Spacer(),
          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
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
    final isActive = currentLocation.startsWith(route);

    return ListTile(
      leading: Icon(icon,
          color: isActive ? const Color(0xFF1E40AF) : null),
      title: Text(label,
          style: TextStyle(
            color: isActive ? const Color(0xFF1E40AF) : null,
            fontWeight: isActive ? FontWeight.w600 : null,
          )),
      selected: isActive,
      selectedTileColor:
          const Color(0xFF1E40AF).withOpacity(0.08),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
