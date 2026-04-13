class ProductBOMItem {
  final String  id;
  final String  componentName;
  final double  qty;
  final double  includedPrice;
  final int     sortOrder;

  const ProductBOMItem({
    required this.id,
    required this.componentName,
    required this.qty,
    required this.includedPrice,
    required this.sortOrder,
  });

  factory ProductBOMItem.fromJson(Map<String, dynamic> j) => ProductBOMItem(
        id:            j['id']            as String,
        componentName: j['componentName'] as String,
        qty:           (j['qty']          as num).toDouble(),
        includedPrice: (j['includedPrice'] as num).toDouble(),
        sortOrder:     (j['sortOrder']    as num? ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
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
        basePrice:   (j['basePrice'] as num).toDouble(),
        isActive:    j['isActive'] as bool? ?? true,
        bomItems: (j['bomItems'] as List<dynamic>? ?? [])
            .map((e) => ProductBOMItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String? ?? j['createdAt'] as String),
      );
}
