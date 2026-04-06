// ── Produto ──────────────────────────────────────────────────────────────────

class ProdutoItem {
  final String nome;
  final double qty;
  final double precoUnit;
  final double total;

  const ProdutoItem({
    required this.nome,
    required this.qty,
    required this.precoUnit,
    required this.total,
  });

  factory ProdutoItem.fromJson(Map<String, dynamic> j) => ProdutoItem(
        nome:      j['nome']      as String,
        qty:       (j['qty']       as num).toDouble(),
        precoUnit: (j['precoUnit'] as num).toDouble(),
        total:     (j['total']     as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'nome': nome, 'qty': qty, 'precoUnit': precoUnit, 'total': total,
      };
}

// ── Extra ─────────────────────────────────────────────────────────────────────

class ExtraItem {
  final String descricao;
  final double valor;

  const ExtraItem({required this.descricao, required this.valor});

  factory ExtraItem.fromJson(Map<String, dynamic> j) => ExtraItem(
        descricao: j['descricao'] as String,
        valor:     (j['valor']    as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'descricao': descricao, 'valor': valor};
}

// ── Sub-modelos ───────────────────────────────────────────────────────────────

class OrderCustomer {
  final String id;
  final String name;
  final String? email;

  const OrderCustomer({required this.id, required this.name, this.email});

  factory OrderCustomer.fromJson(Map<String, dynamic> j) => OrderCustomer(
        id:    j['id']    as String,
        name:  j['name']  as String,
        email: j['email'] as String?,
      );
}

class OrderCreatedBy {
  final String id;
  final String name;

  const OrderCreatedBy({required this.id, required this.name});

  factory OrderCreatedBy.fromJson(Map<String, dynamic> j) =>
      OrderCreatedBy(id: j['id'] as String, name: j['name'] as String);
}

class StatusHistoryEntry {
  final String id;
  final String status;
  final String changedByName;
  final String? notes;
  final DateTime createdAt;

  const StatusHistoryEntry({
    required this.id,
    required this.status,
    required this.changedByName,
    this.notes,
    required this.createdAt,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> j) =>
      StatusHistoryEntry(
        id:            j['id']     as String,
        status:        j['status'] as String,
        changedByName: (j['changedBy'] as Map<String, dynamic>)['name'] as String,
        notes:         j['notes']  as String?,
        createdAt:     DateTime.parse(j['createdAt'] as String),
      );
}

// ── Modelo principal ──────────────────────────────────────────────────────────

class OrderModel {
  final String id;
  final String orderNumber;
  final String status;

  // Trabalho
  final String trabalho;

  // Cemitério
  final String? cemiterio;
  final String? talhao;
  final String? numeroSepultura;

  // Falecido
  final String? fotoPessoa;
  final String? nomeFalecido;
  final String? datasFalecido;
  final String? dedicatoria;

  // Produtos
  final List<ProdutoItem> produtos;

  // Valores
  final double valorSepultura;   // subtotal produtos
  final double? km;
  final double portagens;
  final double refeicoes;
  final double deslocacaoMontagem;
  final List<ExtraItem> extras;
  final double valorTotal;

  // Requerente
  final String requerente;
  final String contacto;
  final String? observacoes;

  // Relações
  final OrderCustomer? customer;
  final OrderCreatedBy? createdBy;
  final List<StatusHistoryEntry> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.trabalho,
    this.cemiterio,
    this.talhao,
    this.numeroSepultura,
    this.fotoPessoa,
    this.nomeFalecido,
    this.datasFalecido,
    this.dedicatoria,
    this.produtos = const [],
    required this.valorSepultura,
    this.km,
    required this.portagens,
    required this.refeicoes,
    required this.deslocacaoMontagem,
    this.extras = const [],
    required this.valorTotal,
    required this.requerente,
    required this.contacto,
    this.observacoes,
    this.customer,
    this.createdBy,
    this.statusHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  double get extrasValor => extras.fold(0.0, (s, e) => s + e.valor);

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id:          j['id']          as String,
        orderNumber: j['orderNumber'] as String,
        status:      j['status']      as String,
        trabalho:    j['trabalho']    as String? ?? '',
        cemiterio:       j['cemiterio']       as String?,
        talhao:          j['talhao']          as String?,
        numeroSepultura: j['numeroSepultura'] as String?,
        fotoPessoa:      j['fotoPessoa']      as String?,
        nomeFalecido:    j['nomeFalecido']    as String?,
        datasFalecido:   j['datasFalecido']   as String?,
        dedicatoria:     j['dedicatoria']     as String?,
        produtos: (j['produtos'] as List<dynamic>? ?? [])
            .map((e) => ProdutoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        extras: (j['extras'] as List<dynamic>? ?? [])
            .map((e) => ExtraItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        valorSepultura:    _d(j['valorSepultura']),
        km: j['km'] != null ? (j['km'] as num).toDouble() : null,
        portagens:         _d(j['portagens']),
        refeicoes:         _d(j['refeicoes']),
        deslocacaoMontagem: _d(j['deslocacaoMontagem']),
        valorTotal:        _d(j['valorTotal']),
        requerente:  j['requerente'] as String? ?? '',
        contacto:    j['contacto']   as String? ?? '',
        observacoes: j['observacoes'] as String?,
        customer:  j['customer']  != null
            ? OrderCustomer.fromJson(j['customer']  as Map<String, dynamic>) : null,
        createdBy: j['createdBy'] != null
            ? OrderCreatedBy.fromJson(j['createdBy'] as Map<String, dynamic>) : null,
        statusHistory: (j['statusHistory'] as List<dynamic>? ?? [])
            .map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(
            j['updatedAt'] as String? ?? j['createdAt'] as String),
      );

  static double _d(dynamic v) =>
      v == null ? 0.0 : double.parse(v.toString());
}
