import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
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
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt');
  final _currency   = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

  final _allStatuses = [
    'PENDING', 'CONFIRMED', 'IN_PRODUCTION', 'READY', 'DELIVERED', 'PAID'
  ];

  // ── Alterar estado ────────────────────────────────────────────────────────────
  Future<void> _changeStatus(String currentStatus) async {
    final available = _allStatuses
        .where((s) => s != currentStatus && s != 'CANCELLED')
        .toList();

    String?          selected;
    final notesCtrl = TextEditingController();
    final fotos      = <Uint8List>[];   // bytes para pré-visualização
    final fotosB64   = <String>[];      // base64 para enviar

    Future<void> pickPhoto(StateSetter setModal) async {
      try {
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200, maxHeight: 1200, imageQuality: 80,
        );
        if (file == null) return;
        final bytes = await file.readAsBytes();
        setModal(() {
          fotos.add(bytes);
          fotosB64.add('data:image/jpeg;base64,${base64Encode(bytes)}');
        });
      } catch (_) {}
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
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

              // ── Chips de estado ──────────────────────────────────────────
              Wrap(
                spacing: 8, runSpacing: 8,
                children: available.map((s) {
                  final isSelected = selected == s;
                  return ChoiceChip(
                    label: Text(AppTheme.statusLabel(s)),
                    selected: isSelected,
                    selectedColor: AppTheme.statusColor(s).withOpacity(0.2),
                    onSelected: (_) => setModal(() => selected = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Nota ──────────────────────────────────────────────────────
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    hintText: 'Ex: Trabalho concluído',
                    prefixIcon: Icon(Icons.notes_outlined)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // ── Fotos ─────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Fotos',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary)),
                  TextButton.icon(
                    onPressed: () => pickPhoto(setModal),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
              if (fotos.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(fotos[i],
                              width: 90, height: 90, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2, right: 2,
                          child: GestureDetector(
                            onTap: () => setModal(() {
                              fotos.removeAt(i);
                              fotosB64.removeAt(i);
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('Nenhuma foto adicionada',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted)),
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            await updateOrderStatus(
                              widget.orderId, selected!,
                              notesCtrl.text.isEmpty ? null : notesCtrl.text,
                              fotos: fotosB64,
                            );
                            ref.invalidate(orderDetailProvider(widget.orderId));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Estado atualizado!'),
                                    backgroundColor: AppTheme.success),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppTheme.error),
                              );
                            }
                          }
                        },
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reverter pagamento ────────────────────────────────────────────────────────
  Future<void> _revertPayment() async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.undo, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reverter Pagamento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A encomenda voltará ao estado "Entregue".\nIndique o motivo (opcional):',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                hintText: 'Ex: Pagamento registado por lapso',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await updateOrderStatus(
        widget.orderId,
        'DELIVERED',
        notesCtrl.text.trim().isEmpty
            ? 'Pagamento revertido'
            : notesCtrl.text.trim(),
      );
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento revertido — encomenda voltou a Entregue'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final auth       = ref.watch(authProvider);
    final canEdit    = auth.user?.isOperator ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da Encomenda'),
        actions: [
          if (canEdit)
            orderAsync.whenData((order) {
              if (order.status == 'CANCELLED' || order.status == 'PAID')
                return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar encomenda',
                onPressed: () =>
                    context.push('/orders/${order.id}/edit', extra: order),
              );
            }).value ?? const SizedBox.shrink(),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (order) => ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Cabeçalho ─────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Encomenda ${order.orderNumber}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
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

            // ── Trabalho ──────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(Icons.construction, 'Trabalho'),
                    const SizedBox(height: 12),
                    Text(order.trabalho,
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Cemitério ─────────────────────────────────────────────────────
            if (order.cemiterio != null ||
                order.talhao != null ||
                order.numeroSepultura != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle(Icons.location_on_outlined, 'Cemitério'),
                      const SizedBox(height: 12),
                      if (order.cemiterio != null)
                        _row(Icons.place_outlined, 'Cemitério', order.cemiterio),
                      if (order.talhao != null) ...[
                        const SizedBox(height: 8),
                        _row(Icons.grid_on_outlined, 'Talhão', order.talhao),
                      ],
                      if (order.numeroSepultura != null) ...[
                        const SizedBox(height: 8),
                        _row(Icons.tag, 'Nº Sepultura', order.numeroSepultura),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Falecido(s) ───────────────────────────────────────────────────
            if (order.falecidos.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle(Icons.people_outlined,
                          order.falecidos.length == 1
                              ? 'Falecido(a)'
                              : 'Falecidos (${order.falecidos.length})'),
                      const SizedBox(height: 12),

                      ...order.falecidos.asMap().entries.map((entry) {
                        final fi = entry.key;
                        final f  = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.falecidos.length > 1) ...[
                              if (fi > 0) const Divider(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Falecido ${fi + 1}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.gold)),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // fotos
                            if (f.fotos.isNotEmpty) ...[
                              SizedBox(
                                height: f.fotos.length == 1 ? 170 : 150,
                                child: f.fotos.length == 1
                                    ? Center(
                                        child: GestureDetector(
                                          onTap: () => _showPhotoDialog(
                                              context, f.fotos, 0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.memory(
                                              _decodePhoto(f.fotos[0]),
                                              height: 170,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: f.fotos.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (_, pi) =>
                                            GestureDetector(
                                          onTap: () => _showPhotoDialog(
                                              context, f.fotos, pi),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.memory(
                                              _decodePhoto(f.fotos[pi]),
                                              width: 120, height: 150,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (f.nome != null && f.nome!.isNotEmpty)
                              _row(Icons.badge_outlined, 'Nome', f.nome),
                            if (f.datas != null && f.datas!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _row(Icons.date_range_outlined, 'Datas',
                                  f.datas),
                            ],
                            if (f.dedicatoria != null &&
                                f.dedicatoria!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldFaint,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(
                                          Icons.format_quote_outlined,
                                          size: 14,
                                          color: AppTheme.gold),
                                      const SizedBox(width: 4),
                                      const Text('Dedicatória',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.gold)),
                                    ]),
                                    const SizedBox(height: 6),
                                    Text(f.dedicatoria!,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Produtos ──────────────────────────────────────────────────────
            if (order.produtos.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle(Icons.inventory_2_outlined, 'Produtos'),
                      const SizedBox(height: 12),
                      // Cabeçalho
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: const [
                          Expanded(flex: 4, child: Text('Descrição',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted))),
                          SizedBox(width: 50, child: Text('Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted))),
                          SizedBox(width: 70, child: Text('Preço',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted))),
                          SizedBox(width: 70, child: Text('Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted))),
                        ]),
                      ),
                      const Divider(height: 4),
                      ...order.produtos.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(children: [
                              Expanded(flex: 4,
                                  child: Text(p.nome,
                                      style: const TextStyle(fontSize: 14))),
                              SizedBox(width: 50,
                                  child: Text(
                                      p.qty % 1 == 0
                                          ? p.qty.toInt().toString()
                                          : p.qty.toStringAsFixed(2),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14))),
                              SizedBox(width: 70,
                                  child: Text(_currency.format(p.precoUnit),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 14))),
                              SizedBox(width: 70,
                                  child: Text(_currency.format(p.total),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500))),
                            ]),
                          )),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Subtotal: ',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(_currency.format(order.valorSepultura),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Deslocação e Montagem ─────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(Icons.drive_eta_outlined,
                        'Deslocação e Montagem'),
                    const SizedBox(height: 12),
                    if (order.km != null) ...[
                      _row(Icons.route_outlined, 'Distância',
                          '${order.km!.toStringAsFixed(1)} km'),
                      const SizedBox(height: 8),
                    ],
                    if (order.portagens > 0) ...[
                      _row(Icons.toll_outlined, 'Portagens',
                          _currency.format(order.portagens)),
                      const SizedBox(height: 8),
                    ],
                    if (order.refeicoes > 0) ...[
                      _row(Icons.restaurant_outlined,
                          'Refeições (2 col.)',
                          _currency.format(order.refeicoes)),
                      const SizedBox(height: 8),
                    ],
                    _row(Icons.euro_outlined, 'Total',
                        _currency.format(order.deslocacaoMontagem)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Extras ────────────────────────────────────────────────────────
            if (order.extras.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle(Icons.add_circle_outline, 'Extras'),
                      const SizedBox(height: 12),
                      ...order.extras.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: Text(e.descricao,
                                        style: const TextStyle(fontSize: 14))),
                                Text(_currency.format(e.valor),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                              ],
                            ),
                          )),
                      if (order.extras.length > 1) ...[
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Subtotal extras: ',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            Text(_currency.format(order.extrasValor),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Desconto de revendedor ────────────────────────────────────────
            if (order.descontoPerc > 0) ...[
              Card(
                color: AppTheme.gold.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.gold.withOpacity(0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.discount_outlined,
                          size: 18, color: AppTheme.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Desconto revendedor (${order.descontoPerc % 1 == 0 ? order.descontoPerc.toInt() : order.descontoPerc.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '−${_currency.format(order.descontoValor)}',
                        style: const TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── IVA ───────────────────────────────────────────────────────────
            if (order.ivaPerc > 0) ...[
              Card(
                color: const Color(0xFF1565C0).withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: const Color(0xFF1565C0).withOpacity(0.35)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 18, color: Color(0xFF1565C0)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'IVA (${order.ivaPerc % 1 == 0 ? order.ivaPerc.toInt() : order.ivaPerc.toStringAsFixed(1)}%) — taxa normal',
                          style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _currency.format(order.ivaValor),
                        style: const TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Base tributável: ${_currency.format(order.valorTotal - order.ivaValor)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1565C0)),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Total geral ───────────────────────────────────────────────────
            Card(
              color: AppTheme.goldFaint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.gold, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(children: [
                  if (order.ivaPerc > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal (sem IVA)',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted)),
                        Text(
                          _currency.format(order.valorTotal - order.ivaValor),
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.ivaPerc > 0 ? 'TOTAL (c/ IVA)' : 'TOTAL',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        _currency.format(order.valorTotal),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // ── Requerente ────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(Icons.person_outline, 'Requerente'),
                    const SizedBox(height: 12),
                    _row(Icons.person_outlined, 'Nome', order.requerente),
                    const SizedBox(height: 8),
                    _row(Icons.phone_outlined, 'Contacto', order.contacto),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Observações ───────────────────────────────────────────────────
            if (order.observacoes != null &&
                order.observacoes!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle(Icons.notes_outlined, 'Observações'),
                      const SizedBox(height: 8),
                      Text(order.observacoes!,
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Histórico ─────────────────────────────────────────────────────
            if (order.statusHistory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardTitle(Icons.history, 'Histórico de Estados'),
                      const SizedBox(height: 12),
                      ...order.statusHistory.map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 10, height: 10,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusColor(h.status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(AppTheme.statusLabel(h.status),
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w500)),
                                      Text(
                                          '${h.changedByName} · ${_dateFormat.format(h.createdAt)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted)),
                                      if (h.notes != null)
                                        Text(h.notes!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle:
                                                    FontStyle.italic)),
                                      if (h.fotos.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 72,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: h.fotos.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 6),
                                            itemBuilder: (_, i) {
                                              final b64 = h.fotos[i].contains(',')
                                                  ? h.fotos[i].split(',').last
                                                  : h.fotos[i];
                                              return GestureDetector(
                                                onTap: () => _showPhoto(context, b64),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Image.memory(
                                                    base64Decode(b64),
                                                    width: 72, height: 72,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
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

            // ── Botões de ação ────────────────────────────────────────────────
            if (canEdit) ...[
              const SizedBox(height: 16),

              // Botão de reverter pagamento (só em PAID)
              if (order.status == 'PAID')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade800),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _revertPayment(),
                      icon: const Icon(Icons.undo),
                      label: const Text('Reverter Pagamento'),
                    ),
                  ),
                ),

              if (order.status != 'PAID' && order.status != 'CANCELLED')
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                              '/orders/${order.id}/edit',
                              extra: order),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _changeStatus(order.status),
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: const Text('Alterar Estado'),
                        ),
                      ),
                    ),
                  ],
                ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Uint8List _decodePhoto(String dataUrl) {
    final b64 = dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
    return base64Decode(b64);
  }

  void _showPhotoDialog(
      BuildContext context, List<String> fotos, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) {
        int current = initialIndex;
        return StatefulBuilder(
          builder: (ctx, setState) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        fotos.length > 1
                            ? 'Foto ${current + 1} / ${fotos.length}'
                            : 'Foto',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                InteractiveViewer(
                  child: Image.memory(
                    _decodePhoto(fotos[current]),
                    fit: BoxFit.contain,
                  ),
                ),
                if (fotos.length > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: current > 0
                            ? () => setState(() => current--)
                            : null,
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(fotos.length, (i) => Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == current
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                          )),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: current < fotos.length - 1
                            ? () => setState(() => current++)
                            : null,
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cardTitle(IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.gold),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _row(IconData icon, String label, String? value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          Expanded(
              child: Text(value ?? '—',
                  style: const TextStyle(fontSize: 14))),
        ],
      );

  void _showPhoto(BuildContext context, String b64) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(base64Decode(b64), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
