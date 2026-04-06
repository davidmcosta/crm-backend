import 'dart:convert';
import 'dart:typed_data';
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
  final _dateFormat  = DateFormat('dd/MM/yyyy HH:mm', 'pt');
  final _dateShort   = DateFormat('dd/MM/yyyy', 'pt');
  final _currency    = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

  final _allStatuses = [
    'PENDING', 'CONFIRMED', 'IN_PRODUCTION', 'READY', 'DELIVERED'
  ];

  // ── Alterar estado ───────────────────────────────────────────────────────────
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alterar Estado',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: available.map((s) {
                  final isSelected = selected == s;
                  return ChoiceChip(
                    label: Text(AppTheme.statusLabel(s)),
                    selected: isSelected,
                    selectedColor:
                        AppTheme.statusColor(s).withOpacity(0.2),
                    onSelected: (_) =>
                        setModal(() => selected = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    hintText: 'Ex: Trabalho concluído'),
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

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final auth       = ref.watch(authProvider);
    final canEdit    = auth.user?.isOperator ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Encomenda')),
      body: orderAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (order) => ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Cabeçalho ──────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Encomenda ${order.orderNumber}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        StatusBadge(status: order.status, large: true),
                      ],
                    ),
                    const Divider(height: 24),
                    _row(Icons.calendar_today_outlined, 'Criada em',
                        _dateFormat.format(order.createdAt)),
                    if (order.createdBy != null) ...[
                      const SizedBox(height: 8),
                      _row(Icons.person, 'Criada por',
                          order.createdBy!.name),
                    ],
                    if (order.customer != null) ...[
                      const SizedBox(height: 8),
                      _row(Icons.business_outlined, 'Cliente',
                          order.customer!.name),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Foto + Falecido ─────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(Icons.person, 'Falecido(a)'),
                    const SizedBox(height: 12),

                    // Foto (se existir)
                    if (order.fotoPessoa != null &&
                        order.fotoPessoa!.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _decodePhoto(order.fotoPessoa!),
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (order.fotoPessoa != null &&
                        order.fotoPessoa!.isNotEmpty)
                      const SizedBox(height: 12),

                    _row(Icons.badge_outlined, 'Nome',
                        order.nomeFalecido),
                    if (order.datasFalecido != null &&
                        order.datasFalecido!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _row(Icons.date_range_outlined, 'Datas',
                          order.datasFalecido!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Trabalho ────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(Icons.construction, 'Trabalho'),
                    const SizedBox(height: 12),
                    Text(order.trabalho),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Cemitério ───────────────────────────────────────────────────
            if (order.cemiterio != null ||
                order.talhao != null ||
                order.numeroSepultura != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle(
                          Icons.location_on_outlined, 'Cemitério'),
                      const SizedBox(height: 12),
                      if (order.cemiterio != null)
                        _row(Icons.place_outlined, 'Cemitério',
                            order.cemiterio!),
                      if (order.talhao != null) ...[
                        const SizedBox(height: 8),
                        _row(Icons.grid_on_outlined, 'Talhão',
                            order.talhao!),
                      ],
                      if (order.numeroSepultura != null) ...[
                        const SizedBox(height: 8),
                        _row(Icons.tag, 'Nº Sepultura',
                            order.numeroSepultura!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Valores ─────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(Icons.euro, 'Valores'),
                    const SizedBox(height: 12),
                    _row(Icons.euro_outlined, 'Sepultura',
                        _currency.format(order.valorSepultura)),
                    const SizedBox(height: 8),
                    if (order.km != null) ...[
                      _row(Icons.route_outlined, 'Km',
                          '${order.km!.toStringAsFixed(1)} km'),
                      const SizedBox(height: 8),
                    ],
                    if (order.portagens > 0) ...[
                      _row(Icons.toll_outlined, 'Portagens',
                          _currency.format(order.portagens)),
                      const SizedBox(height: 8),
                    ],
                    _row(Icons.drive_eta_outlined,
                        'Deslocação / Montagem',
                        _currency.format(order.deslocacaoMontagem)),
                    if (order.extrasValor > 0) ...[
                      const SizedBox(height: 8),
                      _row(
                        Icons.add_circle_outline,
                        order.extrasDescricao != null &&
                                order.extrasDescricao!.isNotEmpty
                            ? 'Extras (${order.extrasDescricao})'
                            : 'Extras',
                        _currency.format(order.extrasValor),
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(
                          _currency.format(order.valorTotal),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Requerente ──────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(
                        Icons.person_outline, 'Requerente'),
                    const SizedBox(height: 12),
                    _row(Icons.person_outlined, 'Nome',
                        order.requerente),
                    const SizedBox(height: 8),
                    _row(Icons.phone_outlined, 'Contacto',
                        order.contacto),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Observações ─────────────────────────────────────────────────
            if (order.observacoes != null &&
                order.observacoes!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle(
                          Icons.notes_outlined, 'Observações'),
                      const SizedBox(height: 8),
                      Text(order.observacoes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Histórico ───────────────────────────────────────────────────
            if (order.statusHistory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle(
                          Icons.history, 'Histórico de Estados'),
                      const SizedBox(height: 12),
                      ...order.statusHistory.map((h) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 10, height: 10,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusColor(
                                        h.status),
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
                                          AppTheme.statusLabel(
                                              h.status),
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w500)),
                                      Text(
                                          '${h.changedByName} · ${_dateFormat.format(h.createdAt)}',
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

            // ── Botão alterar estado ────────────────────────────────────────
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

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Uint8List _decodePhoto(String dataUrl) {
    final base64 =
        dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
    return base64Decode(base64);
  }

  Widget _cardTitle(IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E40AF)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _row(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 14)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 14))),
        ],
      );
}
