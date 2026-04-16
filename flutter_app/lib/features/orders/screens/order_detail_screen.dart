import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';
import '../widgets/status_badge.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

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
    'PENDING', 'CONFIRMED', 'IN_PRODUCTION', 'READY', 'DELIVERED', 'PAID', 'CANCELLED'
  ];

  // ── Alterar estado ────────────────────────────────────────────────────────────
  Future<void> _changeStatus(String currentStatus) async {
    final available = _allStatuses
        .where((s) => s != currentStatus)
        .toList();

    String?          selected;
    final notesCtrl = TextEditingController();
    final fotos      = <Uint8List>[];   // bytes para pré-visualização
    final fotosB64   = <String>[];      // base64 para enviar

    Future<void> pickPhoto(StateSetter setModal) async {
      // On desktop there is no camera — skip the picker
      final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
      ImageSource? source = ImageSource.gallery;
      if (!isDesktop) {
        source = await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Câmara'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Biblioteca de fotos'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
        if (source == null) return;
      }
      try {
        final file = await ImagePicker().pickImage(
          source: source,
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
                            // Refresh the orders list so the new status is
                            // visible immediately when navigating back.
                            ref.read(ordersProvider.notifier).refresh();
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
                                    content: Text(_shortError(e)),
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
            Expanded(
              child: Text('Reverter Pagamento',
                  overflow: TextOverflow.ellipsis),
            ),
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
      ref.read(ordersProvider.notifier).refresh();
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
              content: Text(_shortError(e)),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  // ── Eliminar encomenda ────────────────────────────────────────────────────────
  Future<void> _deleteOrder(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.delete_forever, color: AppTheme.error),
          SizedBox(width: 8),
          Expanded(child: Text('Eliminar Encomenda',
              overflow: TextOverflow.ellipsis)),
        ]),
        content: const Text(
          'Esta ação é irreversível. A encomenda será eliminada permanentemente.\n\nTem a certeza?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiClient().dio.delete(ApiEndpoints.orderById(id));
      if (mounted) {
        ref.read(ordersProvider.notifier).removeOrder(id);
        // Invalidate all cached order details so isLastOrder is recalculated
        // on the next open (the order before this one is now the last)
        ref.invalidate(orderDetailProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Encomenda eliminada'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_shortError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// Returns a short, human-readable Portuguese error message.
  static String _shortError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error']?.toString() ?? '';
        if (msg.isNotEmpty) return msg;
      }
      final code = e.response?.statusCode;
      if (code == 400) return 'Pedido inválido. Verifique os dados.';
      if (code == 403) return 'Sem permissão para esta operação.';
      if (code == 404) return 'Registo não encontrado.';
      return 'Erro de ligação. Verifique a rede e tente novamente.';
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final auth       = ref.watch(authProvider);
    final canEdit    = auth.user?.isOperator ?? false;
    final canDelete  = auth.user?.isManager  ?? false;

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
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 56,
                    color: AppTheme.textMuted.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  friendlyError(e),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                  onPressed: () =>
                      ref.invalidate(orderDetailProvider(widget.orderId)),
                ),
              ],
            ),
          ),
        ),
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
                                              context, f.fotos, 0, order.orderNumber),
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
                                              context, f.fotos, pi, order.orderNumber),
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
                          Expanded(flex: 1, child: Text('Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted))),
                          Expanded(flex: 1, child: Text('Preço',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted))),
                          Expanded(flex: 1, child: Text('Total',
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
                              Expanded(flex: 1,
                                  child: Text(
                                      p.qty % 1 == 0
                                          ? p.qty.toInt().toString()
                                          : p.qty.toStringAsFixed(2),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 1,
                                  child: Text(_currency.format(p.precoUnit),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 1,
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

            // ── Desconto ─────────────────────────────────────────────────────
            if (order.descontoPerc > 0) ...[
              Card(
                color: AppTheme.primary.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.discount_outlined,
                          size: 18, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Desconto (${order.descontoPerc % 1 == 0 ? order.descontoPerc.toInt() : order.descontoPerc.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '−${_currency.format(order.descontoValor)}',
                        style: const TextStyle(
                            color: AppTheme.primary,
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

            // ── Requerente (só para Casa das Campas) ──────────────────────────
            if (order.customer?.name.toLowerCase().contains('casa das campas') == true)
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
                                                onTap: () => _showPhoto(context, b64, order.orderNumber, i),
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
            if (canEdit || canDelete) ...[
              const SizedBox(height: 16),

              // Botão de reverter pagamento (só em PAID)
              if (canEdit && order.status == 'PAID')
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

              if (canEdit && order.status != 'PAID')
                Row(
                  children: [
                    // Botão Editar — oculto para encomendas canceladas
                    if (order.status != 'CANCELLED') ...[
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
                    ],
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

              // Botão de eliminar — só para MANAGER+ e só na encomenda mais recente
              if (canDelete && order.isLastOrder) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error.withOpacity(0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _deleteOrder(order.id),
                    icon: const Icon(Icons.delete_forever_outlined, size: 18),
                    label: const Text('Eliminar encomenda'),
                  ),
                ),
              ],
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

  String _photoMimeExt(String dataUrl) {
    if (dataUrl.startsWith('data:image/png')) return 'png';
    if (dataUrl.startsWith('data:image/gif')) return 'gif';
    if (dataUrl.startsWith('data:image/webp')) return 'webp';
    return 'jpg';
  }

  Future<void> _savePhoto(BuildContext context, String dataUrl, String orderNumber, int index) async {
    try {
      final bytes = _decodePhoto(dataUrl);
      final ext = _photoMimeExt(dataUrl);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final suggestedName = 'encomenda_${orderNumber.replaceAll('/', '-')}_foto${index + 1}_$ts.$ext';

      String? savePath;

      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        // Desktop: show native Save As dialog
        final typeGroup = XTypeGroup(
          label: 'Imagem',
          extensions: [ext],
        );
        final location = await getSaveLocation(
          suggestedName: suggestedName,
          acceptedTypeGroups: [typeGroup],
        );
        if (location == null) return; // user cancelled
        savePath = location.path;
      } else if (!kIsWeb) {
        // Mobile: save to documents directory silently
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$suggestedName';
      }

      if (savePath == null) return;

      final file = File(savePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto guardada em: $savePath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível guardar a foto. ${friendlyError(e)}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showPhotoDialog(
      BuildContext context, List<String> fotos, int initialIndex, String orderNumber) {
    showDialog(
      context: context,
      builder: (_) {
        int current = initialIndex;
        return StatefulBuilder(
          builder: (ctx, setState) {
            final screenSize = MediaQuery.of(ctx).size;
            final maxW = screenSize.width  - 48;
            final maxH = screenSize.height - 120; // leave room for toolbar + nav row
            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH + 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── toolbar ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            fotos.length > 1
                                ? 'Foto ${current + 1} / ${fotos.length}'
                                : 'Foto',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Guardar foto',
                              onPressed: () => _savePhoto(context, fotos[current], orderNumber, current),
                              icon: const Icon(Icons.download, color: Colors.white70),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // ── image (constrained, zoom-able) ───────────────────
                    SizedBox(
                      width:  maxW,
                      height: maxH,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5.0,
                        child: Image.memory(
                          _decodePhoto(fotos[current]),
                          fit: BoxFit.contain,
                          width:  maxW,
                          height: maxH,
                        ),
                      ),
                    ),
                    // ── prev / dots / next ───────────────────────────────
                    if (fotos.length > 1) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: current > 0 ? () => setState(() => current--) : null,
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          ...List.generate(fotos.length, (i) => Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == current ? Colors.white : Colors.white38,
                                ),
                              )),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: current < fotos.length - 1
                                ? () => setState(() => current++)
                                : null,
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
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
      },
    );
  }

  Widget _cardTitle(IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
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

  void _showPhoto(BuildContext context, String b64, String orderNumber, int index) {
    final dataUrl = b64.contains(',') ? b64 : 'data:image/jpeg;base64,$b64';
    showDialog(
      context: context,
      builder: (ctx) {
        final screenSize = MediaQuery.of(ctx).size;
        final maxW = screenSize.width  - 48;
        final maxH = screenSize.height - 120;
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH + 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Guardar foto',
                      onPressed: () => _savePhoto(context, dataUrl, orderNumber, index),
                      icon: const Icon(Icons.download, color: Colors.white70),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(
                  width:  maxW,
                  height: maxH,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.memory(
                      base64Decode(b64),
                      fit: BoxFit.contain,
                      width:  maxW,
                      height: maxH,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
