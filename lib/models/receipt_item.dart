class ReceiptItem {
  int? id;
  int? transactionId;
  String productName;
  int qty;
  double costPrice; // Modal / HPP per unit (tidak dicetak di struk)
  double sellingPrice; // Harga Jual per unit (dicetak di struk)

  ReceiptItem({
    this.id,
    this.transactionId,
    required this.productName,
    required this.qty,
    required this.costPrice,
    required this.sellingPrice,
  });

  double get subtotal => qty * sellingPrice;
  double get costSubtotal => qty * costPrice;
  double get grossProfit => subtotal - costSubtotal;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_name': productName,
      'qty': qty,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int?,
      productName: map['product_name'] as String,
      qty: (map['qty'] as num).toInt(),
      costPrice: (map['cost_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
    );
  }

  ReceiptItem copyWith({
    int? id,
    int? transactionId,
    String? productName,
    int? qty,
    double? costPrice,
    double? sellingPrice,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productName: productName ?? this.productName,
      qty: qty ?? this.qty,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
    );
  }
}
