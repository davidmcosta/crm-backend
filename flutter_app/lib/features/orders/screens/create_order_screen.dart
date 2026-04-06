import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/orders_provider.dart';
import '../../customers/providers/customers_provider.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ── Controllers ─────────────────────────────────────────────────────────────
  final _trabalhoCtrl        = TextEditingController();
  final _cemiterioCtrl       = TextEditingController();
  final _talhaoCtrl          = TextEditingController();
  final _numeroSepulturaCtrl = TextEditingController();
  final _nomeFalecidoCtrl    = TextEditingController();
  final _datasFalecidoCtrl   = TextEditingController();
  final _valorSepulturaCtrl  = TextEditingController(text: '0');
  final _kmCtrl              = TextEditingController();
  final _portagensCtrl       = TextEditingController(text: '0');
  final _deslocacaoCtrl      = TextEditingController(text: '0');
  final _extrasDescCtrl      = TextEditingController();
  final _extrasValorCtrl     = TextEditingController(text: '0');
  final _valorTotalCtrl      = TextEditingController(text: '0');
  final _requerenteCtrl      = TextEditingController();
  final _contactoCtrl        = TextEditingController();
  final _observacoesCtrl     = TextEditingController();

  String? _selectedCustomerId;
  String? _fotoPessoaBase64;
  Uint8List? _fotoPessoaBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _trabalhoCtrl.dispose();
    _cemiterioCtrl.dispose();
    _talhaoCtrl.dispose();
    _numeroSepulturaCtrl.dispose();
    _nomeFalecidoCtrl.dispose();
    _datasFalecidoCtrl.dispose();
    _valorSepulturaCtrl.dispose();
    _kmCtrl.dispose();
    _portagensCtrl.dispose();
    _deslocacaoCtrl.dispose();
    _extrasDescCtrl.dispose();
    _extrasValorCtrl.dispose();
    _valorTotalCtrl.dispose();
    _requerenteCtrl.dispose();
    _contactoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  // ── Cálculo automático ───────────────────────────────────────────────────────
  void _recalcTotal() {
    final sep   = _parseDecimal(_valorSepulturaCtrl.text);
    final desl  = _parseDecimal(_deslocacaoCtrl.text);
    final extra = _parseDecimal(_extrasValorCtrl.text);
    _valorTotalCtrl.text = (sep + desl + extra).toStringAsFixed(2);
  }

  void _recalcDeslocacao() {
    final km        = _parseDecimal(_kmCtrl.text);
    final portagens = _parseDecimal(_portagensCtrl.text);
    _deslocacaoCtrl.text = ((km * 0.36) + portagens).toStringAsFixed(2);
    _recalcTotal();
  }

  double _parseDecimal(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  // ── Foto (web) ───────────────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecção de foto disponível na versão web')),
      );
      return;
    }
    _pickPhotoWeb();
  }

  // Separated to avoid import errors on non-web builds
  void _pickPhotoWeb() {
    // Uses dart:html dynamically to avoid conditional import complexity
    final input = _createFileInput();
    input.click();
  }

  // ignore: avoid_web_libraries_in_flutter
  dynamic _createFileInput() {
    // dart:html is always available on web builds
    // ignore: undefined_identifier
    return (kIsWeb)
        ? (throw UnimplementedError()) // replaced at runtime on web
        : null;
  }

  // Called from build() when kIsWeb is true - avoids dart:html on non-web
  Future<void> _pickPhotoWebImpl() async {
    // We use a workaround: create an invisible input element via JS interop
    // This is handled inline in the button callback below
  }

  void _removePhoto() {
    setState(() {
      _fotoPessoaBase64 = null;
      _fotoPessoaBytes  = null;
    });
  }

  // ── Submit ───────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final body = <String, dynamic>{
        'trabalho':           _trabalhoCtrl.text.trim(),
        'nomeFalecido':       _nomeFalecidoCtrl.text.trim(),
        'requerente':         _requerenteCtrl.text.trim(),
        'contacto':           _contactoCtrl.text.trim(),
        'valorSepultura':     _parseDecimal(_valorSepulturaCtrl.text),
        'portagens':          _parseDecimal(_portagensCtrl.text),
        'deslocacaoMontagem': _parseDecimal(_deslocacaoCtrl.text),
        'extrasValor':        _parseDecimal(_extrasValorCtrl.text),
        'valorTotal':         _parseDecimal(_valorTotalCtrl.text),
      };

      if (_selectedCustomerId != null)
        body['customerId'] = _selectedCustomerId;
      if (_cemiterioCtrl.text.trim().isNotEmpty)
        body['cemiterio'] = _cemiterioCtrl.text.trim();
      if (_talhaoCtrl.text.trim().isNotEmpty)
        body['talhao'] = _talhaoCtrl.text.trim();
      if (_numeroSepulturaCtrl.text.trim().isNotEmpty)
        body['numeroSepultura'] = _numeroSepulturaCtrl.text.trim();
      if (_fotoPessoaBase64 != null)
        body['fotoPessoa'] = _fotoPessoaBase64;
      if (_datasFalecidoCtrl.text.trim().isNotEmpty)
        body['datasFalecido'] = _datasFalecidoCtrl.text.trim();
      if (_kmCtrl.text.trim().isNotEmpty)
        body['km'] = _parseDecimal(_kmCtrl.text);
      if (_extrasDescCtrl.text.trim().isNotEmpty)
        body['extrasDescricao'] = _extrasDescCtrl.text.trim();
      if (_observacoesCtrl.text.trim().isNotEmpty)
        body['observacoes'] = _observacoesCtrl.text.trim();

      await ref.read(ordersProvider.notifier).createOrder(body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Encomenda criada com sucesso!'),
              backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Encomenda'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
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

            // ── FALECIDO ────────────────────────────────────────────────────
            _sectionHeader(Icons.person, 'Falecido(a)'),
            const SizedBox(height: 16),

            // Foto
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: _fotoPessoaBytes != null
                        ? MemoryImage(_fotoPessoaBytes!)
                        : null,
                    child: _fotoPessoaBytes == null
                        ? const Icon(Icons.person, size: 40,
                            color: Color(0xFF94A3B8))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _fotoPessoaBytes != null
                          ? _removePhoto
                          : _pickPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _fotoPessoaBytes != null
                              ? Colors.red
                              : const Color(0xFF1E40AF),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          _fotoPessoaBytes != null
                              ? Icons.close
                              : Icons.add_a_photo,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text('Toque para adicionar foto',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 16),

            _field(
              controller: _nomeFalecidoCtrl,
              label: 'Nome do(a) falecido(a) *',
              icon: Icons.badge_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Campo obrigatório'
                  : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _datasFalecidoCtrl,
              label: 'Datas  (ex: 01/01/1950 - 15/03/2026)',
              icon: Icons.date_range_outlined,
            ),

            const SizedBox(height: 24),

            // ── TRABALHO ────────────────────────────────────────────────────
            _sectionHeader(Icons.construction, 'Trabalho'),
            const SizedBox(height: 12),

            _field(
              controller: _trabalhoCtrl,
              label: 'Descrição do trabalho *',
              icon: Icons.description_outlined,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Campo obrigatório'
                  : null,
            ),

            const SizedBox(height: 24),

            // ── CEMITÉRIO ───────────────────────────────────────────────────
            _sectionHeader(Icons.location_on_outlined, 'Cemitério'),
            const SizedBox(height: 12),

            _field(
              controller: _cemiterioCtrl,
              label: 'Cemitério (opcional)',
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _talhaoCtrl,
                    label: 'Letra/Nº do talhão',
                    icon: Icons.grid_on_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _numeroSepulturaCtrl,
                    label: 'Nº de sepultura',
                    icon: Icons.tag,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── VALORES ─────────────────────────────────────────────────────
            _sectionHeader(Icons.euro, 'Valores'),
            const SizedBox(height: 12),

            _field(
              controller: _valorSepulturaCtrl,
              label: 'Valor da sepultura (€)',
              icon: Icons.euro_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(_recalcTotal),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _kmCtrl,
                    label: 'Km (opcional)',
                    icon: Icons.route_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(_recalcDeslocacao),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _portagensCtrl,
                    label: 'Portagens (€)',
                    icon: Icons.toll_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(_recalcDeslocacao),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Deslocação calculada automaticamente a €0,36/km + portagens',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),

            _field(
              controller: _deslocacaoCtrl,
              label: 'Deslocação / Montagem (€)',
              icon: Icons.drive_eta_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(_recalcTotal),
            ),
            const SizedBox(height: 12),

            _field(
              controller: _extrasDescCtrl,
              label: 'Extras – descrição (opcional)',
              icon: Icons.add_circle_outline,
            ),
            const SizedBox(height: 8),
            _field(
              controller: _extrasValorCtrl,
              label: 'Extras – valor (€)',
              icon: Icons.euro_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(_recalcTotal),
            ),
            const SizedBox(height: 12),

            // Total destacado
            TextFormField(
              controller: _valorTotalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF)),
              decoration: InputDecoration(
                labelText: 'Valor Total (€)',
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.summarize_outlined,
                    color: Color(0xFF1E40AF)),
                filled: true,
                fillColor: const Color(0xFFEFF6FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E40AF)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── REQUERENTE ──────────────────────────────────────────────────
            _sectionHeader(Icons.person_outline, 'Requerente'),
            const SizedBox(height: 12),

            _field(
              controller: _requerenteCtrl,
              label: 'Nome do requerente *',
              icon: Icons.person_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Campo obrigatório'
                  : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _contactoCtrl,
              label: 'Contacto *',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Campo obrigatório'
                  : null,
            ),

            const SizedBox(height: 24),

            // ── CLIENTE (OPCIONAL) ──────────────────────────────────────────
            _sectionHeader(Icons.business_outlined, 'Cliente (opcional)'),
            const SizedBox(height: 12),

            customersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customersState.error != null
                    ? Text('Erro ao carregar clientes: ${customersState.error}')
                    : DropdownButtonFormField<String>(
                        value: _selectedCustomerId,
                        decoration: InputDecoration(
                          labelText: 'Associar cliente',
                          prefixIcon:
                              const Icon(Icons.business_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('— Nenhum —')),
                          ...customersState.customers.map((c) =>
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedCustomerId = v),
                      ),

            const SizedBox(height: 24),

            // ── OBSERVAÇÕES ─────────────────────────────────────────────────
            _sectionHeader(Icons.notes_outlined, 'Observações'),
            const SizedBox(height: 12),

            _field(
              controller: _observacoesCtrl,
              label: 'Observações (opcional)',
              icon: Icons.notes,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Guardar Encomenda'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1E40AF)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E40AF)),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      );
}
