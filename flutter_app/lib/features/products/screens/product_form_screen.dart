import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/products_provider.dart';
import '../models/product_model.dart';
import '../../../core/theme/app_theme.dart';

// ── BOM row state ─────────────────────────────────────────────────────────────

class _BOMRow {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _BOMRow({String name = '', String qty = '1', String price = '0'})
      : nameCtrl  = TextEditingController(text: name),
        qtyCtrl   = TextEditingController(text: qty),
        priceCtrl = TextEditingController(text: price);

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }

  Map<String, dynamic> toJson(int idx) => {
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
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _catCtrl    = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();

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
          name:  item.componentName,
          qty:   item.qty.toString(),
          price: item.includedPrice.toString(),
        ));
      }
    } else {
      _priceCtrl.text = '0';
    }
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

  double get _computedBasePrice {
    if (_bomRows.isEmpty) {
      return double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    }
    return _bomRows.fold(0.0, (sum, r) {
      final p = double.tryParse(r.priceCtrl.text.replaceAll(',', '.')) ?? 0;
      final q = double.tryParse(r.qtyCtrl.text.replaceAll(',', '.')) ?? 1;
      return sum + p * q;
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
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.error),
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
        content:
            const Text('Tem a certeza que quer eliminar este produto?'),
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
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit   = widget.product != null;
    final currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

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

            // Price field — only editable when no BOM items
            AnimatedOpacity(
              opacity: _bomRows.isEmpty ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: TextFormField(
                controller: _priceCtrl,
                enabled: _bomRows.isEmpty,
                decoration: InputDecoration(
                  labelText: _bomRows.isEmpty
                      ? 'Preço base (€) *'
                      : 'Preço base (€) — calculado pelos componentes',
                  prefixIcon:
                      const Icon(Icons.euro_outlined, size: 18),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _bomRows.isEmpty
                    ? (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório'
                        : null
                    : null,
              ),
            ),

            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Produto ativo',
                  style: TextStyle(fontSize: 14)),
              subtitle: const Text('Aparece no catálogo e no picker de encomendas',
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
                'Adicione os componentes incluídos neste produto. O preço base é calculado automaticamente como a soma dos componentes.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),

            ..._bomRows.asMap().entries.map((entry) {
              final i   = entry.key;
              final row = entry.value;
              return _BOMRowWidget(
                row: row,
                index: i,
                onRemove: () => setState(() {
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

            // ── Resumo do preço ─────────────────────────────────────────────
            if (_bomRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.euro_outlined,
                      size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text('Preço total calculado:',
                      style: TextStyle(fontSize: 13, color: AppTheme.primary)),
                  const Spacer(),
                  Text(
                    currency.format(_computedBasePrice),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
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
  final _BOMRow  row;
  final int      index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _BOMRowWidget({
    required this.row,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 22,
                height: 22,
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
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
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
            TextField(
              controller: row.nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome do componente',
                  isDense: true,
                  prefixIcon: Icon(Icons.build_outlined, size: 16)),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: row.priceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Preço incl. (€)',
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
