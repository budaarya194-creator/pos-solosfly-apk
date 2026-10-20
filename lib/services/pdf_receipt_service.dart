import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/store_profile.dart';
import '../models/transaction_record.dart';
import 'currency_format.dart';

class PdfReceiptService {
  static const double rollWidthMm = 80.0;
  static const String dashedLine = '--------------------------------------------------';

  static Future<Uint8List> generateReceiptPdf({
    required StoreProfile store,
    required TransactionRecord trx,
    Uint8List? customLogoBytes,
  }) async {
    final doc = pw.Document();

    // Load logo if available
    pw.ImageProvider? logoImage;
    if (customLogoBytes != null && customLogoBytes.isNotEmpty) {
      logoImage = pw.MemoryImage(customLogoBytes);
    } else {
      try {
        final byteData = await rootBundle.load('assets/images/solosfly_logo.png');
        logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (_) {
        // Fallback gracefully without logo image
      }
    }

    final rollPageFormat = PdfPageFormat(
      rollWidthMm * PdfPageFormat.mm,
      double.infinity,
      marginAll: 4 * PdfPageFormat.mm,
    );

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    doc.addPage(
      pw.Page(
        pageFormat: rollPageFormat,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER (Center)
                if (logoImage != null)
                  pw.Center(
                    child: pw.Container(
                      width: store.logoSize,
                      height: store.logoSize,
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  ),

                pw.Center(
                  child: pw.Text(
                    store.storeName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    store.storeAddress,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    store.storePhone,
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(height: 4),

                // Dashed line
                pw.Center(
                  child: pw.Text(
                    dashedLine,
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(height: 4),

                // 2. INFO TRANSAKSI (Space Between)
                _buildInfoRow('Tanggal/Waktu:', '${_formatDate(trx.dateTime)} / ${_formatTime(trx.dateTime)}'),
                _buildInfoRow('No.Trans.:', trx.invoiceNumber),
                _buildInfoRow('Kasir:', trx.cashierName),
                _buildInfoRow('Pelanggan:', trx.customerName),
                _buildInfoRow('Hp/Telp.:', trx.customerPhone),

                pw.SizedBox(height: 4),
                // Dashed line
                pw.Center(
                  child: pw.Text(
                    dashedLine,
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(height: 4),

                // 3. DAFTAR BARANG (2 baris per item)
                ...trx.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Line 1: Nama Barang Bold
                        pw.Text(
                          item.productName,
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 1.5),
                        // Line 2: Qty x Harga Jual (kiri) & Subtotal (kanan)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${item.qty} x ${CurrencyFormat.format(item.sellingPrice)}',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                            ),
                            pw.Text(
                              CurrencyFormat.format(item.subtotal),
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 4),
                // Dashed line
                pw.Center(
                  child: pw.Text(
                    dashedLine,
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(height: 3),

                // 4. RINGKASAN KUANTITAS
                pw.Text(
                  'Item(s): ${trx.totalItemsCount} Qty: ${trx.totalQuantityCount}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                ),

                pw.SizedBox(height: 3),
                // Dashed line
                pw.Center(
                  child: pw.Text(
                    dashedLine,
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(height: 4),

                // 5. TOTAL & PEMBAYARAN
                _buildAmountRow('SubTotal :', CurrencyFormat.format(trx.subtotal)),
                if (trx.discount > 0)
                  _buildAmountRow('Diskon :', '-${CurrencyFormat.format(trx.discount)}'),

                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    dashedLine,
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(height: 3),

                // TOTAL (BOLD & LARGER)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      CurrencyFormat.format(trx.totalAmount),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    dashedLine,
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
                  ),
                ),
                pw.SizedBox(height: 4),

                _buildAmountRow('Pembayaran (${trx.paymentMethod})', CurrencyFormat.format(trx.cashPaid)),
                _buildAmountRow('Kembalian', CurrencyFormat.format(trx.changeAmount)),

                pw.SizedBox(height: 12),

                // 6. FOOTER (Center)
                if (store.footerLine1.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      store.footerLine1,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                    ),
                  ),
                pw.SizedBox(height: 6),

                if (store.footerLine2.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      store.footerLine2,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 6),

                if (store.footerLine3.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      store.footerLine3,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                    ),
                  ),
                if (store.footerLine4.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      store.footerLine4,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                    ),
                  ),
                if (store.footerLine5.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      store.footerLine5,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                    ),
                  ),
                pw.SizedBox(height: 6),

                if (store.footerLine6.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      store.footerLine6,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                    ),
                  ),
                pw.SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );

    return await doc.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAmountRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
