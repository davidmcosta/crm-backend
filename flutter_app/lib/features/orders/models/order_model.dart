class OrderItem {
  final String id;
  final String productName;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.productName,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        productName: json['productName'] as String,
        description: json['description'] as String?,
        quantity: json['quantity'] as int,
        unitPrice: double.parse(json['unitPrice'].toString()),
        totalPrice: double.parse(json['totalPrice'].toString()),
      );
}

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
  final double totalAmount;
  final String? notes;
  final DateTime? expectedDate;
  final DateTime createdAt;
  final OrderCustomer? customer;
  final OrderCreatedBy? createdBy;
  final List<OrderItem> items;
  final List<StatusHistoryEntry> statusHistory;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.expectedDate,
    required this.createdAt,
    this.customer,
    this.createdBy,
    this.items = const [],
    this.statusHistory = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        status: json['status'] as String,
        totalAmount: double.parse(json['totalAmount'].toString()),
        notes: json['notes'] as String?,
        expectedDate: json['expectedDate'] != null
            ? DateTime.parse(json['expectedDate'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        customer: json['customer'] != null
            ? OrderCustomer.fromJson(
                json['customer'] as Map<String, dynamic>)
            : null,
        createdBy: json['createdBy'] != null
            ? OrderCreatedBy.fromJson(
                json['createdBy'] as Map<String, dynamic>)
            : null,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
            .map((e) =>
                StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
