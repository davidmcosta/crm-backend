import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import '../../auth/providers/auth_provider.dart';

const _statuses = [
  null,
  'PENDING',
  'CONFIRMED',
  'IN_PRODUCTION',
  'READY',
  'DELIVERED',
  'CANCELLED',
];

const _statusLabels = [
  'Todos',
  'Pendentes',
  'Confirmadas',
  'Em Execução',
  'Concluídas',
  'Entregues',
  'Canceladas',
];

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final _searchCtrl = TextEditingController();
  int _selectedStatusIndex = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    ref.read(ordersProvider.notifier).setFilter(
          OrdersFilter(
            status: _statuses[_selectedStatusIndex],
            search: _searchCtrl.text.trim().isEmpty
                ? null
                : _searchCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);
    final auth = ref.watch(authProvider);
    final canCreate = auth.user?.isOperator ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encomendas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/orders/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nova Encomenda'),
            )
          : null,
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Pesquisar por número, falecido, requerente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilter();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _applyFilter(),
              onChanged: (v) {
                if (v.isEmpty) _applyFilter();
              },
            ),
          ),

          // Filtro por estado
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusLabels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _selectedStatusIndex == i;
                return FilterChip(
                  label: Text(_statusLabels[i]),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedStatusIndex = i);
                    _applyFilter();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Contador
          if (!state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${state.total} encomenda${state.total != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Lista
          Expanded(
            child: state.isLoading
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
                                  ref.read(ordersProvider.notifier).refresh(),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : state.orders.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 56, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('Nenhuma encomenda encontrada',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(ordersProvider.notifier).refresh(),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: state.orders.length,
                              itemBuilder: (_, i) =>
                                  OrderCard(order: state.orders[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
