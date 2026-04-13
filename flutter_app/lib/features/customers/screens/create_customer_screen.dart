import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../providers/customers_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

String _extractError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is List) return (msg as List).join('\n');
      if (msg != null) return msg.toString();
    }
  }
  return e.toString().replaceAll('Exception: ', '');
}

class CreateCustomerScreen extends ConsumerStatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  ConsumerState<CreateCustomerScreen> createState() =>
      _CreateCustomerScreenState();
}

class _CreateCustomerScreenState
    extends ConsumerState<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _taxIdCtrl    = TextEditingController();
  final _notesCtrl    = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _taxIdCtrl.dispose(); _notesCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final body = <String, dynamic>{'name': _nameCtrl.text.trim()};
      if (_emailCtrl.text.trim().isNotEmpty)   body['email']   = _emailCtrl.text.trim();
      if (_phoneCtrl.text.trim().isNotEmpty)   body['phone']   = _phoneCtrl.text.trim();
      if (_addressCtrl.text.trim().isNotEmpty) body['address'] = _addressCtrl.text.trim();
      if (_taxIdCtrl.text.trim().isNotEmpty)   body['taxId']   = _taxIdCtrl.text.trim();
      if (_notesCtrl.text.trim().isNotEmpty)   body['notes']   = _notesCtrl.text.trim();
      body['discount'] = double.tryParse(_discountCtrl.text.replaceAll(',', '.')) ?? 0.0;

      await ApiClient().dio.post(ApiEndpoints.customers, data: body);

      ref.read(customersProvider.notifier).refresh();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cliente criado com sucesso!'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractError(e)), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nome *'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Nome é obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _taxIdCtrl,
                      decoration: const InputDecoration(labelText: 'NIF'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Morada'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notas'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.discount_outlined,
                          size: 16, color: AppTheme.gold),
                      const SizedBox(width: 6),
                      const Text('Desconto de revendedor',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                              fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _discountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Desconto (%)',
                        hintText: '0 = sem desconto',
                        prefixIcon: Icon(Icons.percent),
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final d = double.tryParse(v?.replaceAll(',', '.') ?? '');
                        if (d == null || d < 0 || d > 100) return 'Valor entre 0 e 100';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    if ((double.tryParse(_discountCtrl.text.replaceAll(',', '.')) ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.stars_outlined,
                                size: 14, color: AppTheme.gold),
                            const SizedBox(width: 6),
                            Text(
                              'Revendedor com ${_discountCtrl.text}% de desconto nas encomendas',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.gold),
                            ),
                          ]),
                        ),
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
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2))
                  : const Text('Guardar Cliente',
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
