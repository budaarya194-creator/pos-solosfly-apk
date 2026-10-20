import 'receipt_item.dart';

class TransactionRecord {
  int? id;
  String invoiceNumber;
  DateTime dateTime;
  String cashierName;
  String customerName;
  String customerPhone;
  String paymentMethod;
  double subtotal;
  double discount;
  double totalAmount;
  double cashPaid;
  double changeAmount;
  double totalCost;
  double grossProfit;
  List<ReceiptItem> items;

  TransactionRecord({
    this.id,
    required this.invoiceNumber,
    required this.dateTime,
    this.cashierName = 'diyah permata',
    this.customerName = 'Pelanggan',
    this.customerPhone = '+62 85xxxx',
    this.paymentMethod = 'Qris',
    required this.subtotal,
    this.discount = 0.0,
    required this.totalAmount,
    required this.cashPaid,
    this.changeAmount = 0.0,
    required this.totalCost,
    required this.grossProfit,
    this.items = const [],
  });

  int get totalItemsCount => items.length;
  int get totalQuantityCount => items.fold(0, (sum, item) => sum + item.qty);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'date_time': dateTime.toIso8601String(),
      'cashier_name': cashierName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
      'subtotal': subtotal,
      'discount': discount,
      'total_amount': totalAmount,
      'cash_paid': cashPaid,
      'change_amount': changeAmount,
      'total_cost': totalCost,
      'gross_profit': grossProfit,
    };
  }

  factory TransactionRecord.fromMap(
    Map<String, dynamic> map, {
    List<ReceiptItem> items = const [],
  }) {
    return TransactionRecord(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      dateTime: DateTime.parse(map['date_time'] as String),
      cashierName: map['cashier_name'] ?? 'diyah permata',
      customerName: map['customer_name'] ?? 'Pelanggan',
      customerPhone: map['customer_phone'] ?? '+62 85xxxx',
      paymentMethod: map['payment_method'] ?? 'Qris',
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      cashPaid: (map['cash_paid'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0.0,
      totalCost: (map['total_cost'] as num).toDouble(),
      grossProfit: (map['gross_profit'] as num).toDouble(),
      items: items,
    );
  }
}
