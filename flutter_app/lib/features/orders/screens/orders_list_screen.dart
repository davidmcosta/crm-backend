import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_filter_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_drawer.dart';

const _statuses = [
  null,
  'PENDING',
  'CONFIRMED',
  'IN_PRODUCTION',
  'READY',
  'DELIVERED',
  'PAID',
  'CANCELLED',
];

const _statusLabels = [
  'Todos',
  'Pendentes',
  'Confirmadas',
  'Em Processo',
  'Concluídas',
  'Entregues',
  'Pagas',
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
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(ordersProvider).filter.status;
      if (status != null) {
        final idx = _statuses.indexOf(status);
        if (idx >= 0) {
          setState(() => _selectedStatusIndex = idx);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter({OrdersFilter? advanced}) {
    final current = ref.read(ordersProvider).filter;
    final base = advanced ?? current;
    ref.read(ordersProvider.notifier).setFilter(
          base.copyWith(
            status: _statuses[_selectedStatusIndex],
            search: _searchCtrl.text.trim().isEmpty
                ? null
                : _searchCtrl.text.trim(),
            clearStatus: _statuses[_selectedStatusIndex] == null,
            clearSearch: _searchCtrl.text.trim().isEmpty,
            page: 1,
          ),
        );
  }

  Future<void> _openFilterSheet() async {
    final current = ref.read(ordersProvider).filter;
    final result = await showModalBottomSheet<OrdersFilter>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OrdersFilterSheet(current: current),
    );
    if (result != null) {
      // Manter o status chip e a pesquisa de texto atuais
      final merged = result.copyWith(
        status: _statuses[_selectedStatusIndex],
        search: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
        clearStatus: _statuses[_selectedStatusIndex] == null,
        clearSearch: _searchCtrl.text.trim().isEmpty,
        page: 1,
      );
      ref.read(ordersProvider.notifier).setFilter(merged);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);
    final auth  = ref.watch(authProvider);
    final canCreate = auth.user?.isOperator ?? false;
    final filter = state.filter;
    final advancedCount = filter.activeAdvancedCount;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Encomendas'),
        actions: [
          // Botão de filtros avançados com badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Filtros avançados',
                onPressed: _openFilterSheet,
              ),
              if (advancedCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$advancedCount',
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.onError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/orders/new').then((_) {
                if (mounted) ref.read(ordersProvider.notifier).refresh();
              }),
              icon: const Icon(Icons.add),
              label: const Text('Nova Encomenda'),
            )
          : null,
      body: Column(
        children: [
          // ── Barra de pesquisa ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

          // ── Chips de estado ─────────────────────────────────────────────
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
          const SizedBox(height: 4),

          // ── Chips de filtros avançados ativos ───────────────────────────
          if (advancedCount > 0)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (filter.dateFrom != null || filter.dateTo != null)
                    _ActiveChip(
                      label: filter.dateFrom != null && filter.dateTo != null
                          ? '${_fmtDate(filter.dateFrom!)} – ${_fmtDate(filter.dateTo!)}'
                          : filter.dateFrom != null
                              ? 'Desde ${_fmtDate(filter.dateFrom!)}'
                              : 'Até ${_fmtDate(filter.dateTo!)}',
                      icon: Icons.calendar_today,
                      onRemove: () {
                        ref.read(ordersProvider.notifier).setFilter(
                              filter.copyWith(
                                  clearDateFrom: true, clearDateTo: true, page: 1),
                            );
                      },
                    ),
                  if (filter.cemiterio != null && filter.cemiterio!.isNotEmpty)
                    _ActiveChip(
                      label: filter.cemiterio!,
                      icon: Icons.location_on,
                      onRemove: () {
                        ref.read(ordersProvider.notifier).setFilter(
                              filter.copyWith(clearCemiterio: true, page: 1),
                            );
                      },
                    ),
                  if (filter.trabalho != null && filter.trabalho!.isNotEmpty)
                    _ActiveChip(
                      label: filter.trabalho!,
                      icon: Icons.build,
                      onRemove: () {
                        ref.read(ordersProvider.notifier).setFilter(
                              filter.copyWith(clearTrabalho: true, page: 1),
                            );
                      },
                    ),
                  if (filter.produto != null && filter.produto!.isNotEmpty)
                    _ActiveChip(
                      label: filter.produto!,
                      icon: Icons.category,
                      onRemove: () {
                        ref.read(ordersProvider.notifier).setFilter(
                              filter.copyWith(clearProduto: true, page: 1),
                            );
                      },
                    ),
                  if (filter.customerId != null)
                    _ActiveChip(
                      label: filter.customerName ?? 'Cliente',
                      icon: Icons.person,
                      onRemove: () {
                        ref.read(ordersProvider.notifier).setFilter(
                              filter.copyWith(clearCustomer: true, page: 1),
                            );
                      },
                    ),
                ],
              ),
            ),

          // ── Contador de resultados ──────────────────────────────────────
          if (!state.isLoading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${state.total} encomenda${state.total != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (advancedCount > 0) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final cleared = const OrdersFilter().copyWith(
                          status: _statuses[_selectedStatusIndex],
                          search: _searchCtrl.text.trim().isEmpty
                              ? null
                              : _searchCtrl.text.trim(),
                          clearStatus:
                              _statuses[_selectedStatusIndex] == null,
                          clearSearch:
                              _searchCtrl.text.trim().isEmpty,
                        );
                        ref
                            .read(ordersProvider.notifier)
                            .setFilter(cleared);
                      },
                      child: Text(
                        'Limpar filtros',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // ── Lista de encomendas ─────────────────────────────────────────
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
                              onPressed: () => ref
                                  .read(ordersProvider.notifier)
                                  .refresh(),
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
                              padding:
                                  const EdgeInsets.only(bottom: 80),
                              itemCount: state.orders.length,
                              itemBuilder: (_, i) =>
                                  OrderCard(
                                    order: state.orders[i],
                                    onReturn: () => ref.read(ordersProvider.notifier).refresh(),
                                  ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Chip de filtro ativo ──────────────────────────────────────────────────────

class _ActiveChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _ActiveChip({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    final onColor = Theme.of(context).colorScheme.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        avatar: Icon(icon, size: 14, color: onColor),
        label: Text(label,
            style: TextStyle(fontSize: 12, color: onColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        deleteIcon: Icon(Icons.close, size: 14, color: onColor),
        onDeleted: onRemove,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
