import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../providers/customers_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/theme/app_theme.dart';

String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is List) return (msg as List).join('\n');
      if (msg != null) return msg.toString();
    }
  }
  return e.toString().replaceAll('Exception: ', '');
}

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() =>
      _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCustomerAction(BuildContext context, WidgetRef ref,
      dynamic customer, String action) async {
    if (action == 'edit') {
      context.push('/customers/${customer.id}/edit', extra: customer);
    } else if (action == 'delete') {
      final orderCount = customer.orderCount ?? 0;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar cliente',
              style: TextStyle(color: AppTheme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tem a certeza que quer eliminar "${customer.name}"?'),
              if (orderCount > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppTheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Este cliente tem $orderCount encomenda${orderCount != 1 ? 's' : ''}. '
                        'As encomendas ficam no sistema mas sem cliente associado.',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.error),
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ),
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
          await ref.read(customersProvider.notifier).delete(customer.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cliente eliminado'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final auth = ref.watch(authProvider);
    final canCreate = auth.user?.isOperator ?? false;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(customersProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/customers/new'),
              icon: const Icon(Icons.person_add),
              label: const Text('Novo Cliente'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome, email ou NIF...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(customersProvider.notifier)
                              .load(search: null);
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) =>
                  ref.read(customersProvider.notifier).load(search: v),
            ),
          ),
          if (!state.isLoading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('${state.total} cliente${state.total != 1 ? 's' : ''}',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text(state.error!))
                    : state.customers.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 56, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('Nenhum cliente encontrado',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(customersProvider.notifier)
                                .refresh(),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: state.customers.length,
                              itemBuilder: (_, i) {
                                final c = state.customers[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  child: ListTile(
                                    onTap: canCreate
                                        ? () => context.push(
                                            '/customers/${c.id}/edit',
                                            extra: c)
                                        : null,
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppTheme.gold.withOpacity(0.15),
                                      child: Text(
                                        c.name[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: AppTheme.gold,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(c.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (c.email != null)
                                          Text(c.email!,
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        if (c.phone != null)
                                          Text(c.phone!,
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                      ],
                                    ),
                                    trailing: canCreate
                                        ? PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert,
                                                color: AppTheme.textMuted),
                                            onSelected: (action) =>
                                                _handleCustomerAction(
                                                    context, ref, c, action),
                                            itemBuilder: (_) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(children: [
                                                  Icon(Icons.edit_outlined,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Editar'),
                                                ]),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(children: [
                                                  Icon(Icons.delete_outline,
                                                      size: 18,
                                                      color: AppTheme.error),
                                                  const SizedBox(width: 8),
                                                  Text('Eliminar',
                                                      style: TextStyle(
                                                          color:
                                                              AppTheme.error)),
                                                ]),
                                              ),
                                            ],
                                          )
                                        : c.orderCount != null
                                            ? Chip(
                                                label: Text(
                                                    '${c.orderCount} enc.',
                                                    style: const TextStyle(
                                                        fontSize: 11)),
                                                padding: EdgeInsets.zero,
                                              )
                                            : const Icon(Icons.chevron_right),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
