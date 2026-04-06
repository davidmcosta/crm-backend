import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customers_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_drawer.dart';

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
                                    onTap: () =>
                                        context.push('/customers/${c.id}'),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF1E40AF)
                                          .withOpacity(0.1),
                                      child: Text(
                                        c.name[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: Color(0xFF1E40AF),
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
                                    trailing: c.orderCount != null
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
