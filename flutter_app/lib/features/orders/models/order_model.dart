class OrderCustomer {
  final String id;
  final String name;
  final String? email;

  const OrderCustomer({required this.id, required this.name, this.email});

  factory OrderCustomer.fromJson(Map<String, dynamic> json) => OrderCustomer(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
      );
}

class OrderCreatedBy {
  final String id;
  final String name;

  const OrderCreatedBy({required this.id, required this.name});

  factory OrderCreatedBy.fromJson(Map<String, dynamic> json) => OrderCreatedBy(
        id: json['id'] as String,
        name: json['name'] as String,
      );
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

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      StatusHistoryEntry(
        id: json['id'] as String,
        status: json['status'] as String,
        changedByName:
            (json['changedBy'] as Map<String, dynamic>)['name'] as String,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

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
  final String? fotoPessoa; // base64
  final String nomeFalecido;
  final String? datasFalecido;

  // Valores
  final double valorSepultura;
  final double? km;
  final double portagens;
  final double deslocacaoMontagem;
  final String? extrasDescricao;
  final double extrasValor;
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
    required this.nomeFalecido,
    this.datasFalecido,
    required this.valorSepultura,
    this.km,
    required this.portagens,
    required this.deslocacaoMontagem,
    this.extrasDescricao,
    required this.extrasValor,
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

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        status: json['status'] as String,
        trabalho: json['trabalho'] as String? ?? '',
        cemiterio: json['cemiterio'] as String?,
        talhao: json['talhao'] as String?,
        numeroSepultura: json['numeroSepultura'] as String?,
        fotoPessoa: json['fotoPessoa'] as String?,
        nomeFalecido: json['nomeFalecido'] as String? ?? '',
        datasFalecido: json['datasFalecido'] as String?,
        valorSepultura: _toDouble(json['valorSepultura']),
        km: json['km'] != null ? (json['km'] as num).toDouble() : null,
        portagens: _toDouble(json['portagens']),
        deslocacaoMontagem: _toDouble(json['deslocacaoMontagem']),
        extrasDescricao: json['extrasDescricao'] as String?,
        extrasValor: _toDouble(json['extrasValor']),
        valorTotal: _toDouble(json['valorTotal']),
        requerente: json['requerente'] as String? ?? '',
        contacto: json['contacto'] as String? ?? '',
        observacoes: json['observacoes'] as String?,
        customer: json['customer'] != null
            ? OrderCustomer.fromJson(
                json['customer'] as Map<String, dynamic>)
            : null,
        createdBy: json['createdBy'] != null
            ? OrderCreatedBy.fromJson(
                json['createdBy'] as Map<String, dynamic>)
            : null,
        statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
            .map((e) =>
                StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(
            json['updatedAt'] as String? ?? json['createdAt'] as String),
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    return double.parse(v.toString());
  }
}
