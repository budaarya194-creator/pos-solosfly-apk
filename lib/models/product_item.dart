class ProductItem {
  final int? id;
  final String name;
  final double costPrice; // Harga modal / HPP
  final double sellingPrice; // Harga jual
  final int stock;

  ProductItem({
    this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    this.stock = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock': stock,
    };
  }

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    return ProductItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      stock: (map['stock'] as int?) ?? 0,
    );
  }

  ProductItem copyWith({
    int? id,
    String? name,
    double? costPrice,
    double? sellingPrice,
    int? stock,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
    );
  }
}
