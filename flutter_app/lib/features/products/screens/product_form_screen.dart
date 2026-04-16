import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/products_provider.dart';
import '../models/product_model.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

// ── BOM row state ─────────────────────────────────────────────────────────────

class _BOMRow {
  // Produto ligado do catálogo (opcional)
  String? componentProductId;
  String? componentProductName; // só para mostrar o badge

  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _BOMRow({
    this.componentProductId,
    this.componentProductName,
    String name  = '',
    String qty   = '1',
    String price = '0',
  })  : nameCtrl  = TextEditingController(text: name),
        qtyCtrl   = TextEditingController(text: qty),
        priceCtrl = TextEditingController(text: price);

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }

  Map<String, dynamic> toJson(int idx) => {
        if (componentProductId != null)
          'componentProductId': componentProductId,
        'componentName': nameCtrl.text.trim(),
        'qty':           double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1,
        'includedPrice': double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0,
        'sortOrder':     idx,
      };
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ProductFormScreen extends ConsumerStatefulWidget {
  final ProductModel? product; // null = create

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _catCtrl   = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _isActive = true;
  bool _saving   = false;
  final List<_BOMRow> _bomRows = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text  = p.name;
      _catCtrl.text   = p.category ?? '';
      _descCtrl.text  = p.description ?? '';
      _priceCtrl.text = p.basePrice.toString();
      _isActive       = p.isActive;
      for (final item in p.bomItems) {
        _bomRows.add(_BOMRow(
          componentProductId:   item.componentProductId,
          componentProductName: item.componentProductId != null ? item.componentName : null,
          name:  item.componentName,
          qty:   item.qty.toString(),
          price: item.includedPrice.toString(),
        ));
      }
    } else {
      _priceCtrl.text = '0';
    }
    // Pre-load product list for BOM picker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    for (final r in _bomRows) r.dispose();
    super.dispose();
  }

  double get _computedBasePrice =>
      double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;

  // ── Picker de produto para BOM ─────────────────────────────────────────────
  Future<void> _pickComponentProduct(_BOMRow row) async {
    final products = ref.read(productsNotifierProvider).products
        .where((p) => p.id != widget.product?.id) // não pode referenciar a si próprio
        .toList();

    final picked = await showDialog<ProductModel>(
      context: context,
      builder: (ctx) => _ProductPickDialog(
        products:        products,
        currentId:       row.componentProductId,
        excludeId:       widget.product?.id,
      ),
    );

    if (picked == null) return;

    setState(() {
      row.componentProductId   = picked.id;
      row.componentProductName = picked.name;
      row.nameCtrl.text        = picked.name;
      row.priceCtrl.text       = picked.basePrice.toString();
    });
  }

  void _clearComponentProduct(_BOMRow row) {
    setState(() {
      row.componentProductId   = null;
      row.componentProductName = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name':        _nameCtrl.text.trim(),
      'category':    _catCtrl.text.trim().isEmpty ? null : _catCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'basePrice':   _computedBasePrice,
      'isActive':    _isActive,
      'bomItems':    _bomRows.asMap().entries
          .where((e) => e.value.nameCtrl.text.trim().isNotEmpty)
          .map((e) => e.value.toJson(e.key))
          .toList(),
    };

    try {
      final notifier = ref.read(productsNotifierProvider.notifier);
      if (widget.product == null) {
        await notifier.create(data);
      } else {
        await notifier.update(widget.product!.id, data);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar produto'),
        content: const Text('Tem a certeza que quer eliminar este produto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(productsNotifierProvider.notifier).delete(widget.product!.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit      = widget.product != null;
    final allProducts = ref.watch(productsNotifierProvider).products;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Produto' : 'Novo Produto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              tooltip: 'Eliminar produto',
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Informações básicas ──────────────────────────────────────────
            _sectionHeader('Informações do produto'),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome *',
                  prefixIcon: Icon(Icons.label_outlined, size: 18)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catCtrl,
              decoration: const InputDecoration(
                  labelText: 'Categoria',
                  hintText: 'ex: Campas, Lápides, Acessórios',
                  prefixIcon: Icon(Icons.folder_outlined, size: 18)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined, size: 18)),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Preço total (€) *',
                prefixIcon: Icon(Icons.euro_outlined, size: 18),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Campo obrigatório'
                  : null,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Produto ativo', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                  'Aparece no catálogo e no picker de encomendas',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),

            const SizedBox(height: 16),

            // ── Composição (BOM) ─────────────────────────────────────────────
            _sectionHeader('Composição do produto'),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Adicione os componentes incluídos neste produto. '
                'Pode ligar cada componente a um produto já existente no catálogo.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),

            ..._bomRows.asMap().entries.map((entry) {
              final i   = entry.key;
              final row = entry.value;
              return _BOMRowWidget(
                row:       row,
                index:     i,
                allProducts: allProducts,
                onPickProduct:  () => _pickComponentProduct(row),
                onClearProduct: () => _clearComponentProduct(row),
                onRemove:  () => setState(() {
                  row.dispose();
                  _bomRows.removeAt(i);
                }),
                onChanged: () => setState(() {}),
              );
            }),

            OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar componente'),
              onPressed: () => setState(() => _bomRows.add(_BOMRow())),
            ),

            if (_bomRows.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.goldFaint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline, size: 14, color: AppTheme.gold),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'O preço total inclui todos os componentes. Numa encomenda, a linha do produto fica com o preço total menos a soma dos componentes, e cada componente aparece como linha separada editável.',
                      style: TextStyle(fontSize: 11, color: AppTheme.gold),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Guardar alterações' : 'Criar produto'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          const Icon(Icons.circle, size: 6, color: AppTheme.gold),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ]),
      );
}

// ── BOM row widget ────────────────────────────────────────────────────────────

class _BOMRowWidget extends StatelessWidget {
  final _BOMRow              row;
  final int                  index;
  final List<ProductModel>   allProducts;
  final VoidCallback         onPickProduct;
  final VoidCallback         onClearProduct;
  final VoidCallback         onRemove;
  final VoidCallback         onChanged;

  const _BOMRowWidget({
    required this.row,
    required this.index,
    required this.allProducts,
    required this.onPickProduct,
    required this.onClearProduct,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLinked = row.componentProductId != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: Center(
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gold)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Componente',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppTheme.textMuted,
                onPressed: onRemove,
              ),
            ]),

            const SizedBox(height: 8),

            // ── Linked product badge OR pick button ─────────────────────────
            if (isLinked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.link, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      row.componentProductName ?? '',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary),
                    ),
                  ),
                  InkWell(
                    onTap: onClearProduct,
                    child: const Icon(Icons.link_off,
                        size: 16, color: AppTheme.textMuted),
                  ),
                ]),
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.category_outlined, size: 16),
                label: const Text('Ligar a produto do catálogo',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                ),
                onPressed: onPickProduct,
              ),

            const SizedBox(height: 8),

            // ── Nome (editável mas pré-preenchido se ligado) ─────────────────
            TextField(
              controller: row.nameCtrl,
              decoration: InputDecoration(
                labelText: isLinked ? 'Nome (do produto ligado)' : 'Nome do componente',
                isDense: true,
                prefixIcon: const Icon(Icons.build_outlined, size: 16),
              ),
              onChanged: (_) => onChanged(),
            ),

            const SizedBox(height: 8),

            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: row.priceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Preço ref. (€)',
                      isDense: true,
                      prefixIcon: Icon(Icons.euro_outlined, size: 16)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: row.qtyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Qtd', isDense: true),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo de seleção de produto para BOM ────────────────────────────────────

class _ProductPickDialog extends StatefulWidget {
  final List<ProductModel> products;
  final String?            currentId;
  final String?            excludeId;

  const _ProductPickDialog({
    required this.products,
    this.currentId,
    this.excludeId,
  });

  @override
  State<_ProductPickDialog> createState() => _ProductPickDialogState();
}

class _ProductPickDialogState extends State<_ProductPickDialog> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

    var filtered = widget.products
        .where((p) => p.id != widget.excludeId)
        .toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.category?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.category_outlined,
                  size: 18, color: AppTheme.gold),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Selecionar produto',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 10),
            TextField(
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
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhum produto encontrado',
                          style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        final isSelected = p.id == widget.currentId;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor:
                              AppTheme.gold.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppTheme.gold.withOpacity(0.1),
                            child: const Icon(
                                Icons.category_outlined,
                                size: 14,
                                color: AppTheme.gold),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: p.category != null
                              ? Text(p.category!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted))
                              : null,
                          trailing: Text(
                            currency.format(p.basePrice),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary),
                          ),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
