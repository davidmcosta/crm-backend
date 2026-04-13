import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/customers_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../orders/widgets/status_badge.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ordersAsync   = ref.watch(customerOrdersProvider(customerId));
    final currency      = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final dateFmt       = DateFormat('dd/MM/yyyy', 'pt');

    return Scaffold(
      appBar: AppBar(
        title: customerAsync.whenData((c) => Text(c.name)).value ??
            const Text('Conta Cliente'),
        actions: [
          customerAsync.whenData((c) => IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar cliente',
            onPressed: () =>
                context.push('/customers/${c.id}/edit', extra: c),
          )).value ?? const SizedBox.shrink(),
        ],
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erro: $e')),
        data: (customer) {
          return ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('Erro: $e')),
            data: (orders) {
              // ── Cálculos financeiros ──────────────────────────────────
              final active = orders.where((o) => o['status'] != 'CANCELLED').toList();
              final paid   = orders.where((o) => o['status'] == 'PAID').toList();
              final debt   = orders.where((o) =>
                  o['status'] != 'PAID' && o['status'] != 'CANCELLED').toList();

              double _val(dynamic v) =>
                  v == null ? 0.0 : double.parse(v.toString());

              final totalFaturado = active.fold(0.0, (s, o) => s + _val(o['valorTotal']));
              final totalPago     = paid.fold(0.0,   (s, o) => s + _val(o['valorTotal']));
              final totalDivida   = debt.fold(0.0,   (s, o) => s + _val(o['valorTotal']));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // ── Cabeçalho do cliente ──────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.gold.withOpacity(0.15),
                            child: Text(
                              customer.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.gold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                if (customer.taxId != null && customer.taxId!.isNotEmpty)
                                  _info(Icons.numbers, 'NIF: ${customer.taxId}'),
                                if (customer.phone != null && customer.phone!.isNotEmpty)
                                  _info(Icons.phone_outlined, customer.phone!),
                                if (customer.email != null && customer.email!.isNotEmpty)
                                  _info(Icons.email_outlined, customer.email!),
                                if (customer.address != null && customer.address!.isNotEmpty)
                                  _info(Icons.location_on_outlined, customer.address!),
                                if (customer.isReseller) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.gold.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppTheme.gold.withOpacity(0.35)),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.discount_outlined,
                                          size: 14, color: AppTheme.gold),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Revendedor — ${customer.discount % 1 == 0 ? customer.discount.toInt() : customer.discount.toStringAsFixed(1)}% de desconto nas encomendas',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.gold,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ]),
                                  ),
                                ],
                                if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldFaint,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.notes_outlined,
                                            size: 14, color: AppTheme.textMuted),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(customer.notes!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textMuted,
                                                  fontStyle: FontStyle.italic)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Resumo financeiro ─────────────────────────────────
                  Row(children: [
                    Expanded(child: _metricCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'Encomendas',
                      value: '${active.length}',
                      color: AppTheme.primary,
                      isCount: true,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _metricCard(
                      icon: Icons.euro_outlined,
                      label: 'Faturado',
                      value: currency.format(totalFaturado),
                      color: AppTheme.primary,
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _metricCard(
                      icon: Icons.check_circle_outline,
                      label: 'Pago',
                      value: currency.format(totalPago),
                      color: const Color(0xFF1565C0),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _metricCard(
                      icon: Icons.pending_outlined,
                      label: 'Em dívida',
                      value: currency.format(totalDivida),
                      color: totalDivida > 0 ? AppTheme.error : AppTheme.success,
                    )),
                  ]),
                  const SizedBox(height: 16),

                  // ── Lista de encomendas ───────────────────────────────
                  Row(children: [
                    const Icon(Icons.list_alt_outlined,
                        size: 16, color: AppTheme.gold),
                    const SizedBox(width: 6),
                    const Text('Histórico de encomendas',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary)),
                    const SizedBox(width: 8),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 8),

                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Sem encomendas',
                            style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    )
                  else
                    ...orders.map((o) {
                      final status    = o['status'] as String;
                      final number    = o['orderNumber'] as String;
                      final total     = _val(o['valorTotal']);
                      final createdAt = DateTime.tryParse(
                              o['createdAt'] as String? ?? '') ??
                          DateTime.now();
                      final nomeFalecido = o['nomeFalecido'] as String?;
                      final cemiterio    = o['cemiterio']    as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => context.push('/orders/${o['id']}'),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                AppTheme.statusColor(status).withOpacity(0.12),
                            child: Icon(
                              _statusIcon(status),
                              size: 18,
                              color: AppTheme.statusColor(status),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(number,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(width: 8),
                              StatusBadge(status: status),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateFmt.format(createdAt),
                                  style: const TextStyle(fontSize: 11,
                                      color: AppTheme.textMuted)),
                              if (nomeFalecido != null &&
                                  nomeFalecido.isNotEmpty)
                                Text(nomeFalecido,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              if (cemiterio != null && cemiterio.isNotEmpty)
                                Text(cemiterio,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(currency.format(total),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: status == 'PAID'
                                          ? const Color(0xFF1565C0)
                                          : status == 'CANCELLED'
                                              ? AppTheme.textMuted
                                              : AppTheme.primary)),
                              const Icon(Icons.chevron_right,
                                  size: 16, color: AppTheme.textMuted),
                            ],
                          ),
                          isThreeLine: (nomeFalecido != null &&
                                  nomeFalecido.isNotEmpty) ||
                              (cemiterio != null && cemiterio.isNotEmpty),
                        ),
                      );
                    }),

                  const SizedBox(height: 32),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.textMuted),
            const SizedBox(width: 5),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCount = false,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: color.withOpacity(0.8),
                          fontWeight: FontWeight.w500)),
                  Text(value,
                      style: TextStyle(
                          fontSize: isCount ? 20 : 14,
                          fontWeight: FontWeight.bold,
                          color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING':       return Icons.hourglass_empty;
      case 'CONFIRMED':     return Icons.thumb_up_outlined;
      case 'IN_PRODUCTION': return Icons.build_outlined;
      case 'READY':         return Icons.check_circle_outline;
      case 'DELIVERED':     return Icons.local_shipping_outlined;
      case 'PAID':          return Icons.euro_outlined;
      case 'CANCELLED':     return Icons.cancel_outlined;
      default:              return Icons.circle_outlined;
    }
  }
}
