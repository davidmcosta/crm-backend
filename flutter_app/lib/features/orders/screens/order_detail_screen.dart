import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/orders_provider.dart';
import '../widgets/status_badge.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt');
  final dateShort = DateFormat('dd/MM/yyyy', 'pt');
  final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

  final _allStatuses = [
    'PENDING', 'CONFIRMED', 'IN_PRODUCTION', 'READY', 'SHIPPED', 'DELIVERED'
  ];

  Future<void> _changeStatus(String currentStatus) async {
    final available = _allStatuses
        .where((s) => s != currentStatus && s != 'CANCELLED')
        .toList();

    String? selected;
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alterar Estado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: available.map((s) {
                  final isSelected = selected == s;
                  return ChoiceChip(
                    label: Text(AppTheme.statusLabel(s)),
                    selected: isSelected,
                    selectedColor:
                        AppTheme.statusColor(s).withOpacity(0.2),
                    onSelected: (_) =>
                        setModalState(() => selected = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Ex: Confirmado por telefone',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        try {
                          await updateOrderStatus(
                              widget.orderId, selected!, notesCtrl.text);
                          ref.invalidate(
                              orderDetailProvider(widget.orderId));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Estado atualizado!'),
                                  backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final auth = ref.watch(authProvider);
    final canEdit = auth.user?.isOperator ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Encomenda')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (order) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cabeçalho
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.orderNumber,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        StatusBadge(status: order.status, large: true),
                      ],
                    ),
                    const Divider(height: 24),
                    _infoRow(Icons.person_outline, 'Cliente',
                        order.customer?.name ?? '—'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.calendar_today_outlined, 'Criada em',
                        dateFormat.format(order.createdAt)),
                    if (order.expectedDate != null) ...[
                      const SizedBox(height: 8),
                      _infoRow(Icons.access_time, 'Data prevista',
                          dateShort.format(order.expectedDate!)),
                    ],
                    const SizedBox(height: 8),
                    _infoRow(Icons.person, 'Criada por',
                        order.createdBy?.name ?? '—'),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow(Icons.notes, 'Notas', order.notes!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Itens
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Itens',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    if (item.description != null)
                                      Text(item.description!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    Text(
                                        '${item.quantity} × ${currency.format(item.unitPrice)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text(currency.format(item.totalPrice),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(currency.format(order.totalAmount),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Histórico de estados
            if (order.statusHistory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Histórico',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...order.statusHistory.map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.statusColor(h.status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          AppTheme.statusLabel(h.status),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                          '${h.changedByName} · ${dateFormat.format(h.createdAt)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      if (h.notes != null)
                                        Text(h.notes!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle:
                                                    FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),

            // Botão de alterar estado
            if (canEdit &&
                order.status != 'DELIVERED' &&
                order.status != 'CANCELLED') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _changeStatus(order.status),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Alterar Estado'),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 14))),
        ],
      );
}
