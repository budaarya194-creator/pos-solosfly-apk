import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_item.dart';
import '../models/receipt_item.dart';
import '../models/transaction_record.dart';
import '../models/expense_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_solosfly.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        stock INTEGER DEFAULT 0
      )
    ''');

    // 2. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        date_time TEXT NOT NULL,
        cashier_name TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        payment_method TEXT,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0,
        total_amount REAL NOT NULL,
        cash_paid REAL NOT NULL,
        change_amount REAL DEFAULT 0,
        total_cost REAL NOT NULL,
        gross_profit REAL NOT NULL
      )
    ''');

    // 3. Transaction Items Table
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        qty INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');

    // 4. Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    // Seed default master products
    final defaultProducts = [
      ProductItem(name: 'Tumbler Mix Miniso/stbc', costPrice: 30000.0, sellingPrice: 40000.0, stock: 50),
      ProductItem(name: 'Viona Blouse', costPrice: 30000.0, sellingPrice: 45000.0, stock: 25),
      ProductItem(name: 'Catok Curly Mangoman', costPrice: 55000.0, sellingPrice: 80000.0, stock: 15),
      ProductItem(name: 'Pashmina Silk Premium', costPrice: 22000.0, sellingPrice: 35000.0, stock: 40),
      ProductItem(name: 'Crop Cardigan Knit', costPrice: 38000.0, sellingPrice: 55000.0, stock: 20),
      ProductItem(name: 'Midi Dress Floral', costPrice: 52000.0, sellingPrice: 79000.0, stock: 18),
    ];

    for (var prod in defaultProducts) {
      await db.insert('products', prod.toMap());
    }

    // Seed default receipt transaction as specified
    final now = DateTime(2026, 10, 20, 13, 3);
    final trxId = await db.insert('transactions', {
      'invoice_number': 'TRX-261020130359',
      'date_time': now.toIso8601String(),
      'cashier_name': 'diyah permata',
      'customer_name': 'Pelanggan',
      'customer_phone': '+62 85xxxx',
      'payment_method': 'Qris',
      'subtotal': 645000.0,
      'discount': 0.0,
      'total_amount': 645000.0,
      'cash_paid': 645000.0,
      'change_amount': 0.0,
      'total_cost': 475000.0,
      'gross_profit': 170000.0,
    });

    final defaultItems = [
      {'transaction_id': trxId, 'product_name': 'Tumbler Mix Miniso/stbc', 'qty': 13, 'cost_price': 30000.0, 'selling_price': 40000.0},
      {'transaction_id': trxId, 'product_name': 'Viona Blouse', 'qty': 1, 'cost_price': 30000.0, 'selling_price': 45000.0},
      {'transaction_id': trxId, 'product_name': 'Catok Curly Mangoman', 'qty': 1, 'cost_price': 55000.0, 'selling_price': 80000.0},
    ];

    for (var it in defaultItems) {
      await db.insert('transaction_items', it);
    }

    // Seed historical demo transactions so weekly, monthly, and yearly charts look realistic
    final pastDemo = [
      {
        'invoice_number': 'TRX-261019091522',
        'date_time': DateTime(2026, 10, 19, 10, 15).toIso8601String(),
        'cashier_name': 'diyah permata',
        'customer_name': 'Siti Rahma',
        'customer_phone': '+62 8123456',
        'payment_method': 'Tunai',
        'subtotal': 165000.0,
        'discount': 0.0,
        'total_amount': 165000.0,
        'cash_paid': 200000.0,
        'change_amount': 35000.0,
        'total_cost': 110000.0,
        'gross_profit': 55000.0,
        'items': [
          {'product_name': 'Crop Cardigan Knit', 'qty': 3, 'cost_price': 38000.0, 'selling_price': 55000.0},
        ]
      },
      {
        'invoice_number': 'TRX-261018143000',
        'date_time': DateTime(2026, 10, 18, 14, 30).toIso8601String(),
        'cashier_name': 'diyah permata',
        'customer_name': 'Bella Clarissa',
        'customer_phone': '+62 8789901',
        'payment_method': 'Transfer',
        'subtotal': 316000.0,
        'discount': 0.0,
        'total_amount': 316000.0,
        'cash_paid': 316000.0,
        'change_amount': 0.0,
        'total_cost': 208000.0,
        'gross_profit': 108000.0,
        'items': [
          {'product_name': 'Midi Dress Floral', 'qty': 4, 'cost_price': 52000.0, 'selling_price': 79000.0},
        ]
      },
      {
        'invoice_number': 'TRX-261015112000',
        'date_time': DateTime(2026, 10, 15, 11, 20).toIso8601String(),
        'cashier_name': 'diyah permata',
        'customer_name': 'Anisa Putri',
        'customer_phone': '+62 8991234',
        'payment_method': 'Qris',
        'subtotal': 240000.0,
        'discount': 0.0,
        'total_amount': 240000.0,
        'cash_paid': 240000.0,
        'change_amount': 0.0,
        'total_cost': 165000.0,
        'gross_profit': 75000.0,
        'items': [
          {'product_name': 'Catok Curly Mangoman', 'qty': 3, 'cost_price': 55000.0, 'selling_price': 80000.0},
        ]
      },
    ];

    for (var pd in pastDemo) {
      final items = pd['items'] as List<Map<String, dynamic>>;
      final mapCopy = Map<String, dynamic>.from(pd);
      mapCopy.remove('items');
      final pastTrxId = await db.insert('transactions', mapCopy);
      for (var it in items) {
        await db.insert('transaction_items', {
          'transaction_id': pastTrxId,
          'product_name': it['product_name'],
          'qty': it['qty'],
          'cost_price': it['cost_price'],
          'selling_price': it['selling_price'],
        });
      }
    }
  }

  // --- PRODUCTS ---
  Future<List<ProductItem>> getProducts() async {
    final db = await database;
    final res = await db.query('products', orderBy: 'name ASC');
    return res.map((m) => ProductItem.fromMap(m)).toList();
  }

  Future<int> insertProduct(ProductItem item) async {
    final db = await database;
    return await db.insert('products', item.toMap());
  }

  Future<int> updateProduct(ProductItem item) async {
    final db = await database;
    return await db.update(
      'products',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- TRANSACTIONS ---
  Future<List<TransactionRecord>> getTransactions({DateTime? start, DateTime? end}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (start != null && end != null) {
      whereClause = 'date_time BETWEEN ? AND ?';
      whereArgs = [start.toIso8601String(), end.toIso8601String()];
    }

    final res = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date_time DESC',
    );

    List<TransactionRecord> transactions = [];
    for (var t in res) {
      final tid = t['id'] as int;
      final itemsRes = await db.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [tid],
      );
      final items = itemsRes.map((m) => ReceiptItem.fromMap(m)).toList();
      transactions.add(TransactionRecord.fromMap(t, items: items));
    }
    return transactions;
  }

  Future<int> insertTransaction(TransactionRecord trx) async {
    final db = await database;
    return await db.transaction((txn) async {
      final trxMap = trx.toMap();
      trxMap.remove('id');
      final trxId = await txn.insert('transactions', trxMap);

      for (var item in trx.items) {
        final itemMap = item.toMap();
        itemMap.remove('id');
        itemMap['transaction_id'] = trxId;
        await txn.insert('transaction_items', itemMap);
      }
      return trxId;
    });
  }

  Future<void> updateTransaction(TransactionRecord trx) async {
    if (trx.id == null) return;
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'transactions',
        trx.toMap(),
        where: 'id = ?',
        whereArgs: [trx.id],
      );
      await txn.delete('transaction_items', where: 'transaction_id = ?', whereArgs: [trx.id]);
      for (var item in trx.items) {
        final itemMap = item.toMap();
        itemMap.remove('id');
        itemMap['transaction_id'] = trx.id;
        await txn.insert('transaction_items', itemMap);
      }
    });
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transaction_items', where: 'transaction_id = ?', whereArgs: [id]);
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- EXPENSES ---
  Future<List<ExpenseRecord>> getExpenses({DateTime? start, DateTime? end}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (start != null && end != null) {
      whereClause = 'date BETWEEN ? AND ?';
      whereArgs = [start.toIso8601String(), end.toIso8601String()];
    }

    final res = await db.query(
      'expenses',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return res.map((m) => ExpenseRecord.fromMap(m)).toList();
  }

  Future<int> insertExpense(ExpenseRecord exp) async {
    final db = await database;
    final map = exp.toMap();
    map.remove('id');
    return await db.insert('expenses', map);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
