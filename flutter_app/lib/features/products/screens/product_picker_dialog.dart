import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/products_provider.dart';
import '../models/product_model.dart';
import '../../../core/theme/app_theme.dart';

// ── Result returned when user picks a product ─────────────────────────────────

class ProductPickResult {
  /// Either a single line (no BOM) or multiple BOM lines
  final List<_PickedLine> lines;
  const ProductPickResult(this.lines);
}

class _PickedLine {
  final String nome;
  final double qty;
  final double precoUnit;
  const _PickedLine({required this.nome, required this.qty, required this.precoUnit});
}

List<Map<String, dynamic>> productPickResultToRows(ProductPickResult result) {
  return result.lines
      .map((l) => {'nome': l.nome, 'qty': l.qty, 'precoUnit': l.precoUnit})
      .toList();
}

// ── Dialog ────────────────────────────────────────────────────────────────────

Future<ProductPickResult?> showProductPickerDialog(BuildContext context) {
  return showModalBottomSheet<ProductPickResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => const _ProductPickerSheet(),
  );
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _categoryFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAsync  = ref.watch(allProductsProvider);
    final catsAsync = ref.watch(productCategoriesProvider);
    final currency  = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Icon(Icons.category_outlined,
                    size: 18, color: AppTheme.gold),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Selecionar produto do catálogo',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
            ),
            // Search
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          })
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            // Category chips
            catsAsync.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data:    (cats) => cats.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 36,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: const Text('Todos'),
                              selected: _categoryFilter == null,
                              onSelected: (_) =>
                                  setState(() => _categoryFilter = null),
                            ),
                          ),
                          ...cats.map((cat) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(cat),
                                  selected: _categoryFilter == cat,
                                  onSelected: (_) => setState(() =>
                                      _categoryFilter = _categoryFilter == cat
                                          ? null
                                          : cat),
                                ),
                              )),
                        ],
                      ),
                    ),
            ),
            const Divider(height: 1),
            // Product list
            Expanded(
              child: allAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Erro: $e')),
                data: (products) {
                  var filtered = products;
                  if (_categoryFilter != null) {
                    filtered = filtered
                        .where((p) =>
                            p.category?.toLowerCase() ==
                            _categoryFilter!.toLowerCase())
                        .toList();
                  }
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    filtered = filtered
                        .where((p) =>
                            p.name.toLowerCase().contains(q) ||
                            (p.category?.toLowerCase().contains(q) ??
                                false))
                        .toList();
                  }
                  if (filtered.isEmpty) {
                    return const Center(
                        child: Text('Nenhum produto encontrado',
                            style: TextStyle(
                                color: AppTheme.textMuted)));
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final result = _buildResult(p);
                            Navigator.pop(context, result);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.gold.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.category_outlined,
                                    size: 16,
                                    color: AppTheme.gold),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    if (p.category != null)
                                      Text(p.category!,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textMuted)),
                                    if (p.bomItems.isNotEmpty)
                                      Text(
                                        p.bomItems
                                            .map((b) => b.componentName)
                                            .join(', '),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(currency.format(p.basePrice),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary)),
                            ]),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  ProductPickResult _buildResult(ProductModel p) {
    if (p.bomItems.isEmpty) {
      return ProductPickResult([
        _PickedLine(nome: p.name, qty: 1, precoUnit: p.basePrice),
      ]);
    }

    // Preço da linha principal = preço total - soma dos componentes
    // (os componentes são adicionados como linhas separadas)
    final componentTotal = p.bomItems.fold(
      0.0,
      (sum, item) => sum + item.includedPrice * item.qty,
    );
    final baseLinePrice = p.basePrice - componentTotal;

    final lines = <_PickedLine>[
      _PickedLine(nome: p.name, qty: 1, precoUnit: baseLinePrice),
      ...p.bomItems.map((item) => _PickedLine(
            nome:      item.componentName,
            qty:       item.qty,
            precoUnit: item.includedPrice,
          )),
    ];

    return ProductPickResult(lines);
  }
}
