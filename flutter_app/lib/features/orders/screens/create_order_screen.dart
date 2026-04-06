import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../providers/orders_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../../core/api/api_client.dart';

class _ItemForm {
  final productCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();

  void dispose() {
    productCtrl.dispose();
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  String? _selectedCustomerId;
  DateTime? _expectedDate;
  final List<_ItemForm> _items = [_ItemForm()];
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final item in _items) item.dispose();
    super.dispose();
  }

  double get _total => _items.fold(0, (sum, item) {
        final qty = int.tryParse(item.qtyCtrl.text) ?? 0;
        final price = double.tryParse(item.priceCtrl.text) ?? 0;
        return sum + qty * price;
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um cliente')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Construir o body sem campos nulos (Zod rejeita null em campos opcionais)
      final body = <String, dynamic>{
        'customerId': _selectedCustomerId,
        'items': _items
            .map((item) {
              final price = double.parse(
                  item.priceCtrl.text.trim().replaceAll(',', '.'));
              final qty = int.parse(item.qtyCtrl.text.trim());
              final itemMap = <String, dynamic>{
                'productName': item.productCtrl.text.trim(),
                'quantity': qty,
                'unitPrice': price,
              };
              final desc = item.descCtrl.text.trim();
              if (desc.isNotEmpty) itemMap['description'] = desc;
              return itemMap;
            })
            .toList(),
      };
      if (_notesCtrl.text.isNotEmpty) body['notes'] = _notesCtrl.text;
      if (_expectedDate != null) body['expectedDate'] = _expectedDate!.toUtc().toIso8601String();

      await createOrder(body);

      ref.read(ordersProvider.notifier).refresh();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Encomenda criada com sucesso!'),
              backgroundColor: Colors.green),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        // Mostrar o erro completo do servidor para debug
        final responseData = e.response?.data;
        String errorMsg = extractErrorMessage(e);
        if (responseData is Map && responseData.containsKey('details')) {
          errorMsg += '\nDetalhes: ${responseData['details']}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 10)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);
    
    // Carregar clientes ao abrir o ecrã
    ref.listen(customersProvider, (_, __) {});
    if (!customersState.isLoading && customersState.customers.isEmpty && customersState.error == null) {
      Future.microtask(() => ref.read(customersProvider.notifier).load());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Encomenda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cliente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cliente',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCustomerId,
                      decoration: const InputDecoration(
                          hintText: 'Seleciona um cliente'),
                      items: customersState.customers
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCustomerId = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Itens
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Itens',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _items.add(_ItemForm())),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                    ..._items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Item ${i + 1}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ),
                                if (_items.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    onPressed: () => setState(
                                        () => _items.removeAt(i)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: item.productCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Produto *'),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Obrigatório'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: item.descCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Descrição'),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: item.qtyCtrl,
                                    decoration: const InputDecoration(
                                        labelText: 'Qtd *'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Obrigatório';
                                      if (int.tryParse(v) == null ||
                                          int.parse(v) <= 0)
                                        return 'Inválido';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: item.priceCtrl,
                                    decoration: const InputDecoration(
                                        labelText: 'Preço unit. (€) *'),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Obrigatório';
                                      if (double.tryParse(v) == null ||
                                          double.parse(v) <= 0)
                                        return 'Inválido';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    // Total em tempo real
                    if (_total > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: €${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E40AF)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Detalhes adicionais
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detalhes adicionais',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(_expectedDate == null
                          ? 'Data prevista (opcional)'
                          : '${_expectedDate!.day.toString().padLeft(2, '0')}/${_expectedDate!.month.toString().padLeft(2, '0')}/${_expectedDate!.year}'),
                      trailing: _expectedDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _expectedDate = null),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now()
                              .add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _expectedDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                        hintText: 'Instruções especiais, observações...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Criar Encomenda',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
