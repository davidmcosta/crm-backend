import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/users_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

const _roles      = ['ADMIN', 'MANAGER', 'OPERATOR', 'VIEWER'];
const _roleLabels = ['Admin', 'Gestor', 'Operador', 'Visualizador'];
const _roleDescriptions = [
  'Acesso total — gere utilizadores, configurações e todas as encomendas',
  'Gere encomendas e clientes, sem acesso a utilizadores',
  'Cria e edita encomendas e clientes',
  'Só consulta — não pode criar nem editar'
];

// ── Helper de extração de erro ─────────────────────────────────────────────────
String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is List) return (msg as List).join('\n');
      if (msg != null)  return msg.toString();
    }
  }
  return e.toString().replaceAll('Exception: ', '');
}

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(usersProvider);
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
      floatingActionButton: authUser?.isAdmin == true
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _showCreateUserDialog(context, ref),
              icon: const Icon(Icons.person_add),
              label: const Text('Novo utilizador'),
            )
          : null,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.error),
                      const SizedBox(height: 12),
                      Text(state.error!,
                          style:
                              const TextStyle(color: AppTheme.textMuted)),
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
                              size: 56, color: AppTheme.textMuted),
                          SizedBox(height: 12),
                          Text('Nenhum utilizador encontrado',
                              style:
                                  TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: state.users.length,
                      itemBuilder: (_, i) {
                        final u      = state.users[i];
                        final isSelf = u.id == authUser?.id;
                        final roleColor = _roleColor(u.role);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor:
                                  roleColor.withOpacity(0.12),
                              child: Text(
                                u.name[0].toUpperCase(),
                                style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Row(children: [
                              Expanded(
                                child: Text(
                                  u.name + (isSelf ? ' (eu)' : ''),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary),
                                ),
                              ),
                              if (!u.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppTheme.error
                                            .withOpacity(0.3)),
                                  ),
                                  child: Text('Inativo',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.error)),
                                ),
                            ]),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(u.email,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textMuted)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(u.roleLabel,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: roleColor,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                            trailing: authUser?.isAdmin == true && !isSelf
                                ? PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert,
                                        color: AppTheme.textMuted),
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
                                        PopupMenuItem(
                                          value: 'deactivate',
                                          child: Row(children: [
                                            Icon(Icons.delete_outline,
                                                size: 18,
                                                color: AppTheme.error),
                                            const SizedBox(width: 8),
                                            Text('Eliminar',
                                                style: TextStyle(
                                                    color: AppTheme.error)),
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

  // ── Criar utilizador ──────────────────────────────────────────────────────────
  Future<void> _showCreateUserDialog(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl     = TextEditingController();
    final emailCtrl    = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'OPERATOR';
    bool isLoading      = false;
    String? errorMsg;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Novo Utilizador',
              style: TextStyle(color: AppTheme.primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.error.withOpacity(0.3)),
                    ),
                    child: Text(errorMsg!,
                        style: TextStyle(
                            color: AppTheme.error, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Username (opcional)',
                    hintText: 'Ex: joao.silva',
                    prefixIcon: Icon(Icons.alternate_email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Função',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted)),
                ),
                const SizedBox(height: 6),
                ...List.generate(_roles.length, (i) => RadioListTile(
                  title: Text(_roleLabels[i]),
                  subtitle: Text(_roleDescriptions[i],
                      style: const TextStyle(fontSize: 12)),
                  value: _roles[i],
                  groupValue: selectedRole,
                  dense: true,
                  activeColor: AppTheme.gold,
                  onChanged: (v) =>
                      setState(() => selectedRole = v ?? 'OPERATOR'),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 42),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final name  = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final pass  = passwordCtrl.text;
                      if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                        setState(() =>
                            errorMsg = 'Nome, email e password são obrigatórios');
                        return;
                      }
                      setState(() {
                        isLoading = true;
                        errorMsg  = null;
                      });
                      try {
                        final payload = <String, dynamic>{
                          'name':     name,
                          'email':    email,
                          'password': pass,
                          'role':     selectedRole,
                        };
                        final username = usernameCtrl.text.trim();
                        if (username.isNotEmpty) payload['username'] = username;
                        await ApiClient().dio.post(
                          ApiEndpoints.users,
                          data: jsonEncode(payload),
                          options: Options(headers: {
                            'Content-Type': 'application/json'
                          }),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        ref.read(usersProvider.notifier).load();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Utilizador criado!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          errorMsg  = _extractError(e);
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary))
                  : const Text('Criar'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
  }

  // ── Ações sobre utilizador existente ──────────────────────────────────────────
  Future<void> _handleAction(BuildContext context, WidgetRef ref,
      UserItem user, String action) async {
    if (action == 'role') {
      String? selected = user.role;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Função de ${user.name}',
              style: const TextStyle(color: AppTheme.primary)),
          content: StatefulBuilder(
            builder: (ctx, setModal) => Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _roles.length,
                (i) => RadioListTile(
                  title: Text(_roleLabels[i]),
                  subtitle: Text(_roleDescriptions[i],
                      style: const TextStyle(fontSize: 12)),
                  value: _roles[i],
                  groupValue: selected,
                  activeColor: AppTheme.gold,
                  onChanged: (v) => setModal(() => selected = v),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 42)),
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
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_extractError(e)),
                          backgroundColor: AppTheme.error,
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
          title: const Text('Eliminar utilizador',
              style: TextStyle(color: AppTheme.primary)),
          content:
              Text('Tem a certeza que quer eliminar "${user.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(100, 42)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        try {
          await ref.read(usersProvider.notifier).deactivate(user.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Utilizador eliminado')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(_extractError(e)),
                  backgroundColor: AppTheme.error),
            );
          }
        }
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':    return const Color(0xFF8A5C2A);
      case 'MANAGER':  return AppTheme.primary;
      case 'OPERATOR': return AppTheme.gold;
      default:         return AppTheme.textMuted;
    }
  }
}
