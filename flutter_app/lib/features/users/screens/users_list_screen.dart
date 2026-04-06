import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/users_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_drawer.dart';

const _roles = ['ADMIN', 'MANAGER', 'OPERATOR', 'VIEWER'];
const _roleLabels = ['Admin', 'Gestor', 'Operador', 'Visualizador'];

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state   = ref.watch(usersProvider);
    final authUser = ref.watch(authProvider).user;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Utilizadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(usersProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(state.error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(usersProvider.notifier).load(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : state.users.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 56, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Nenhum utilizador encontrado',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: state.users.length,
                      itemBuilder: (_, i) {
                        final u = state.users[i];
                        final isSelf = u.id == authUser?.id;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: _roleColor(u.role)
                                  .withOpacity(0.1),
                              child: Text(
                                u.name[0].toUpperCase(),
                                style: TextStyle(
                                    color: _roleColor(u.role),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Row(children: [
                              Expanded(
                                child: Text(
                                  u.name + (isSelf ? ' (eu)' : ''),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (!u.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.red.shade200),
                                  ),
                                  child: const Text('Inativo',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.red)),
                                ),
                            ]),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(u.email,
                                    style:
                                        const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _roleColor(u.role)
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(u.roleLabel,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _roleColor(u.role),
                                          fontWeight:
                                              FontWeight.w500)),
                                ),
                              ],
                            ),
                            trailing: authUser?.isAdmin == true &&
                                    !isSelf
                                ? PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (action) =>
                                        _handleAction(
                                            context, ref, u, action),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'role',
                                        child: Row(children: [
                                          Icon(Icons.manage_accounts,
                                              size: 18),
                                          SizedBox(width: 8),
                                          Text('Alterar função'),
                                        ]),
                                      ),
                                      if (u.isActive)
                                        const PopupMenuItem(
                                          value: 'deactivate',
                                          child: Row(children: [
                                            Icon(Icons.person_off,
                                                size: 18,
                                                color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Desativar',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ]),
                                        ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref,
      UserItem user, String action) async {
    if (action == 'role') {
      String? selected = user.role;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Função de ${user.name}'),
          content: StatefulBuilder(
            builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_roles.length, (i) => RadioListTile(
                title: Text(_roleLabels[i]),
                value: _roles[i],
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
              )),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (selected != null && selected != user.role) {
                  try {
                    await ref
                        .read(usersProvider.notifier)
                        .changeRole(user.id, selected!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Função atualizada!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    } else if (action == 'deactivate') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Desativar utilizador'),
          content: Text(
              'Tem a certeza que quer desativar "${user.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Desativar'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        try {
          await ref.read(usersProvider.notifier).deactivate(user.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Utilizador desativado')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':    return const Color(0xFF7C3AED);
      case 'MANAGER':  return const Color(0xFF1E40AF);
      case 'OPERATOR': return const Color(0xFF059669);
      default:         return Colors.grey;
    }
  }
}
