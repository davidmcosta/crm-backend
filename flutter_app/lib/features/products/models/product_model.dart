// Prisma Decimal fields serialise as strings — handle both
double _d(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

class ProductBOMItem {
  final String  id;
  final String? componentProductId;   // referência ao produto do catálogo (opcional)
  final String  componentName;
  final double  qty;
  final double  includedPrice;
  final int     sortOrder;

  const ProductBOMItem({
    required this.id,
    this.componentProductId,
    required this.componentName,
    required this.qty,
    required this.includedPrice,
    required this.sortOrder,
  });

  factory ProductBOMItem.fromJson(Map<String, dynamic> j) => ProductBOMItem(
        id:                 j['id']                 as String,
        componentProductId: j['componentProductId'] as String?,
        componentName:      j['componentName']      as String,
        qty:                _d(j['qty'],           1),
        includedPrice:      _d(j['includedPrice'], 0),
        sortOrder:          (j['sortOrder'] as num? ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        if (componentProductId != null)
          'componentProductId': componentProductId,
        'componentName': componentName,
        'qty':           qty,
        'includedPrice': includedPrice,
        'sortOrder':     sortOrder,
      };
}

class ProductModel {
  final String  id;
  final String  name;
  final String? category;
  final String? description;
  final double  basePrice;
  final bool    isActive;
  final List<ProductBOMItem> bomItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.category,
    this.description,
    required this.basePrice,
    required this.isActive,
    this.bomItems = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id:          j['id']       as String,
        name:        j['name']     as String,
        category:    j['category'] as String?,
        description: j['description'] as String?,
        basePrice:   _d(j['basePrice'], 0),
        isActive:    j['isActive'] as bool? ?? true,
        bomItems: (j['bomItems'] as List<dynamic>? ?? [])
            .map((e) => ProductBOMItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String? ?? j['createdAt'] as String),
      );
}
