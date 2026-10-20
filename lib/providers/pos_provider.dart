import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_profile.dart';
import '../models/product_item.dart';
import '../models/receipt_item.dart';
import '../models/transaction_record.dart';
import '../database/database_helper.dart';

enum ReportFilter { today, week, month, year, custom }

class PosProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // --- STORE PROFILE ---
  StoreProfile _storeProfile = StoreProfile();
  Uint8List? _customLogoBytes;
  StoreProfile get storeProfile => _storeProfile;
  Uint8List? get customLogoBytes => _customLogoBytes;

  // --- PRODUCTS ---
  List<ProductItem> _products = [];
  List<ProductItem> get products => _products;

  // --- CURRENT TRANSACTION DRAFT (KASIR) ---
  int? _editingTransactionId;
  String _invoiceNumber = 'TRX-261020130359';
  DateTime _dateTime = DateTime(2026, 10, 20, 13, 3);
  String _cashierName = 'diyah permata';
  String _customerName = 'Pelanggan';
  String _customerPhone = '+62 85xxxx';
  String _paymentMethod = 'Qris';
  double _discount = 0.0;
  double _cashPaid = 645000.0;
  bool _isManualOverride = false;
  double _overrideTotal = 645000.0;

  List<ReceiptItem> _currentItems = [];

  int? get editingTransactionId => _editingTransactionId;
  String get invoiceNumber => _invoiceNumber;
  DateTime get dateTime => _dateTime;
  String get cashierName => _cashierName;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get paymentMethod => _paymentMethod;
  double get discount => _discount;
  double get cashPaid => _cashPaid;
  bool get isManualOverride => _isManualOverride;
  double get overrideTotal => _overrideTotal;
  List<ReceiptItem> get currentItems => _currentItems;

  // Calculations
  double get subtotal => _currentItems.fold(0.0, (sum, it) => sum + it.subtotal);
  double get totalCost => _currentItems.fold(0.0, (sum, it) => sum + it.costSubtotal);
  double get totalAmount => _isManualOverride ? _overrideTotal : (subtotal - _discount);
  double get changeAmount => _cashPaid >= totalAmount ? (_cashPaid - totalAmount) : 0.0;
  double get grossProfit => totalAmount - totalCost;
  int get totalItemsCount => _currentItems.length;
  int get totalQuantityCount => _currentItems.fold(0, (sum, it) => sum + it.qty);

  // --- TRANSACTIONS HISTORY ---
  List<TransactionRecord> _transactions = [];
  List<TransactionRecord> get transactions => _transactions;

  // --- FINANCIAL REPORT & ANALYTICS ---
  ReportFilter _currentFilter = ReportFilter.today;
  DateTimeRange? _customDateRange;
  double _operationalExpense = 0.0;

  ReportFilter get currentFilter => _currentFilter;
  DateTimeRange? get customDateRange => _customDateRange;
  double get operationalExpense => _operationalExpense;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  PosProvider() {
    _initData();
  }

  Future<void> _initData() async {
    _isLoading = true;
    notifyListeners();

    await _loadStoreProfile();
    await loadProducts();
    await loadTransactions();
    _initDefaultDraft();

    _isLoading = false;
    notifyListeners();
  }

  void _initDefaultDraft() {
    _editingTransactionId = null;
    _invoiceNumber = 'TRX-261020130359';
    _dateTime = DateTime(2026, 10, 20, 13, 3);
    _cashierName = 'diyah permata';
    _customerName = 'Pelanggan';
    _customerPhone = '+62 85xxxx';
    _paymentMethod = 'Qris';
    _discount = 0.0;
    _isManualOverride = false;

    _currentItems = [
      ReceiptItem(
        productName: 'Tumbler Mix Miniso/stbc',
        qty: 13,
        costPrice: 30000.0,
        sellingPrice: 40000.0,
      ),
      ReceiptItem(
        productName: 'Viona Blouse',
        qty: 1,
        costPrice: 30000.0,
        sellingPrice: 45000.0,
      ),
      ReceiptItem(
        productName: 'Catok Curly Mangoman',
        qty: 1,
        costPrice: 55000.0,
        sellingPrice: 80000.0,
      ),
    ];

    _cashPaid = subtotal;
    _overrideTotal = subtotal;
  }

  // --- STORE PROFILE PERSISTENCE ---
  Future<void> _loadStoreProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString('store_profile');
    if (profileStr != null) {
      try {
        final map = jsonDecode(profileStr) as Map<String, dynamic>;
        _storeProfile = StoreProfile.fromMap(map);
      } catch (_) {}
    }
    final logoBase64 = prefs.getString('store_logo_base64');
    if (logoBase64 != null) {
      try {
        _customLogoBytes = base64Decode(logoBase64);
      } catch (_) {}
    }
  }

  Future<void> updateStoreProfile(StoreProfile newProfile) async {
    _storeProfile = newProfile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_profile', jsonEncode(_storeProfile.toMap()));
    notifyListeners();
  }

  Future<void> setCustomLogo(Uint8List? bytes) async {
    _customLogoBytes = bytes;
    final prefs = await SharedPreferences.getInstance();
    if (bytes != null) {
      await prefs.setString('store_logo_base64', base64Encode(bytes));
    } else {
      await prefs.remove('store_logo_base64');
    }
    notifyListeners();
  }

  void updateLogoSize(double size) {
    _storeProfile.logoSize = size;
    updateStoreProfile(_storeProfile);
  }

  // --- PRODUCTS CRUD ---
  Future<void> loadProducts() async {
    _products = await _db.getProducts();
    notifyListeners();
  }

  Future<void> addProduct(String name, double costPrice, double sellingPrice, int stock) async {
    await _db.insertProduct(ProductItem(
      name: name,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stock: stock,
    ));
    await loadProducts();
  }

  Future<void> editProduct(ProductItem item) async {
    await _db.updateProduct(item);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    await loadProducts();
  }

  // --- DRAFT ITEMS MANIPULATION ---
  void addItem({
    required String name,
    required int qty,
    required double costPrice,
    required double sellingPrice,
  }) {
    _currentItems.add(ReceiptItem(
      productName: name,
      qty: qty,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
    ));
    _cashPaid = totalAmount;
    notifyListeners();
  }

  void updateItem(int index, {
    required String name,
    required int qty,
    required double costPrice,
    required double sellingPrice,
  }) {
    if (index >= 0 && index < _currentItems.length) {
      _currentItems[index] = ReceiptItem(
        productName: name,
        qty: qty,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
      );
      _cashPaid = totalAmount;
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _currentItems.length) {
      _currentItems.removeAt(index);
      _cashPaid = totalAmount;
      notifyListeners();
    }
  }

  void setInvoiceNumber(String val) {
    _invoiceNumber = val;
    notifyListeners();
  }

  void setDateTime(DateTime val) {
    _dateTime = val;
    notifyListeners();
  }

  void setDateTimeNow() {
    _dateTime = DateTime.now();
    notifyListeners();
  }

  void autoGenerateInvoiceNumber() {
    final now = DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final MM = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final HH = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    _invoiceNumber = 'TRX-$yy$MM$dd$HH$mm$ss';
    notifyListeners();
  }

  void setCashierName(String val) {
    _cashierName = val;
    notifyListeners();
  }

  void setCustomerName(String val) {
    _customerName = val;
    notifyListeners();
  }

  void setCustomerPhone(String val) {
    _customerPhone = val;
    notifyListeners();
  }

  void setPaymentMethod(String val) {
    _paymentMethod = val;
    notifyListeners();
  }

  void setDiscount(double val) {
    _discount = val;
    _cashPaid = totalAmount;
    notifyListeners();
  }

  void setCashPaid(double val) {
    _cashPaid = val;
    notifyListeners();
  }

  void setManualOverride(bool override, [double? total]) {
    _isManualOverride = override;
    if (total != null) _overrideTotal = total;
    _cashPaid = totalAmount;
    notifyListeners();
  }

  void clearToNewTransaction() {
    _initDefaultDraft();
    autoGenerateInvoiceNumber();
    setDateTimeNow();
    _currentItems.clear();
    _cashPaid = 0.0;
    _overrideTotal = 0.0;
    notifyListeners();
  }

  void loadTransactionForEdit(TransactionRecord trx) {
    _editingTransactionId = trx.id;
    _invoiceNumber = trx.invoiceNumber;
    _dateTime = trx.dateTime;
    _cashierName = trx.cashierName;
    _customerName = trx.customerName;
    _customerPhone = trx.customerPhone;
    _paymentMethod = trx.paymentMethod;
    _discount = trx.discount;
    _cashPaid = trx.cashPaid;
    _isManualOverride = false;
    _overrideTotal = trx.totalAmount;

    _currentItems = trx.items.map((it) => it.copyWith()).toList();
    notifyListeners();
  }

  // --- SAVE TRANSACTION TO DATABASE ---
  Future<TransactionRecord> saveCurrentTransaction() async {
    final record = TransactionRecord(
      id: _editingTransactionId,
      invoiceNumber: _invoiceNumber,
      dateTime: _dateTime,
      cashierName: _cashierName,
      customerName: _customerName,
      customerPhone: _customerPhone,
      paymentMethod: _paymentMethod,
      subtotal: subtotal,
      discount: _discount,
      totalAmount: totalAmount,
      cashPaid: _cashPaid,
      changeAmount: changeAmount,
      totalCost: totalCost,
      grossProfit: grossProfit,
      items: _currentItems,
    );

    if (_editingTransactionId == null) {
      final newId = await _db.insertTransaction(record);
      record.id = newId;
      _editingTransactionId = newId;
    } else {
      await _db.updateTransaction(record);
    }

    await loadTransactions();
    notifyListeners();
    return record;
  }

  // --- TRANSACTIONS LIST & CRUD ---
  Future<void> loadTransactions() async {
    _transactions = await _db.getTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    if (_editingTransactionId == id) {
      _editingTransactionId = null;
    }
    await loadTransactions();
    notifyListeners();
  }

  // --- ANALYTICS & FILTERING ---
  void setReportFilter(ReportFilter filter, {DateTimeRange? customRange}) {
    _currentFilter = filter;
    _customDateRange = customRange;
    notifyListeners();
  }

  void setOperationalExpense(double val) {
    _operationalExpense = val;
    notifyListeners();
  }

  List<TransactionRecord> get filteredTransactions {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_currentFilter) {
      case ReportFilter.today:
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        break;
      case ReportFilter.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case ReportFilter.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
      case ReportFilter.year:
        start = DateTime(now.year - 1, now.month, now.day);
        break;
      case ReportFilter.custom:
        if (_customDateRange != null) {
          start = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day,
            0,
            0,
            0,
          );
          end = DateTime(
            _customDateRange!.end.year,
            _customDateRange!.end.month,
            _customDateRange!.end.day,
            23,
            59,
            59,
          );
        } else {
          start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        }
        break;
    }

    return _transactions.where((t) {
      return t.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
          t.dateTime.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  double get reportTotalSales =>
      filteredTransactions.fold(0.0, (sum, t) => sum + t.totalAmount);

  double get reportTotalCost =>
      filteredTransactions.fold(0.0, (sum, t) => sum + t.totalCost);

  double get reportGrossProfit => reportTotalSales - reportTotalCost;

  double get reportNetProfit => reportGrossProfit - _operationalExpense;

  int get reportTotalTransactions => filteredTransactions.length;

  int get reportTotalUnitsSold => filteredTransactions.fold(
      0, (sum, t) => sum + t.items.fold(0, (isum, it) => isum + it.qty));

  // Current TransactionRecord snapshot for Preview
  TransactionRecord get currentTransactionSnapshot => TransactionRecord(
        id: _editingTransactionId,
        invoiceNumber: _invoiceNumber,
        dateTime: _dateTime,
        cashierName: _cashierName,
        customerName: _customerName,
        customerPhone: _customerPhone,
        paymentMethod: _paymentMethod,
        subtotal: subtotal,
        discount: _discount,
        totalAmount: totalAmount,
        cashPaid: _cashPaid,
        changeAmount: changeAmount,
        totalCost: totalCost,
        grossProfit: grossProfit,
        items: _currentItems,
      );
}
