import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../../../core/theme/app_theme.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  /// Devolve os bytes da primeira foto disponível (falecidos → fotosPessoa → fotoPessoa).
  /// Retorna null se não houver foto.
  Uint8List? _firstPhotoBytes() {
    String? raw;
    if (order.falecidos.isNotEmpty && order.falecidos[0].fotos.isNotEmpty) {
      raw = order.falecidos[0].fotos[0];
    } else if (order.fotosPessoa.isNotEmpty) {
      raw = order.fotosPessoa[0];
    } else if (order.fotoPessoa?.isNotEmpty == true) {
      raw = order.fotoPessoa;
    }
    if (raw == null) return null;
    try {
      final b64 = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat     = DateFormat('dd/MM/yyyy', 'pt');
    final currencyFormat = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final photoBytes     = _firstPhotoBytes();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Conteúdo principal ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Número + Estado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Encomenda ${order.orderNumber}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Nome do falecido
                    if (order.nomeFalecido?.isNotEmpty ?? false)
                      Row(children: [
                        const Icon(Icons.person,
                            size: 15, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.nomeFalecido ?? '',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),

                    // Cemitério
                    if (order.cemiterio != null &&
                        order.cemiterio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.place_outlined,
                            size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.cemiterio!,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],

                    // Requerente
                    if (order.requerente.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Req: ${order.requerente}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 8),

                    // Data + Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(order.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ]),
                        Text(
                          currencyFormat.format(order.valorTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Thumbnail do falecido (só quando existe foto) ───────────────
              if (photoBytes != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    photoBytes,
                    width:  56,
                    height: 72,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
