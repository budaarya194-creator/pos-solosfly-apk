import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/currency_format.dart';
import '../../models/product_item.dart';
import '../../models/receipt_item.dart';
import '../../models/store_profile.dart';

class KasirScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const KasirScreen({Key? key, required this.onNavigateTab}) : super(key: key);

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir & Edit Struk'),
        actions: [
          IconButton(
            tooltip: 'Template & Logo Toko',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => _showStoreProfileDialog(context, pos),
          ),
          IconButton(
            tooltip: 'Transaksi Baru',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              pos.clearToNewTransaction();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaksi baru dimulai')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Info Toko Aktif
            _buildStoreBanner(context, pos),
            const SizedBox(height: 12),

            // Card 1: Info Transaksi
            _buildTransactionInfoCard(context, pos),
            const SizedBox(height: 12),

            // Card 2: Daftar Barang
            _buildItemsListCard(context, pos),
            const SizedBox(height: 12),

            // Card 3: Pembayaran & Total
            _buildPaymentCard(context, pos),
            const SizedBox(height: 20),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () async {
                if (pos.currentItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tambahkan minimal 1 barang terlebih dahulu!')),
                  );
                  return;
                }
                await pos.saveCurrentTransaction();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi berhasil disimpan! Menuju Pratinjau PDF...')),
                );
                widget.onNavigateTab(1); // Pindah ke tab Preview Struk & PDF
              },
              icon: const Icon(Icons.save_alt),
              label: const Text(
                'Simpan Transaksi & Export PDF',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD63384),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => widget.onNavigateTab(1),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Lihat Pratinjau Struk (Preview)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- STORE BANNER ---
  Widget _buildStoreBanner(BuildContext context, PosProvider pos) {
    final profile = pos.storeProfile;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFC0CB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            backgroundImage: pos.customLogoBytes != null
                ? MemoryImage(pos.customLogoBytes!)
                : const AssetImage('assets/images/solosfly_logo.png') as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.storeName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF8B004F)),
                ),
                Text(
                  profile.storePhone,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  profile.storeAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFD63384)),
            onPressed: () => _showStoreProfileDialog(context, pos),
          )
        ],
      ),
    );
  }

  // --- CARD 1: INFO TRANSAKSI ---
  Widget _buildTransactionInfoCard(BuildContext context, PosProvider pos) {
    final dt = pos.dateTime;
    final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} / ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Info Transaksi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            // Tanggal / Waktu
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: dateStr),
                    decoration: const InputDecoration(
                      labelText: 'Tanggal / Waktu',
                      prefixIcon: Icon(Icons.calendar_today, size: 18),
                      isDense: true,
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: pos.dateTime,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(pos.dateTime),
                        );
                        if (pickedTime != null) {
                          pos.setDateTime(DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          ));
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => pos.setDateTimeNow(),
                  child: const Text('Waktu Sekarang', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // No. Transaksi
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('inv_${pos.invoiceNumber}'),
                    initialValue: pos.invoiceNumber,
                    decoration: const InputDecoration(
                      labelText: 'No. Transaksi',
                      prefixIcon: Icon(Icons.confirmation_number_outlined, size: 18),
                      isDense: true,
                    ),
                    onChanged: (val) => pos.setInvoiceNumber(val),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => pos.autoGenerateInvoiceNumber(),
                  child: const Text('Auto-Gen', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Kasir & Pelanggan
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: pos.cashierName,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kasir',
                      isDense: true,
                    ),
                    onChanged: (val) => pos.setCashierName(val),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: pos.customerName,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pelanggan',
                      isDense: true,
                    ),
                    onChanged: (val) => pos.setCustomerName(val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: pos.customerPhone,
              decoration: const InputDecoration(
                labelText: 'Hp/Telp Pelanggan',
                prefixIcon: Icon(Icons.phone_android, size: 18),
                isDense: true,
              ),
              onChanged: (val) => pos.setCustomerPhone(val),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD 2: DAFTAR BARANG ---
  Widget _buildItemsListCard(BuildContext context, PosProvider pos) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Barang (${pos.currentItems.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(context, pos),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Barang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD63384),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (pos.currentItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Belum ada barang di struk. Tekan "+ Tambah Barang".',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pos.currentItems.length,
                separatorBuilder: (_, __) => const Divider(height: 14),
                itemBuilder: (ctx, idx) {
                  final item = pos.currentItems[idx];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.qty} x ${CurrencyFormat.format(item.sellingPrice)} = ${CurrencyFormat.format(item.subtotal)}',
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'HPP Modal: ${CurrencyFormat.format(item.costPrice)}/unit (Laba: ${CurrencyFormat.format(item.grossProfit)})',
                              style: const TextStyle(fontSize: 11, color: Colors.teal),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                        onPressed: () => _showEditItemDialog(context, pos, idx, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        onPressed: () => pos.removeItem(idx),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- CARD 3: TOTAL & PEMBAYARAN ---
  Widget _buildPaymentCard(BuildContext context, PosProvider pos) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan & Pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Item(s) & Total Qty:'),
                Text(
                  '${pos.totalItemsCount} Item(s) | ${pos.totalQuantityCount} Qty',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SubTotal:'),
                Text(
                  CurrencyFormat.format(pos.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Diskon
            Row(
              children: [
                const Text('Diskon:'),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    initialValue: pos.discount.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixText: 'Rp ',
                      hintText: '0',
                    ),
                    onChanged: (val) {
                      final d = double.tryParse(val) ?? 0.0;
                      pos.setDiscount(d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Total highlight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    CurrencyFormat.format(pos.totalAmount),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD63384)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Metode Pembayaran
            Row(
              children: [
                const Text('Metode Bayar:'),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    initialValue: pos.paymentMethod,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Qris / Tunai / Transfer',
                    ),
                    onChanged: (val) => pos.setPaymentMethod(val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Uang Diterima / Cash Paid
            Row(
              children: [
                const Text('Pembayaran (Uang Masuk):'),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: Key('paid_${pos.cashPaid}'),
                    initialValue: pos.cashPaid.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixText: 'Rp ',
                    ),
                    onChanged: (val) {
                      final p = double.tryParse(val) ?? 0.0;
                      pos.setCashPaid(p);
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Bayar Pas',
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  onPressed: () => pos.setCashPaid(pos.totalAmount),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian:'),
                Text(
                  CurrencyFormat.format(pos.changeAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG TAMBAH BARANG ---
  void _showAddItemDialog(BuildContext context, PosProvider pos) {
    String name = '';
    int qty = 1;
    double cost = 0.0;
    double price = 0.0;
    ProductItem? selectedMaster;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Tambah Barang ke Struk'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pos.products.isNotEmpty) ...[
                      DropdownButtonFormField<ProductItem>(
                        decoration: const InputDecoration(
                          labelText: 'Pilih dari Master Produk (Opsional)',
                          isDense: true,
                        ),
                        items: pos.products.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (Jual: ${CurrencyFormat.format(p.sellingPrice)})'),
                          );
                        }).toList(),
                        onChanged: (p) {
                          if (p != null) {
                            setStateModal(() {
                              selectedMaster = p;
                              name = p.name;
                              cost = p.costPrice;
                              price = p.sellingPrice;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      key: Key('name_$name'),
                      initialValue: name,
                      decoration: const InputDecoration(labelText: 'Nama Barang *', isDense: true),
                      onChanged: (val) => name = val,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: qty.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Kuantitas (Qty) *', isDense: true),
                      onChanged: (val) => qty = int.tryParse(val) ?? 1,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: Key('cost_$cost'),
                      initialValue: cost > 0 ? cost.toStringAsFixed(0) : '',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Modal / HPP per unit *',
                        helperText: 'Untuk laba finansial, TIDAK dicetak di struk',
                        isDense: true,
                        prefixText: 'Rp ',
                      ),
                      onChanged: (val) => cost = double.tryParse(val) ?? 0.0,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: Key('price_$price'),
                      initialValue: price > 0 ? price.toStringAsFixed(0) : '',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual per unit *',
                        helperText: 'Harga ini yang tampil & dicetak di struk',
                        isDense: true,
                        prefixText: 'Rp ',
                      ),
                      onChanged: (val) => price = double.tryParse(val) ?? 0.0,
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
                    pos.addItem(
                      name: name.trim(),
                      qty: qty <= 0 ? 1 : qty,
                      costPrice: cost,
                      sellingPrice: price,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Tambahkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DIALOG EDIT BARANG ---
  void _showEditItemDialog(BuildContext context, PosProvider pos, int index, ReceiptItem item) {
    String name = item.productName;
    int qty = item.qty;
    double cost = item.costPrice;
    double price = item.sellingPrice;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Barang di Struk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Nama Barang', isDense: true),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: qty.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Kuantitas (Qty)', isDense: true),
                  onChanged: (val) => qty = int.tryParse(val) ?? 1,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: cost.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Modal / HPP per unit',
                    helperText: 'TIDAK dicetak di struk',
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
                    labelText: 'Harga Jual per unit',
                    helperText: 'Tampil di struk',
                    isDense: true,
                    prefixText: 'Rp ',
                  ),
                  onChanged: (val) => price = double.tryParse(val) ?? 0.0,
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
                pos.updateItem(
                  index,
                  name: name.trim(),
                  qty: qty <= 0 ? 1 : qty,
                  costPrice: cost,
                  sellingPrice: price,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        );
      },
    );
  }

  // --- DIALOG TEMPLATE & LOGO TOKO (AUTO SAVE) ---
  void _showStoreProfileDialog(BuildContext context, PosProvider pos) {
    final profile = pos.storeProfile;
    String name = profile.storeName;
    String address = profile.storeAddress;
    String phone = profile.storePhone;
    double logoSize = profile.logoSize;
    String f1 = profile.footerLine1;
    String f2 = profile.footerLine2;
    String f3 = profile.footerLine3;
    String f4 = profile.footerLine4;
    String f5 = profile.footerLine5;
    String f6 = profile.footerLine6;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Template Struk & Logo Toko',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Logo Picker & Size Slider
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: pos.customLogoBytes != null
                              ? MemoryImage(pos.customLogoBytes!)
                              : const AssetImage('assets/images/solosfly_logo.png') as ImageProvider,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                                  if (file != null) {
                                    final bytes = await file.readAsBytes();
                                    await pos.setCustomLogo(bytes);
                                    setStateModal(() {});
                                  }
                                },
                                icon: const Icon(Icons.photo_library, size: 16),
                                label: const Text('Ganti Logo Galeri'),
                                style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                              ),
                              if (pos.customLogoBytes != null)
                                TextButton(
                                  onPressed: () async {
                                    await pos.setCustomLogo(null);
                                    setStateModal(() {});
                                  },
                                  child: const Text('Reset ke Logo Default', style: TextStyle(fontSize: 11, color: Colors.red)),
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Ukuran Logo:'),
                        Expanded(
                          child: Slider(
                            value: logoSize,
                            min: 40,
                            max: 130,
                            divisions: 18,
                            label: '${logoSize.toInt()}px',
                            onChanged: (val) {
                              setStateModal(() => logoSize = val);
                              pos.updateLogoSize(val);
                            },
                          ),
                        ),
                        Text('${logoSize.toInt()}px'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(labelText: 'Nama Toko (Header Bold)', isDense: true),
                      onChanged: (val) => name = val,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: address,
                      decoration: const InputDecoration(labelText: 'Alamat Toko', isDense: true),
                      onChanged: (val) => address = val,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: phone,
                      decoration: const InputDecoration(labelText: 'Kontak / No. HP Toko', isDense: true),
                      onChanged: (val) => phone = val,
                    ),
                    const SizedBox(height: 12),
                    const Text('Teks Footer Struk (Bisa Diedit Bebas):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: f1,
                      decoration: const InputDecoration(labelText: 'Footer Baris 1', isDense: true),
                      onChanged: (val) => f1 = val,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: f2,
                      decoration: const InputDecoration(labelText: 'Footer Baris 2', isDense: true),
                      onChanged: (val) => f2 = val,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: f3,
                      decoration: const InputDecoration(labelText: 'Footer Baris 3', isDense: true),
                      onChanged: (val) => f3 = val,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: f4,
                      decoration: const InputDecoration(labelText: 'Footer Baris 4', isDense: true),
                      onChanged: (val) => f4 = val,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: f5,
                      decoration: const InputDecoration(labelText: 'Footer Baris 5', isDense: true),
                      onChanged: (val) => f5 = val,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: f6,
                      decoration: const InputDecoration(labelText: 'Footer Baris 6', isDense: true),
                      onChanged: (val) => f6 = val,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        pos.updateStoreProfile(StoreProfile(
                          storeName: name.trim(),
                          storeAddress: address.trim(),
                          storePhone: phone.trim(),
                          logoSize: logoSize,
                          footerLine1: f1.trim(),
                          footerLine2: f2.trim(),
                          footerLine3: f3.trim(),
                          footerLine4: f4.trim(),
                          footerLine5: f5.trim(),
                          footerLine6: f6.trim(),
                        ));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Template toko otomatis tersimpan permanen!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD63384),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Simpan Template Toko'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
