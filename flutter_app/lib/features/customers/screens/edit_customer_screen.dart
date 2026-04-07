import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../models/customer_model.dart';
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

class EditCustomerScreen extends ConsumerStatefulWidget {
  final CustomerModel customer;
  const EditCustomerScreen({super.key, required this.customer});

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey    = GlobalKey<FormState>();
  late final _nameCtrl    = TextEditingController(text: widget.customer.name);
  late final _emailCtrl   = TextEditingController(text: widget.customer.email ?? '');
  late final _phoneCtrl   = TextEditingController(text: widget.customer.phone ?? '');
  late final _taxIdCtrl   = TextEditingController(text: widget.customer.taxId ?? '');
  late final _addressCtrl = TextEditingController(text: widget.customer.address ?? '');
  late final _notesCtrl   = TextEditingController(text: widget.customer.notes ?? '');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _taxIdCtrl.dispose(); _addressCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final body = <String, dynamic>{'name': _nameCtrl.text.trim()};
      if (_emailCtrl.text.trim().isNotEmpty)   body['email']   = _emailCtrl.text.trim();
      if (_phoneCtrl.text.trim().isNotEmpty)   body['phone']   = _phoneCtrl.text.trim();
      if (_taxIdCtrl.text.trim().isNotEmpty)   body['taxId']   = _taxIdCtrl.text.trim();
      if (_addressCtrl.text.trim().isNotEmpty) body['address'] = _addressCtrl.text.trim();
      if (_notesCtrl.text.trim().isNotEmpty)   body['notes']   = _notesCtrl.text.trim();

      await ApiClient().dio.put(
        ApiEndpoints.customerById(widget.customer.id),
        data: body,
      );

      ref.read(customersProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente atualizado com sucesso!'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_extractError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check, color: Colors.white),
            label: const Text('Guardar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Secção: Identificação ─────────────────────────────
                    _sectionHeader(Icons.person_outline, 'Identificação'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _taxIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'NIF',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 20),
                    // ── Secção: Contacto ──────────────────────────────────
                    _sectionHeader(Icons.contact_phone_outlined, 'Contacto'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),
                    // ── Secção: Morada ────────────────────────────────────
                    _sectionHeader(Icons.location_on_outlined, 'Morada'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Morada',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),
                    // ── Secção: Notas ─────────────────────────────────────
                    _sectionHeader(Icons.notes_outlined, 'Notas'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notas internas',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary))
                  : const Icon(Icons.save),
              label: const Text('Guardar alterações'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.gold),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      );
}
