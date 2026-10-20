import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/currency_format.dart';
import '../../services/pdf_receipt_service.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({Key? key}) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _showPdfViewer = false;

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final trx = pos.currentTransactionSnapshot;
    final store = pos.storeProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Preview Struk & PDF'),
        actions: [
          IconButton(
            tooltip: _showPdfViewer ? 'Tampilkan Mode Visual' : 'Tampilkan Dokumen PDF',
            icon: Icon(_showPdfViewer ? Icons.receipt : Icons.picture_as_pdf),
            onPressed: () {
              setState(() {
                _showPdfViewer = !_showPdfViewer;
              });
            },
          ),
          IconButton(
            tooltip: 'Share PDF (WhatsApp)',
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceiptPdf(context, pos),
          ),
          IconButton(
            tooltip: 'Cetak Langsung',
            icon: const Icon(Icons.print),
            onPressed: () => _printDirectly(context, pos),
          ),
        ],
      ),
      body: _showPdfViewer
          ? PdfPreview(
              build: (format) => PdfReceiptService.generateReceiptPdf(
                store: store,
                trx: trx,
                customLogoBytes: pos.customLogoBytes,
              ),
              canChangePageFormat: false,
              canChangeOrientation: false,
              initialPageFormat: const PdfPageFormat(
                80 * PdfPageFormat.mm,
                double.infinity,
                marginAll: 4 * PdfPageFormat.mm,
              ),
              actions: [
                PdfPrintAction(
                  icon: const Icon(Icons.download),
                  onPressed: (context, build, pageFormat) async {
                    final bytes = await build(pageFormat);
                    await _savePdfToStorage(context, bytes, trx.invoiceNumber);
                  },
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    children: [
                      // Thermal Receipt Paper Card Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Logo
                            Center(
                              child: Container(
                                width: store.logoSize,
                                height: store.logoSize,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: pos.customLogoBytes != null
                                    ? Image.memory(pos.customLogoBytes!, fit: BoxFit.contain)
                                    : Image.asset('assets/images/solosfly_logo.png', fit: BoxFit.contain),
                              ),
                            ),

                            // Store Name (Bold)
                            Center(
                              child: Text(
                                store.storeName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Store Address
                            Center(
                              child: Text(
                                store.storeAddress,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Store Phone
                            Center(
                              child: Text(
                                store.storePhone,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Dashed Line
                            _buildDashedLine(),
                            const SizedBox(height: 6),

                            // 2. Info Transaksi
                            _buildInfoRow('Tanggal/Waktu:', '${_formatDate(trx.dateTime)} / ${_formatTime(trx.dateTime)}'),
                            _buildInfoRow('No.Trans.:', trx.invoiceNumber),
                            _buildInfoRow('Kasir:', trx.cashierName),
                            _buildInfoRow('Pelanggan:', trx.customerName),
                            _buildInfoRow('Hp/Telp.:', trx.customerPhone),

                            const SizedBox(height: 6),
                            _buildDashedLine(),
                            const SizedBox(height: 6),

                            // 3. Daftar Barang (2 baris per item)
                            ...trx.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Baris 1: Nama Barang Bold
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Baris 2: Qty x Harga Jual (kiri) & Subtotal (kanan)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item.qty} x ${CurrencyFormat.format(item.sellingPrice)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormat.format(item.subtotal),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 6),
                            _buildDashedLine(),
                            const SizedBox(height: 6),

                            // 4. Ringkasan Kuantitas
                            Text(
                              'Item(s): ${trx.totalItemsCount} Qty: ${trx.totalQuantityCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontFamily: 'monospace',
                              ),
                            ),

                            const SizedBox(height: 6),
                            _buildDashedLine(),
                            const SizedBox(height: 6),

                            // 5. Total & Pembayaran
                            _buildAmountRow('SubTotal :', CurrencyFormat.format(trx.subtotal)),
                            if (trx.discount > 0)
                              _buildAmountRow('Diskon :', '-${CurrencyFormat.format(trx.discount)}'),

                            const SizedBox(height: 4),
                            _buildDashedLine(),
                            const SizedBox(height: 4),

                            // TOTAL (BOLD & BESAR)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  CurrencyFormat.format(trx.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),
                            _buildDashedLine(),
                            const SizedBox(height: 4),

                            _buildAmountRow('Pembayaran (${trx.paymentMethod})', CurrencyFormat.format(trx.cashPaid)),
                            _buildAmountRow('Kembalian', CurrencyFormat.format(trx.changeAmount)),

                            const SizedBox(height: 18),

                            // 6. Footer (Center)
                            if (store.footerLine1.isNotEmpty)
                              Center(
                                child: Text(
                                  store.footerLine1,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: Colors.black, fontFamily: 'monospace'),
                                ),
                              ),
                            const SizedBox(height: 8),

                            if (store.footerLine2.isNotEmpty)
                              Center(
                                child: Text(
                                  store.footerLine2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),

                            if (store.footerLine3.isNotEmpty)
                              Center(
                                child: Text(
                                  store.footerLine3,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10.5, color: Colors.black, fontFamily: 'monospace'),
                                ),
                              ),
                            if (store.footerLine4.isNotEmpty)
                              Center(
                                child: Text(
                                  store.footerLine4,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10.5, color: Colors.black, fontFamily: 'monospace'),
                                ),
                              ),
                            if (store.footerLine5.isNotEmpty)
                              Center(
                                child: Text(
                                  store.footerLine5,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10.5, color: Colors.black, fontFamily: 'monospace'),
                                ),
                              ),
                            const SizedBox(height: 8),

                            if (store.footerLine6.isNotEmpty)
                              Center(
                                child: Text(
                                  store.footerLine6,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: Colors.black, fontFamily: 'monospace'),
                                ),
                              ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Control Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final bytes = await PdfReceiptService.generateReceiptPdf(
                                  store: store,
                                  trx: trx,
                                  customLogoBytes: pos.customLogoBytes,
                                );
                                await _savePdfToStorage(context, bytes, trx.invoiceNumber);
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Download PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD63384),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _shareReceiptPdf(context, pos),
                              icon: const Icon(Icons.share),
                              label: const Text('Share PDF'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => _printDirectly(context, pos),
                        icon: const Icon(Icons.print),
                        label: const Text('Cetak Struk (Printer Bluetooth / Thermal)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade800,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDashedLine() {
    return const Center(
      child: Text(
        '----------------------------------------',
        style: TextStyle(
          fontSize: 11,
          color: Colors.black,
          letterSpacing: 1.2,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Colors.black, fontFamily: 'monospace'),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11.5, color: Colors.black, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'monospace'),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReceiptPdf(BuildContext context, PosProvider pos) async {
    final pdfBytes = await PdfReceiptService.generateReceiptPdf(
      store: pos.storeProfile,
      trx: pos.currentTransactionSnapshot,
      customLogoBytes: pos.customLogoBytes,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Struk_${pos.invoiceNumber}.pdf',
    );
  }

  Future<void> _printDirectly(BuildContext context, PosProvider pos) async {
    final pdfBytes = await PdfReceiptService.generateReceiptPdf(
      store: pos.storeProfile,
      trx: pos.currentTransactionSnapshot,
      customLogoBytes: pos.customLogoBytes,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Struk_${pos.invoiceNumber}',
    );
  }

  Future<void> _savePdfToStorage(BuildContext context, Uint8List bytes, String invoiceNumber) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Struk_$invoiceNumber.pdf');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil disimpan ke: ${file.path}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () {
                Share.shareXFiles([XFile(file.path)], text: 'Struk Pembayaran $invoiceNumber');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan file: $e')),
        );
      }
    }
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
