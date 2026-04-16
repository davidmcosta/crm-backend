import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../customers/models/customer_model.dart';
import '../../products/screens/product_picker_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/providers/settings_provider.dart';

// ── Falecido entry ────────────────────────────────────────────────────────────

class _FalecidoEntry {
  final nomeCtrl        = TextEditingController();
  final datasCtrl       = TextEditingController();
  final dedicatoriaCtrl = TextEditingController();
  List<String>    fotosBase64 = [];
  List<Uint8List> fotosBytes  = [];

  void dispose() {
    nomeCtrl.dispose();
    datasCtrl.dispose();
    dedicatoriaCtrl.dispose();
  }

  FalecidoItem toItem() => FalecidoItem(
        nome:        nomeCtrl.text.trim().isEmpty  ? null : nomeCtrl.text.trim(),
        datas:       datasCtrl.text.trim().isEmpty ? null : datasCtrl.text.trim(),
        dedicatoria: dedicatoriaCtrl.text.trim().isEmpty ? null : dedicatoriaCtrl.text.trim(),
        fotos:       fotosBase64,
      );
}

// ── Linha de produto ──────────────────────────────────────────────────────────

class _ProdRow {
  final nomeCtrl  = TextEditingController();
  final qtyCtrl   = TextEditingController(text: '1');
  final precoCtrl = TextEditingController(text: '0,00');

  /// Identificador do grupo do catálogo (null = linha manual)
  String? groupId;
  /// Nome do produto principal do grupo (para o cabeçalho)
  String? groupLabel;
  /// Se é a primeira linha do grupo (mostra cabeçalho)
  bool isGroupStart = false;

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
  final _kmCtrl              = TextEditingController();
  final _portagensCtrl       = TextEditingController(text: '0');
  final _requerenteCtrl      = TextEditingController();
  final _contactoCtrl        = TextEditingController();
  final _observacoesCtrl     = TextEditingController();

  String?              _selectedCustomerId;
  String?              _selectedCustomerName;
  double               _selectedCustomerDiscount = 0;

  bool get _isCasaDasCampas =>
      _selectedCustomerName?.toLowerCase().contains('casa das campas') == true;
  bool                 _temIVA                   = false;
  List<_FalecidoEntry> _falecidos                = [_FalecidoEntry()];
  List<_ProdRow>  _produtos = [_ProdRow()];
  List<_ExtraRow> _extras   = [];

  // Calculados
  double _refeicoes        = 0;
  double _deslocacao       = 0;
  bool   _precisaRefeicao  = false;
  double _kmRateCurrent    = 0.40;
  double _mealCostCurrent  = 15.0;

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
    _kmCtrl.text              = o.km?.toString()  ?? '';
    _portagensCtrl.text       = o.portagens.toStringAsFixed(2);
    _requerenteCtrl.text      = o.requerente;
    _contactoCtrl.text        = o.contacto;
    _observacoesCtrl.text     = o.observacoes ?? '';
    _selectedCustomerId       = o.customer?.id;
    _selectedCustomerName     = o.customer?.name;
    _selectedCustomerDiscount = o.descontoPerc;
    _temIVA                   = o.ivaPerc > 0;

    if (o.falecidos.isNotEmpty) {
      _falecidos = o.falecidos.map((f) {
        final e = _FalecidoEntry();
        e.nomeCtrl.text        = f.nome        ?? '';
        e.datasCtrl.text       = f.datas       ?? '';
        e.dedicatoriaCtrl.text = f.dedicatoria ?? '';
        e.fotosBase64 = List<String>.from(f.fotos);
        e.fotosBytes  = f.fotos.map((s) {
          final b64 = s.contains(',') ? s.split(',').last : s;
          return base64Decode(b64);
        }).toList();
        return e;
      }).toList();
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
    _kmCtrl.dispose();
    _portagensCtrl.dispose();
    _requerenteCtrl.dispose();
    _contactoCtrl.dispose();
    _observacoesCtrl.dispose();
    for (final r in _falecidos) r.dispose();
    for (final r in _produtos)  r.dispose();
    for (final r in _extras)    r.dispose();
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

  double get _baseIVA =>
      _subtotalProdutos - _descontoValor + _deslocacao + _subtotalExtras;

  double get _ivaValor => _temIVA ? _baseIVA * 0.23 : 0;

  double get _valorTotal => _baseIVA + _ivaValor;

  void _recalcDeslocacao({double kmRate = 0.40, double mealCost = 15.0}) {
    final km        = double.tryParse(_kmCtrl.text.replaceAll(',', '.'))        ?? 0;
    final portagens = double.tryParse(_portagensCtrl.text.replaceAll(',', '.')) ?? 0;

    final custokm     = km * 2 * kmRate;
    final portagensRT = portagens * 2;          // ida + volta
    final horasViagem = (km * 2) / 80;
    _precisaRefeicao  = horasViagem > 4.0;
    _refeicoes        = _precisaRefeicao ? 2 * mealCost : 0;  // 2 col. × mealCost
    _deslocacao       = custokm + portagensRT + _refeicoes;
    _kmRateCurrent    = kmRate;
    _mealCostCurrent  = mealCost;

    setState(() {});
  }

  // ── Fotos de falecidos ────────────────────────────────────────────────────────
  Future<void> _addFotoFalecido(int falecidoIndex) async {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    ImageSource? source = ImageSource.gallery;
    if (!isDesktop) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Câmara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Biblioteca de fotos'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;
    }
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 900, maxHeight: 900, imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _falecidos[falecidoIndex].fotosBytes.add(bytes);
        _falecidos[falecidoIndex].fotosBase64
            .add('data:image/jpeg;base64,${base64Encode(bytes)}');
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar a foto')),
        );
      }
    }
  }

  void _removeFotoFalecido(int falecidoIndex, int fotoIndex) =>
      setState(() {
        _falecidos[falecidoIndex].fotosBytes.removeAt(fotoIndex);
        _falecidos[falecidoIndex].fotosBase64.removeAt(fotoIndex);
      });

  // ── Produtos / Extras ─────────────────────────────────────────────────────────
  void _addProduto() => setState(() => _produtos.add(_ProdRow()));
  void _removeProduto(int i) {
    _produtos[i].dispose();
    setState(() => _produtos.removeAt(i));
  }

  Future<void> _addFromCatalog() async {
    final result = await showProductPickerDialog(context);
    if (result == null) return;
    final rows = productPickResultToRows(result);
    setState(() {
      // Remove the single empty row if it's the only one
      if (_produtos.length == 1 &&
          _produtos[0].nomeCtrl.text.isEmpty &&
          _produtos[0].qtyCtrl.text == '1' &&
          _produtos[0].precoCtrl.text == '0,00') {
        _produtos[0].dispose();
        _produtos.clear();
      }
      // Unique group ID based on timestamp + group label
      final groupId = '${DateTime.now().millisecondsSinceEpoch}';
      bool isFirst = true;
      for (final r in rows) {
        final row = _ProdRow();
        final qty   = r['qty']      as double;
        final preco = r['precoUnit'] as double;
        row.nomeCtrl.text  = r['nome'] as String;
        row.qtyCtrl.text   = qty  == qty.truncateToDouble()
            ? qty.toInt().toString()
            : qty.toString();
        row.precoCtrl.text = preco == preco.truncateToDouble()
            ? preco.toInt().toString()
            : preco.toStringAsFixed(2);
        row.groupId     = groupId;
        row.groupLabel  = result.groupLabel;
        row.isGroupStart = isFirst;
        isFirst = false;
        _produtos.add(row);
      }
    });
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
        'ivaPerc':            _temIVA ? 23.0 : 0.0,
        'ivaValor':           _ivaValor,
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
      final falecidosJson = _falecidos
          .map((e) => e.toItem())
          .where((f) => !f.isEmpty)
          .map((f) => f.toJson())
          .toList();
      body['falecidos']    = falecidosJson;
      // legado — primeiro falecido
      if (falecidosJson.isNotEmpty) {
        final first = _falecidos.first;
        body['fotosPessoa'] = first.fotosBase64;
        if (first.fotosBase64.isNotEmpty)
          body['fotoPessoa'] = first.fotosBase64.first;
      }
      // campos legados do primeiro falecido
      if (_falecidos.isNotEmpty) {
        final first = _falecidos.first;
        if (first.nomeCtrl.text.trim().isNotEmpty)
          body['nomeFalecido']  = first.nomeCtrl.text.trim();
        if (first.datasCtrl.text.trim().isNotEmpty)
          body['datasFalecido'] = first.datasCtrl.text.trim();
        if (first.dedicatoriaCtrl.text.trim().isNotEmpty)
          body['dedicatoria']   = first.dedicatoriaCtrl.text.trim();
      }
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
    final customersState  = ref.watch(customersProvider);
    // Apply settings-based travel rates whenever settings load/change
    ref.watch(settingsProvider).whenData((s) {
      if (s.kmRate != _kmRateCurrent || s.mealCost != _mealCostCurrent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _recalcDeslocacao(kmRate: s.kmRate, mealCost: s.mealCost);
        });
      }
    });

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
            _section(Icons.business_outlined, 'Cliente'),
            customersState.isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _CustomerAutocomplete(
                    customers:    customersState.customers,
                    selectedId:   _selectedCustomerId,
                    selectedName: _selectedCustomerName,
                    isEdit:       _isEdit,
                    onSelected: (c) => setState(() {
                      _selectedCustomerId       = c?.id;
                      _selectedCustomerName     = c?.name;
                      _selectedCustomerDiscount = c?.discount ?? 0;
                    }),
                    onAutoSelected: (c) {
                      if (_selectedCustomerId == null) {
                        setState(() {
                          _selectedCustomerId       = c.id;
                          _selectedCustomerName     = c.name;
                          _selectedCustomerDiscount = c.discount;
                        });
                      }
                    },
                    validator: (_) =>
                        _selectedCustomerId == null ? 'Cliente obrigatório' : null,
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
            // 4. FALECIDO(S)
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.person, 'Falecido(s)', optional: true),

            ..._falecidos.asMap().entries.map((entry) {
              final fi = entry.key;
              final fe = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 0,
                  color: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // cabeçalho com número e botão de remover
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Falecido ${fi + 1}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gold)),
                          ),
                          const Spacer(),
                          if (_falecidos.length > 1)
                            IconButton(
                              onPressed: () => setState(
                                  () { fe.dispose(); _falecidos.removeAt(fi); }),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.error, size: 20),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                        ]),
                        const SizedBox(height: 10),

                        // fotos
                        if (fe.fotosBytes.isNotEmpty) ...[
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: fe.fotosBytes.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, pi) {
                                if (pi == fe.fotosBytes.length) {
                                  return GestureDetector(
                                    onTap: () => _addFotoFalecido(fi),
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldFaint,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppTheme.gold),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo,
                                              color: AppTheme.gold,
                                              size: 20),
                                          SizedBox(height: 3),
                                          Text('Adicionar',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.gold)),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return Stack(children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    child: Image.memory(
                                      fe.fotosBytes[pi],
                                      width: 80, height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 3, right: 3,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _removeFotoFalecido(fi, pi),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.error,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white,
                                              width: 1.5),
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 10,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ]);
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: () => _addFotoFalecido(fi),
                            icon: const Icon(Icons.add_a_photo, size: 16),
                            label: const Text('Carregar foto(s)',
                                style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40)),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // campos de texto
                        TextFormField(
                          controller: fe.nomeCtrl,
                          decoration:
                              _deco('Nome do(a) falecido(a)', Icons.badge_outlined),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: fe.datasCtrl,
                          decoration: _deco(
                              'Datas (ex: 01/01/1950 – 15/03/2026)',
                              Icons.date_range_outlined),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: fe.dedicatoriaCtrl,
                          maxLines: 3,
                          decoration: _deco(
                              'Dedicatória / Epitáfio',
                              Icons.format_quote_outlined),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            if (_falecidos.length < 5)
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _falecidos.add(_FalecidoEntry())),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Adicionar outro falecido'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44)),
              ),

            // ═══════════════════════════════════════
            // 5. PRODUTOS
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.inventory_2_outlined, 'Produtos'),

            ..._produtos.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              // Is this row part of a catalog group?
              final isCatalog = r.groupId != null;
              final cardColor = isCatalog
                  ? AppTheme.goldFaint.withOpacity(0.5)
                  : AppTheme.surface;
              final borderColor = isCatalog ? AppTheme.gold.withOpacity(0.4) : AppTheme.border;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group header shown on first row of group
                  if (r.isGroupStart && r.groupLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Row(children: [
                        const Icon(Icons.category_outlined,
                            size: 13, color: AppTheme.gold),
                        const SizedBox(width: 6),
                        Text(
                          r.groupLabel!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Divider(
                              color: AppTheme.border, height: 1),
                        ),
                      ]),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Card(
                      elevation: 0,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          Row(children: [
                            if (isCatalog && !r.isGroupStart)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.subdirectory_arrow_right,
                                    size: 14,
                                    color: AppTheme.gold.withOpacity(0.7)),
                              ),
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
                  ),
                ],
              );
            }),

            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addProduto,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar linha'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addFromCatalog,
                  icon: const Icon(Icons.category_outlined, size: 18),
                  label: const Text('Do catálogo'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ]),
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
                      'Veículo  ×  ${(double.tryParse(_kmCtrl.text) ?? 0) * 2} km × €${_kmRateCurrent.toStringAsFixed(2)}',
                      (double.tryParse(_kmCtrl.text) ?? 0) * 2 * _kmRateCurrent),
                  _calcRow('Portagens (ida + volta)',
                      (double.tryParse(_portagensCtrl.text.replaceAll(',', '.')) ?? 0) * 2),
                  if (_precisaRefeicao)
                    _calcRow('Refeições (2 col. × €${_mealCostCurrent.toStringAsFixed(2)})', _refeicoes,
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
            // 8. REQUERENTE (só para Casa das Campas)
            // ═══════════════════════════════════════
            if (_isCasaDasCampas) ...[
              _gap(),
              _section(Icons.person_outline, 'Requerente'),
              _field(
                ctrl: _requerenteCtrl,
                label: 'Nome do requerente *',
                icon: Icons.person_outlined,
                validator: (v) =>
                    _isCasaDasCampas && (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório'
                        : null,
              ),
              const SizedBox(height: 10),
              _field(
                ctrl: _contactoCtrl,
                label: 'Contacto *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    _isCasaDasCampas && (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório'
                        : null,
              ),
            ],

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
            // IVA
            // ═══════════════════════════════════════
            _gap(),
            _section(Icons.receipt_long_outlined, 'Faturação / IVA'),
            Container(
              decoration: BoxDecoration(
                color: _temIVA
                    ? const Color(0xFF1565C0).withOpacity(0.06)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _temIVA
                      ? const Color(0xFF1565C0).withOpacity(0.35)
                      : AppTheme.border,
                ),
              ),
              child: SwitchListTile(
                value: _temIVA,
                onChanged: (v) => setState(() => _temIVA = v),
                title: const Text('Fatura com IVA',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _temIVA
                      ? 'IVA à taxa normal (23%) incluído no total'
                      : 'Encomenda isenta de IVA',
                  style: TextStyle(
                    fontSize: 12,
                    color: _temIVA
                        ? const Color(0xFF1565C0)
                        : AppTheme.textMuted,
                  ),
                ),
                activeColor: const Color(0xFF1565C0),
                secondary: Icon(
                  _temIVA ? Icons.receipt_long : Icons.receipt_long_outlined,
                  color: _temIVA
                      ? const Color(0xFF1565C0)
                      : AppTheme.textMuted,
                ),
              ),
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
                if (_temIVA) ...[
                  const Divider(height: 12),
                  _totalRow('Subtotal (sem IVA)', _baseIVA, highlight: false),
                  _totalRow('IVA (23%)', _ivaValor, isIva: true),
                ],
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
          {bool highlight = true, bool isDiscount = false, bool isIva = false}) {
    const ivaColor = Color(0xFF1565C0);
    final color = isDiscount
        ? AppTheme.gold
        : isIva
            ? ivaColor
            : highlight
                ? AppTheme.primary
                : AppTheme.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(children: [
              if (isDiscount) ...[
                const Icon(Icons.discount_outlined,
                    size: 13, color: AppTheme.gold),
                const SizedBox(width: 4),
              ],
              if (isIva) ...[
                const Icon(Icons.receipt_long_outlined,
                    size: 13, color: ivaColor),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: (isDiscount || isIva)
                            ? FontWeight.w600 : FontWeight.normal),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Text(
            '${isDiscount ? '−' : ''}${NumberFormat.currency(locale: 'pt_PT', symbol: '€').format(value.abs())}',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color),
          ),
        ],
      ),
    );
  }
}

extension on double {
  double truncate() => truncateToDouble();
}

// ── Autocomplete de cliente ───────────────────────────────────────────────────

class _CustomerAutocomplete extends StatefulWidget {
  final List<CustomerModel>           customers;
  final String?                       selectedId;
  final String?                       selectedName;
  final bool                          isEdit;
  final void Function(CustomerModel?) onSelected;
  final void Function(CustomerModel)  onAutoSelected;
  final String? Function(String?)     validator;

  const _CustomerAutocomplete({
    required this.customers,
    required this.selectedId,
    required this.selectedName,
    required this.isEdit,
    required this.onSelected,
    required this.onAutoSelected,
    required this.validator,
  });

  @override
  State<_CustomerAutocomplete> createState() => _CustomerAutocompleteState();
}

class _CustomerAutocompleteState extends State<_CustomerAutocomplete> {
  final _ctrl       = TextEditingController();
  final _focusNode  = FocusNode();
  bool  _autoSet    = false;

  @override
  void initState() {
    super.initState();
    // Se estamos em edição e já há cliente, pré-preencher o campo
    if (widget.selectedName != null) {
      _ctrl.text = widget.selectedName!;
      _autoSet   = true;
    }
  }

  @override
  void didUpdateWidget(_CustomerAutocomplete old) {
    super.didUpdateWidget(old);
    // Auto-selecionar "Casa das Campas" quando os clientes carregam (nova encomenda)
    if (!widget.isEdit && !_autoSet && widget.customers.isNotEmpty) {
      _autoSet = true;
      final casaDasCampas = widget.customers.firstWhere(
        (c) => c.name.toLowerCase().contains('casa das campas'),
        orElse: () => widget.customers.first,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ctrl.text = casaDasCampas.name;
        widget.onAutoSelected(casaDasCampas);
      });
    }
    // Sincronizar texto quando o selectedName muda externamente (ex: prefill em edição)
    if (widget.selectedName != null && _ctrl.text != widget.selectedName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ctrl.text = widget.selectedName!;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<CustomerModel> get _filtered {
    final q = _ctrl.text.toLowerCase();
    if (q.isEmpty) return widget.customers;
    return widget.customers
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<CustomerModel>(
      textEditingController: _ctrl,
      focusNode: _focusNode,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (_) => _filtered,
      onSelected: (c) {
        _ctrl.text = c.name;
        widget.onSelected(c);
      },
      fieldViewBuilder: (ctx, ctrl, fn, onSubmit) => TextFormField(
        controller: ctrl,
        focusNode: fn,
        decoration: InputDecoration(
          labelText: 'Cliente *',
          prefixIcon: const Icon(Icons.business_outlined),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    ctrl.clear();
                    widget.onSelected(null);
                    fn.requestFocus();
                  },
                )
              : const Icon(Icons.search, size: 18,
                  color: AppTheme.textMuted),
        ),
        validator: widget.validator,
        onChanged: (_) => setState(() {}),
      ),
      optionsViewBuilder: (ctx, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          color: AppTheme.cardColor,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 420),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (ctx, i) {
                final c = options.elementAt(i);
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(c.name[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(fontSize: 14)),
                  subtitle: c.isReseller
                      ? Text(
                          'Revendedor · ${c.discount.toStringAsFixed(0)}% desconto',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted))
                      : null,
                  onTap: () => onSelected(c),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
