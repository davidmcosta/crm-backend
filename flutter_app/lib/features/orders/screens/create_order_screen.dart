import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../../core/theme/app_theme.dart';

// ── Linha de produto ──────────────────────────────────────────────────────────

class _ProdRow {
  final nomeCtrl  = TextEditingController();
  final qtyCtrl   = TextEditingController(text: '1');
  final precoCtrl = TextEditingController(text: '0,00');

  void dispose() {
    nomeCtrl.dispose();
    qtyCtrl.dispose();
    precoCtrl.dispose();
  }

  double get qty   => double.tryParse(qtyCtrl.text.replaceAll(',', '.'))   ?? 0;
  double get preco => double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0;
  double get total => qty * preco;
}

// ── Linha de extra ────────────────────────────────────────────────────────────

class _ExtraRow {
  final descCtrl  = TextEditingController();
  final valorCtrl = TextEditingController(text: '0,00');

  void dispose() {
    descCtrl.dispose();
    valorCtrl.dispose();
  }

  double get valor => double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CreateOrderScreen extends ConsumerStatefulWidget {
  /// Se fornecido, entra em modo edição
  final OrderModel? initialOrder;

  const CreateOrderScreen({super.key, this.initialOrder});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey  = GlobalKey<FormState>();
  bool _isLoading = false;

  bool get _isEdit => widget.initialOrder != null;

  // ── Controllers ──────────────────────────────────────────────────────────────
  final _trabalhoCtrl        = TextEditingController();
  final _cemiterioCtrl       = TextEditingController();
  final _talhaoCtrl          = TextEditingController();
  final _numeroSepulturaCtrl = TextEditingController();
  final _nomeFalecidoCtrl    = TextEditingController();
  final _datasFalecidoCtrl   = TextEditingController();
  final _dedicatoriaCtrl     = TextEditingController();
  final _kmCtrl              = TextEditingController();
  final _portagensCtrl       = TextEditingController(text: '0');
  final _requerenteCtrl      = TextEditingController();
  final _contactoCtrl        = TextEditingController();
  final _observacoesCtrl     = TextEditingController();

  String?    _selectedCustomerId;
  double     _selectedCustomerDiscount = 0;
  String?    _fotoPessoaBase64;
  Uint8List? _fotoPessoaBytes;
  List<_ProdRow>  _produtos = [_ProdRow()];
  List<_ExtraRow> _extras   = [];

  // Calculados
  double _refeicoes       = 0;
  double _deslocacao      = 0;
  bool   _precisaRefeicao = false;

  final _currency = NumberFormat.currency(locale: 'pt_PT', symbol: '€');

  // ── Init ─────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersProvider.notifier).load();
      if (_isEdit) _prefill(widget.initialOrder!);
    });
  }

  void _prefill(OrderModel o) {
    _trabalhoCtrl.text        = o.trabalho;
    _cemiterioCtrl.text       = o.cemiterio       ?? '';
    _talhaoCtrl.text          = o.talhao          ?? '';
    _numeroSepulturaCtrl.text = o.numeroSepultura ?? '';
    _nomeFalecidoCtrl.text    = o.nomeFalecido    ?? '';
    _datasFalecidoCtrl.text   = o.datasFalecido   ?? '';
    _dedicatoriaCtrl.text     = o.dedicatoria     ?? '';
    _kmCtrl.text              = o.km?.toString()  ?? '';
    _portagensCtrl.text       = o.portagens.toStringAsFixed(2);
    _requerenteCtrl.text      = o.requerente;
    _contactoCtrl.text        = o.contacto;
    _observacoesCtrl.text     = o.observacoes ?? '';
    _selectedCustomerId       = o.customer?.id;
    _selectedCustomerDiscount = o.descontoPerc;

    if (o.fotoPessoa != null && o.fotoPessoa!.isNotEmpty) {
      _fotoPessoaBase64 = o.fotoPessoa;
      final b64 = o.fotoPessoa!.contains(',')
          ? o.fotoPessoa!.split(',').last
          : o.fotoPessoa!;
      _fotoPessoaBytes = base64Decode(b64);
    }

    if (o.produtos.isNotEmpty) {
      _produtos = o.produtos.map((p) {
        final r = _ProdRow();
        r.nomeCtrl.text  = p.nome;
        r.qtyCtrl.text   =
            p.qty % 1 == 0 ? p.qty.toInt().toString() : p.qty.toStringAsFixed(2);
        r.precoCtrl.text = p.precoUnit.toStringAsFixed(2);
        return r;
      }).toList();
    }

    if (o.extras.isNotEmpty) {
      _extras = o.extras.map((e) {
        final r = _ExtraRow();
        r.descCtrl.text  = e.descricao;
        r.valorCtrl.text = e.valor.toStringAsFixed(2);
        return r;
      }).toList();
    }

    _refeicoes  = o.refeicoes;
    _deslocacao = o.deslocacaoMontagem;
    _recalcDeslocacao();
  }

  @override
  void dispose() {
    _trabalhoCtrl.dispose();
    _cemiterioCtrl.dispose();
    _talhaoCtrl.dispose();
    _numeroSepulturaCtrl.dispose();
    _nomeFalecidoCtrl.dispose();
    _datasFalecidoCtrl.dispose();
    _dedicatoriaCtrl.dispose();
    _kmCtrl.dispose();
    _portagensCtrl.dispose();
    _requerenteCtrl.dispose();
    _contactoCtrl.dispose();
    _observacoesCtrl.dispose();
    for (final r in _produtos) r.dispose();
    for (final r in _extras)   r.dispose();
    super.dispose();
  }

  // ── Cálculos ──────────────────────────────────────────────────────────────────
  double get _subtotalProdutos =>
      _produtos.fold(0, (s, r) => s + r.total);

  double get _subtotalExtras =>
      _extras.fold(0, (s, r) => s + r.valor);

  double get _descontoValor =>
      _selectedCustomerDiscount > 0
          ? _subtotalProdutos * _selectedCustomerDiscount / 100
          : 0;

  double get _valorTotal =>
      _subtotalProdutos - _descontoValor + _deslocacao + _subtotalExtras;

  void _recalcDeslocacao() {
    final km        = double.tryParse(_kmCtrl.text.replaceAll(',', '.'))        ?? 0;
    final portagens = double.tryParse(_portagensCtrl.text.replaceAll(',', '.')) ?? 0;

    final custokm     = km * 2 * 0.40;
    final portagensRT = portagens * 2;          // ida + volta
    final horasViagem = (km * 2) / 80;
    _precisaRefeicao  = horasViagem > 4.0;
    _refeicoes        = _precisaRefeicao ? 2 * 15.00 : 0;  // 2 col. × €15
    _deslocacao       = custokm + portagensRT + _refeicoes;

    setState(() {});
  }

  // ── Foto ──────────────────────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, maxHeight: 800, imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _fotoPessoaBytes  = bytes;
        _fotoPessoaBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar a foto')),
        );
      }
    }
  }

  void _removePhoto() => setState(() {
        _fotoPessoaBytes  = null;
        _fotoPessoaBase64 = null;
      });

  // ── Produtos / Extras ─────────────────────────────────────────────────────────
  void _addProduto() => setState(() => _produtos.add(_ProdRow()));
  void _removeProduto(int i) {
    _produtos[i].dispose();
    setState(() => _produtos.removeAt(i));
  }

  void _addExtra() => setState(() => _extras.add(_ExtraRow()));
  void _removeExtra(int i) {
    _extras[i].dispose();
    setState(() => _extras.removeAt(i));
  }

  // ── Guardar ───────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final produtosJson = _produtos
          .where((r) => r.nomeCtrl.text.trim().isNotEmpty)
          .map((r) => {
                'nome': r.nomeCtrl.text.trim(),
                'qty':  r.qty, 'precoUnit': r.preco, 'total': r.total,
              })
          .toList();

      final extrasJson = _extras
          .where((r) => r.descCtrl.text.trim().isNotEmpty)
          .map((r) => {'descricao': r.descCtrl.text.trim(), 'valor': r.valor})
          .toList();

      final body = <String, dynamic>{
        'trabalho':           _trabalhoCtrl.text.trim(),
        'requerente':         _requerenteCtrl.text.trim(),
        'contacto':           _contactoCtrl.text.trim(),
        'produtos':           produtosJson,
        'extras':             extrasJson,
        'valorSepultura':     _subtotalProdutos,
        'portagens':          (double.tryParse(_portagensCtrl.text.replaceAll(',', '.')) ?? 0) * 2,
        'refeicoes':          _refeicoes,
        'deslocacaoMontagem': _deslocacao,
        'extrasValor':        _subtotalExtras,
        'descontoPerc':       _selectedCustomerDiscount,
        'descontoValor':      _descontoValor,
        'valorTotal':         _valorTotal,
      };

      if (_selectedCustomerId != null) body['customerId'] = _selectedCustomerId;
      if (_kmCtrl.text.trim().isNotEmpty)
        body['km'] = double.tryParse(_kmCtrl.text.replaceAll(',', '.')) ?? 0;
      if (_cemiterioCtrl.text.trim().isNotEmpty)
        body['cemiterio']       = _cemiterioCtrl.text.trim();
      if (_talhaoCtrl.text.trim().isNotEmpty)
        body['talhao']          = _talhaoCtrl.text.trim();
      if (_numeroSepulturaCtrl.text.trim().isNotEmpty)
        body['numeroSepultura'] = _numeroSepulturaCtrl.text.trim();
      if (_fotoPessoaBase64 != null)
        body['fotoPessoa']      = _fotoPessoaBase64;
      if (_nomeFalecidoCtrl.text.trim().isNotEmpty)
        body['nomeFalecido']    = _nomeFalecidoCtrl.text.trim();
      if (_datasFalecidoCtrl.text.trim().isNotEmpty)
        body['datasFalecido']   = _datasFalecidoCtrl.text.trim();
      if (_dedicatoriaCtrl.text.trim().isNotEmpty)
        body['dedicatoria']     = _dedicatoriaCtrl.text.trim();
      if (_observacoesCtrl.text.trim().isNotEmpty)
        body['observacoes']     = _observacoesCtrl.text.trim();

      if (_isEdit) {
        await ref.read(ordersProvider.notifier).updateOrder(widget.initialOrder!.id, body);
        ref.invalidate(orderDetailProvider(widget.initialOrder!.id));
      } else {
        await ref.read(ordersProvider.notifier).createOrder(body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Encomenda atualizada!' : 'Encomenda criada!'),
          backgroundColor: AppTheme.success,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? 'Editar ${widget.initialOrder!.orderNumber}'
            : 'Nova Encomenda'),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [

            // ═══════════════════════════════════════
            // 1. CLIENTE
            // ═══════════════════════════════════════
            _section(Icons.business_outlined, 'Cliente', optional: true),
            customersState.isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    decoration: _deco('Associar cliente', Icons.business_outlined),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Nenhum —')),
                      ...customersState.customers.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) {
                      final customer = v == null
                          ? null
                          : customersState.customers
                              .where((c) => c.id == v)
                              .firstOrNull;
                      setState(() {
                        _selectedCustomerId       = v;
                        _selectedCustomerDiscount = customer?.discount ?? 0;
                      });
                    },
                  ),

            // ═══════════════════════════════════════
            // 2. TRABALHO
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.construction, 'Trabalho'),
            _field(
              ctrl: _trabalhoCtrl,
              label: 'Descrição do trabalho *',
              icon: Icons.description_outlined,
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),

            // ═══════════════════════════════════════
            // 3. CEMITÉRIO
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.location_on_outlined, 'Cemitério', optional: true),
            _field(
              ctrl: _cemiterioCtrl,
              label: 'Nome do cemitério',
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(
                ctrl: _talhaoCtrl,
                label: 'Letra/Nº talhão',
                icon: Icons.grid_on_outlined,
              )),
              const SizedBox(width: 10),
              Expanded(child: _field(
                ctrl: _numeroSepulturaCtrl,
                label: 'Nº sepultura',
                icon: Icons.tag,
              )),
            ]),

            // ═══════════════════════════════════════
            // 4. FALECIDO(A)
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.person, 'Falecido(a)', optional: true),

            // Foto
            Center(
              child: Stack(children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppTheme.border,
                  backgroundImage: _fotoPessoaBytes != null
                      ? MemoryImage(_fotoPessoaBytes!) : null,
                  child: _fotoPessoaBytes == null
                      ? const Icon(Icons.person, size: 44,
                          color: AppTheme.textMuted) : null,
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: GestureDetector(
                    onTap: _fotoPessoaBytes != null ? _removePhoto : _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _fotoPessoaBytes != null
                            ? AppTheme.error : AppTheme.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        _fotoPessoaBytes != null
                            ? Icons.close : Icons.add_a_photo,
                        size: 14, color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Carregar foto',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 10),

            _field(
              ctrl: _nomeFalecidoCtrl,
              label: 'Nome do(a) falecido(a)',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 10),
            _field(
              ctrl: _datasFalecidoCtrl,
              label: 'Datas (ex: 01/01/1950 – 15/03/2026)',
              icon: Icons.date_range_outlined,
            ),
            const SizedBox(height: 10),
            _field(
              ctrl: _dedicatoriaCtrl,
              label: 'Dedicatória / Epitáfio',
              icon: Icons.format_quote_outlined,
              maxLines: 3,
            ),

            // ═══════════════════════════════════════
            // 5. PRODUTOS
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.inventory_2_outlined, 'Produtos'),

            ..._produtos.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  elevation: 0,
                  color: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: r.nomeCtrl,
                            decoration: _deco('Nome do produto',
                                Icons.label_outline),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_produtos.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeProduto(i),
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: r.qtyCtrl,
                            decoration: _deco('Qtd', Icons.numbers),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: r.precoCtrl,
                            decoration:
                                _deco('Preço unit. (€)', Icons.euro_outlined),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.goldFaint,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              _currency.format(r.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                  fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),
              );
            }),

            OutlinedButton.icon(
              onPressed: _addProduto,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar produto'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44)),
            ),
            if (_subtotalProdutos > 0) ...[
              const SizedBox(height: 10),
              _totalRow('Subtotal produtos', _subtotalProdutos,
                  highlight: false),
            ],

            // ═══════════════════════════════════════
            // 6. DESLOCAÇÃO E MONTAGEM
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.drive_eta_outlined, 'Deslocação e Montagem'),

            Row(children: [
              Expanded(
                child: _field(
                  ctrl: _kmCtrl,
                  label: 'Km (ida)',
                  icon: Icons.route_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onChanged: (_) => _recalcDeslocacao(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  ctrl: _portagensCtrl,
                  label: 'Portagens (€)',
                  icon: Icons.toll_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onChanged: (_) => _recalcDeslocacao(),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cálculo automático',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success)),
                  const SizedBox(height: 6),
                  _calcRow(
                      'Veículo classe 2  ×  ${(double.tryParse(_kmCtrl.text) ?? 0) * 2} km × €0,40',
                      (double.tryParse(_kmCtrl.text) ?? 0) * 2 * 0.40),
                  _calcRow('Portagens (ida + volta)',
                      (double.tryParse(_portagensCtrl.text.replaceAll(',', '.')) ?? 0) * 2),
                  if (_precisaRefeicao)
                    _calcRow('Refeições (2 colaboradores × €15)', _refeicoes,
                        note: 'viagem > 4h'),
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total deslocação',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_currency.format(_deslocacao),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success)),
                    ],
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════
            // 7. EXTRAS
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.add_circle_outline, 'Extras', optional: true),

            if (_extras.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: const Text('Nenhum extra adicionado',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ),

            ..._extras.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  elevation: 0,
                  color: AppTheme.goldFaint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: r.descCtrl,
                          decoration: _deco('Descrição', Icons.notes),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: r.valorCtrl,
                          decoration: _deco('Valor (€)', Icons.euro_outlined),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _removeExtra(i),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        visualDensity: VisualDensity.compact,
                      ),
                    ]),
                  ),
                ),
              );
            }),

            OutlinedButton.icon(
              onPressed: _addExtra,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar extra'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44)),
            ),

            // ═══════════════════════════════════════
            // 8. REQUERENTE
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.person_outline, 'Requerente'),
            _field(
              ctrl: _requerenteCtrl,
              label: 'Nome do requerente *',
              icon: Icons.person_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 10),
            _field(
              ctrl: _contactoCtrl,
              label: 'Contacto *',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),

            // ═══════════════════════════════════════
            // 9. OBSERVAÇÕES
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.notes_outlined, 'Observações', optional: true),
            _field(
              ctrl: _observacoesCtrl,
              label: 'Observações',
              icon: Icons.notes,
              maxLines: 3,
            ),

            // ═══════════════════════════════════════
            // RESUMO FINANCEIRO
            // ═══════════════════════════════════════
            _gap(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.goldFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(children: [
                _totalRow('Produtos', _subtotalProdutos),
                if (_descontoValor > 0)
                  _totalRow(
                    'Desconto (${_selectedCustomerDiscount % 1 == 0 ? _selectedCustomerDiscount.toInt().toString() : _selectedCustomerDiscount.toStringAsFixed(1)}%)',
                    -_descontoValor,
                    isDiscount: true,
                  ),
                _totalRow('Deslocação / Montagem', _deslocacao),
                if (_subtotalExtras > 0)
                  _totalRow('Extras', _subtotalExtras),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(_currency.format(_valorTotal),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary)),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isEdit ? 'Guardar alterações' : 'Criar encomenda'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────────────

  Widget _gap() => const SizedBox(height: 28);

  Widget _section(IconData icon, String title, {bool optional = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.gold),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          if (optional) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('opcional',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ),
          ],
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ]),
      );

  InputDecoration _deco(String label, IconData icon) =>
      InputDecoration(labelText: label, prefixIcon: Icon(icon));

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller:   ctrl,
        maxLines:     maxLines,
        keyboardType: keyboardType,
        onChanged:    onChanged,
        validator:    validator,
        decoration:   _deco(label, icon),
      );

  Widget _calcRow(String label, double value, {String? note}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                note != null ? '$label ($note)' : label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.success),
              ),
            ),
            Text(
              NumberFormat.currency(locale: 'pt_PT', symbol: '€').format(value),
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.success),
            ),
          ],
        ),
      );

  Widget _totalRow(String label, double value,
          {bool highlight = true, bool isDiscount = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              if (isDiscount) ...[
                const Icon(Icons.discount_outlined,
                    size: 13, color: AppTheme.gold),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: TextStyle(
                      color: isDiscount ? AppTheme.gold : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: isDiscount
                          ? FontWeight.w600 : FontWeight.normal)),
            ]),
            Text(
              '${isDiscount ? '−' : ''}${NumberFormat.currency(locale: 'pt_PT', symbol: '€').format(value.abs())}',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDiscount
                      ? AppTheme.gold
                      : highlight
                          ? AppTheme.primary
                          : AppTheme.textMuted),
            ),
          ],
        ),
      );
}

extension on double {
  double truncate() => truncateToDouble();
}
