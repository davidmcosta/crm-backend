class CustomerModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxId;
  final String? notes;
  final int? orderCount;

  const CustomerModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.taxId,
    this.notes,
    this.orderCount,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      taxId: json['taxId'] as String?,
      notes: json['notes'] as String?,
      orderCount: count?['orders'] as int?,
    );
  }
}
