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
  final VoidCallback? onReturn;

  const OrderCard({super.key, required this.order, this.onReturn});

  /// Recolhe até [max] fotos de todos os falecidos (nova estrutura + legado).
  List<Uint8List> _allPhotoBytes({int max = 4}) {
    final result = <Uint8List>[];

    Uint8List? _decode(String raw) {
      try {
        final b64 = raw.contains(',') ? raw.split(',').last : raw;
        return base64Decode(b64);
      } catch (_) {
        return null;
      }
    }

    // Nova estrutura: falecidos[].fotos[]
    for (final falecido in order.falecidos) {
      for (final foto in falecido.fotos) {
        if (result.length >= max) return result;
        final bytes = _decode(foto);
        if (bytes != null) result.add(bytes);
      }
    }

    // Legado: fotosPessoa (primeiro falecido)
    if (result.isEmpty) {
      for (final foto in order.fotosPessoa) {
        if (result.length >= max) return result;
        final bytes = _decode(foto);
        if (bytes != null) result.add(bytes);
      }
    }

    // Legado: fotoPessoa (campo único)
    if (result.isEmpty && order.fotoPessoa?.isNotEmpty == true) {
      final bytes = _decode(order.fotoPessoa!);
      if (bytes != null) result.add(bytes);
    }

    return result;
  }

  // Dimensões fixas de cada thumbnail
  static const _photoW   = 52.0;
  static const _photoH   = 68.0;
  static const _photoGap =  4.0;

  // Largura estimada da coluna direita (badge + preço)
  static const _rightColW = 92.0;
  // Largura mínima reservada para a coluna esquerda (nº + data)
  static const _minLeftW  = 118.0;
  // Espaço entre colunas
  static const _colGap    = 10.0;

  /// Quantas fotos cabem numa única row dado [availableWidth].
  int _fitsCount(double availableWidth) {
    if (availableWidth <= 0) return 0;
    // n fotos ocupam n×_photoW + (n-1)×_photoGap
    // ↔  n ≤ (available + _photoGap) / (_photoW + _photoGap)
    return ((availableWidth + _photoGap) / (_photoW + _photoGap))
        .floor()
        .clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat     = DateFormat('dd/MM/yyyy', 'pt');
    final currencyFormat = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final photos         = _allPhotoBytes();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/orders/${order.id}').then((_) => onReturn?.call()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          // LayoutBuilder para saber exactamente quantas fotos cabem
          child: LayoutBuilder(builder: (ctx, constraints) {
            // Espaço sobrante depois de reservar colunas esquerda e direita
            final spaceForPhotos = constraints.maxWidth
                - _minLeftW
                - _rightColW
                - _colGap * 2;

            final showCount = photos.isEmpty
                ? 0
                : _fitsCount(spaceForPhotos).clamp(0, photos.length);
            final shown = photos.take(showCount).toList();

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // ── Coluna esquerda: número + data ────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Encomenda ${order.orderNumber}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (order.customer != null) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.business_outlined,
                              size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.customer!.name,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ],
                      const SizedBox(height: 3),
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
                    ],
                  ),
                ),

                // ── Coluna central: fotos em row (max 4, limite automático) ───
                if (shown.isNotEmpty) ...[
                  const SizedBox(width: _colGap),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < shown.length; i++) ...[
                        if (i > 0) const SizedBox(width: _photoGap),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            shown[i],
                            width:  _photoW,
                            height: _photoH,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // ── Coluna direita: estado + preço ─────────────────────────────
                const SizedBox(width: _colGap),
                SizedBox(
                  width: _rightColW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(status: order.status),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormat.format(order.valorTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.primary),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
