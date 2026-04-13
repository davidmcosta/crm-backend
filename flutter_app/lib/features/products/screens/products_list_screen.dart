import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/products_provider.dart';
import '../models/product_model.dart';
import '../../../core/theme/app_theme.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> _filtered(List<ProductModel> all) {
    var list = all;
    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      list = list.where((p) =>
          p.category?.toLowerCase() == _categoryFilter!.toLowerCase()).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.category?.toLowerCase().contains(q) ?? false) ||
          (p.description?.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsNotifierProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final filtered = _filtered(state.products);

    // Group by category
    final Map<String, List<ProductModel>> grouped = {};
    for (final p in filtered) {
      final cat = p.category ?? 'Sem categoria';
      grouped.putIfAbsent(cat, () => []).add(p);
    }
    final categories = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo produto',
            onPressed: () => context.push('/products/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Pesquisar produtos...',
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // ── Category chips ────────────────────────────────────────────────
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => cats.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    height: 38,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                    _categoryFilter =
                                        _categoryFilter == cat ? null : cat),
                              ),
                            )),
                      ],
                    ),
                  ),
          ),

          const Divider(height: 1),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Erro: ${state.error}'))
                    : filtered.isEmpty
                        ? const Center(
                            child: Text('Nenhum produto encontrado',
                                style: TextStyle(color: AppTheme.textMuted)))
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(productsNotifierProvider.notifier)
                                .load(category: state.selectedCategory),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, bottom: 80, top: 8),
                              itemCount: categories.length,
                              itemBuilder: (ctx, catIdx) {
                                final cat = categories[catIdx];
                                final items = grouped[cat]!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Category header
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 4),
                                      child: Row(children: [
                                        const Icon(Icons.folder_outlined,
                                            size: 14, color: AppTheme.gold),
                                        const SizedBox(width: 6),
                                        Text(cat,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.gold)),
                                        const SizedBox(width: 8),
                                        const Expanded(child: Divider()),
                                      ]),
                                    ),
                                    ...items.map((p) =>
                                        _ProductCard(product: p)),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/products/${product.id}/edit', extra: product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.category_outlined,
                        size: 16, color: AppTheme.gold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Text(currency.format(product.basePrice),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.primary)),
                ],
              ),
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(product.description!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              if (product.bomItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: product.bomItems.map((item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppTheme.primary.withOpacity(0.15)),
                        ),
                        child: Text(
                          '${item.componentName} — ${currency.format(item.includedPrice)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.primary),
                        ),
                      )).toList(),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    product.isActive
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 12,
                    color: product.isActive
                        ? AppTheme.success
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    product.isActive ? 'Ativo' : 'Inativo',
                    style: TextStyle(
                        fontSize: 11,
                        color: product.isActive
                            ? AppTheme.success
                            : AppTheme.textMuted),
                  ),
                  if (product.bomItems.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.account_tree_outlined,
                        size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${product.bomItems.length} componentes',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted)),
                  ],
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppTheme.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
