import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/currency_format.dart';
import '../../models/product_item.dart';
import '../../models/transaction_record.dart';

class KatalogScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const KatalogScreen({Key? key, required this.onNavigateTab}) : super(key: key);

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchProductQuery = '';
  String _searchTrxQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat & Katalog'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD63384),
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Katalog Produk'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat Transaksi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. KATALOG PRODUK
          _buildKatalogTab(context, pos),
          // 2. RIWAYAT TRANSAKSI
          _buildRiwayatTab(context, pos),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddProductDialog(context, pos),
              backgroundColor: const Color(0xFFD63384),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Produk Baru'),
            )
          : null,
    );
  }

  // --- TAB 1: MASTER PRODUK ---
  Widget _buildKatalogTab(BuildContext context, PosProvider pos) {
    final filtered = pos.products.where((p) {
      return p.name.toLowerCase().contains(_searchProductQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchProductQuery = val),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Belum ada produk atau produk tidak ditemukan.'))
              : ListView.separated(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final p = filtered[idx];
                    final profitPerUnit = p.sellingPrice - p.costPrice;
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFFF0F5),
                          child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFD63384)),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'Harga Jual: ${CurrencyFormat.format(p.sellingPrice)} (Struk)',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            Text(
                              'Modal HPP: ${CurrencyFormat.format(p.costPrice)} | Laba: +${CurrencyFormat.format(profitPerUnit)}',
                              style: const TextStyle(fontSize: 11, color: Colors.teal),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Tambah ke Kasir',
                              icon: const Icon(Icons.add_shopping_cart, color: Color(0xFFD63384)),
                              onPressed: () {
                                pos.addItem(
                                  name: p.name,
                                  qty: 1,
                                  costPrice: p.costPrice,
                                  sellingPrice: p.sellingPrice,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${p.name} ditambahkan ke Kasir!'),
                                    action: SnackBarAction(
                                      label: 'Ke Kasir',
                                      onPressed: () => widget.onNavigateTab(0),
                                    ),
                                  ),
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showEditProductDialog(context, pos, p);
                                } else if (val == 'delete' && p.id != null) {
                                  pos.deleteProduct(p.id!);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit Produk')),
                                const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 2: RIWAYAT TRANSAKSI ---
  Widget _buildRiwayatTab(BuildContext context, PosProvider pos) {
    final filtered = pos.transactions.where((t) {
      final q = _searchTrxQuery.toLowerCase();
      return t.invoiceNumber.toLowerCase().contains(q) ||
          t.customerName.toLowerCase().contains(q) ||
          t.paymentMethod.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari No. TRX / Pelanggan...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchTrxQuery = val),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Belum ada riwayat transaksi.'))
              : ListView.separated(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final t = filtered[idx];
                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t.invoiceNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.paymentMethod,
                                    style: const TextStyle(
                                      color: Color(0xFFD63384),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDate(t.dateTime)} ${_formatTime(t.dateTime)} • Pelanggan: ${t.customerName}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                            const Divider(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total: ${CurrencyFormat.format(t.totalAmount)}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Laba Bersih: +${CurrencyFormat.format(t.grossProfit)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.teal),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Buka & Edit di Kasir',
                                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                                      onPressed: () {
                                        pos.loadTransactionForEdit(t);
                                        widget.onNavigateTab(0);
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Pratinjau / Cetak PDF',
                                      icon: const Icon(Icons.print_outlined, color: Color(0xFFD63384)),
                                      onPressed: () {
                                        pos.loadTransactionForEdit(t);
                                        widget.onNavigateTab(1);
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Hapus Transaksi',
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _confirmDeleteTransaction(context, pos, t),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- DIALOG TAMBAH PRODUK ---
  void _showAddProductDialog(BuildContext context, PosProvider pos) {
    String name = '';
    double cost = 0.0;
    double price = 0.0;
    int stock = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tambah Master Produk Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nama Produk *', isDense: true),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Modal / HPP *',
                    helperText: 'Untuk kalkulasi laba',
                    isDense: true,
                    prefixText: 'Rp ',
                  ),
                  onChanged: (val) => cost = double.tryParse(val) ?? 0.0,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual *',
                    helperText: 'Tampil di struk kasir',
                    isDense: true,
                    prefixText: 'Rp ',
                  ),
                  onChanged: (val) => price = double.tryParse(val) ?? 0.0,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok Barang (Opsional)', isDense: true),
                  onChanged: (val) => stock = int.tryParse(val) ?? 0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.trim().isEmpty) return;
                pos.addProduct(name.trim(), cost, price, stock);
                Navigator.pop(ctx);
              },
              child: const Text('Simpan Produk'),
            ),
          ],
        );
      },
    );
  }

  // --- DIALOG EDIT PRODUK ---
  void _showEditProductDialog(BuildContext context, PosProvider pos, ProductItem item) {
    String name = item.name;
    double cost = item.costPrice;
    double price = item.sellingPrice;
    int stock = item.stock;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Master Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Nama Produk', isDense: true),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: cost.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Modal / HPP',
                    isDense: true,
                    prefixText: 'Rp ',
                  ),
                  onChanged: (val) => cost = double.tryParse(val) ?? 0.0,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: price.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual',
                    isDense: true,
                    prefixText: 'Rp ',
                  ),
                  onChanged: (val) => price = double.tryParse(val) ?? 0.0,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: stock.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok Barang', isDense: true),
                  onChanged: (val) => stock = int.tryParse(val) ?? 0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                pos.editProduct(item.copyWith(
                  name: name.trim(),
                  costPrice: cost,
                  sellingPrice: price,
                  stock: stock,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTransaction(BuildContext context, PosProvider pos, TransactionRecord t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text('Yakin ingin menghapus transaksi ${t.invoiceNumber}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (t.id != null) pos.deleteTransaction(t.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  static String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
