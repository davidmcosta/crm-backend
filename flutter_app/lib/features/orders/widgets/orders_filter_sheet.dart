import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/orders_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../customers/models/customer_model.dart';

/// Bottom sheet com filtros avançados para encomendas.
/// Devolve um [OrdersFilter] atualizado ou null se cancelado.
class OrdersFilterSheet extends ConsumerStatefulWidget {
  final OrdersFilter current;

  const OrdersFilterSheet({super.key, required this.current});

  @override
  ConsumerState<OrdersFilterSheet> createState() => _OrdersFilterSheetState();
}

class _OrdersFilterSheetState extends ConsumerState<OrdersFilterSheet> {
  late final TextEditingController _cemiterioCtrl;
  late final TextEditingController _trabalhoCtrl;
  late final TextEditingController _produtoCtrl;
  late final TextEditingController _customerCtrl;

  DateTime? _dateFrom;
  DateTime? _dateTo;
  CustomerModel? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _cemiterioCtrl = TextEditingController(text: widget.current.cemiterio ?? '');
    _trabalhoCtrl  = TextEditingController(text: widget.current.trabalho  ?? '');
    _produtoCtrl   = TextEditingController(text: widget.current.produto   ?? '');
    _customerCtrl  = TextEditingController(text: widget.current.customerName ?? '');
    _dateFrom = widget.current.dateFrom;
    _dateTo   = widget.current.dateTo;
  }

  @override
  void dispose() {
    _cemiterioCtrl.dispose();
    _trabalhoCtrl.dispose();
    _produtoCtrl.dispose();
    _customerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_dateFrom ?? now)
        : (_dateTo   ?? _dateFrom ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      helpText: isFrom ? 'Data de início' : 'Data de fim',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
        if (_dateTo != null && _dateTo!.isBefore(picked)) _dateTo = picked;
      } else {
        _dateTo = picked;
        if (_dateFrom != null && _dateFrom!.isAfter(picked)) _dateFrom = picked;
      }
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Selecionar';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _apply() {
    final f = widget.current.copyWith(
      cemiterio:    _cemiterioCtrl.text.trim().isEmpty ? null : _cemiterioCtrl.text.trim(),
      trabalho:     _trabalhoCtrl.text.trim().isEmpty  ? null : _trabalhoCtrl.text.trim(),
      produto:      _produtoCtrl.text.trim().isEmpty   ? null : _produtoCtrl.text.trim(),
      customerId:   _selectedCustomer?.id ?? (_customerCtrl.text.isEmpty ? null : widget.current.customerId),
      customerName: _selectedCustomer?.name ?? (_customerCtrl.text.isEmpty ? null : widget.current.customerName),
      dateFrom:     _dateFrom,
      dateTo:       _dateTo,
      clearCemiterio: _cemiterioCtrl.text.trim().isEmpty,
      clearTrabalho:  _trabalhoCtrl.text.trim().isEmpty,
      clearProduto:   _produtoCtrl.text.trim().isEmpty,
      clearCustomer:  _selectedCustomer == null && _customerCtrl.text.isEmpty,
      clearDateFrom:  _dateFrom == null,
      clearDateTo:    _dateTo   == null,
      page: 1,
    );
    Navigator.pop(context, f);
  }

  void _clear() {
    setState(() {
      _cemiterioCtrl.clear();
      _trabalhoCtrl.clear();
      _produtoCtrl.clear();
      _customerCtrl.clear();
      _selectedCustomer = null;
      _dateFrom = null;
      _dateTo   = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersState = ref.watch(customersProvider);
    final customers = customersState.customers;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ──────────────────────────────────────────────────
          Row(
            children: [
              Text('Filtros avançados',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: _clear,
                child: const Text('Limpar tudo'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // ── Período de datas ────────────────────────────────────────────
          Text('Período de criação',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'De',
                  value: _fmt(_dateFrom),
                  hasValue: _dateFrom != null,
                  onTap: () => _pickDate(isFrom: true),
                  onClear: () => setState(() => _dateFrom = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'Até',
                  value: _fmt(_dateTo),
                  hasValue: _dateTo != null,
                  onTap: () => _pickDate(isFrom: false),
                  onClear: () => setState(() => _dateTo = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Cliente ─────────────────────────────────────────────────────
          Text('Cliente',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 6),
          customersState.isLoading
              ? const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : Autocomplete<CustomerModel>(
                  initialValue: TextEditingValue(
                    text: widget.current.customerName ?? '',
                  ),
                  displayStringForOption: (c) => c.name,
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) return customers;
                    final q = value.text.toLowerCase();
                    return customers.where(
                      (c) => c.name.toLowerCase().contains(q),
                    );
                  },
                  onSelected: (customer) {
                    setState(() => _selectedCustomer = customer);
                  },
                  fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
                    // Sincronizar com limpeza
                    if (_selectedCustomer == null &&
                        widget.current.customerId == null &&
                        ctrl.text != _customerCtrl.text) {
                      ctrl.text = _customerCtrl.text;
                    }
                    return TextField(
                      controller: ctrl,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar cliente...',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        suffixIcon: ctrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  ctrl.clear();
                                  setState(() => _selectedCustomer = null);
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      onChanged: (_) {
                        if (_selectedCustomer != null) {
                          setState(() => _selectedCustomer = null);
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (ctx, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (_, i) {
                              final c = options.elementAt(i);
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.person, size: 18),
                                title: Text(c.name),
                                subtitle: c.email != null
                                    ? Text(c.email!,
                                        style: const TextStyle(fontSize: 11))
                                    : null,
                                onTap: () => onSelected(c),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 16),

          // ── Cemitério ───────────────────────────────────────────────────
          Text('Cemitério',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 6),
          _FilterField(
            controller: _cemiterioCtrl,
            hint: 'Ex: Cemitério Municipal de Lisboa',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),

          // ── Tipo de trabalho ────────────────────────────────────────────
          Text('Tipo de trabalho',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 6),
          _FilterField(
            controller: _trabalhoCtrl,
            hint: 'Ex: Lápide, Placa, Jazigo...',
            icon: Icons.build_outlined,
          ),
          const SizedBox(height: 16),

          // ── Produto / Descrição ─────────────────────────────────────────
          Text('Produto / Descrição',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 6),
          _FilterField(
            controller: _produtoCtrl,
            hint: 'Ex: granito, mármore, letras...',
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 24),

          // ── Botão Aplicar ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.filter_list),
              label: const Text('Aplicar filtros'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _FilterField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _FilterField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, v, __) => v.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: controller.clear,
                )
              : const SizedBox.shrink(),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateButton({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasValue
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
          color: hasValue
              ? theme.colorScheme.primary.withOpacity(0.08)
              : null,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16,
                color: hasValue
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  Text(value,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: hasValue
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: hasValue ? FontWeight.w600 : null)),
                ],
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close,
                    size: 16, color: theme.colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}
