import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/currency_format.dart';
import '../../models/transaction_record.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({Key? key}) : super(key: key);

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  bool _useBarChart = true;

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Laporan & Grafik Keuangan'),
        actions: [
          IconButton(
            tooltip: _useBarChart ? 'Beralih ke Line Chart' : 'Beralih ke Bar Chart',
            icon: Icon(_useBarChart ? Icons.show_chart : Icons.bar_chart),
            onPressed: () {
              setState(() {
                _useBarChart = !_useBarChart;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. FILTER WAKTU CHIPS
            _buildFilterChips(context, pos),
            const SizedBox(height: 14),

            // 2. KARTU RINGKASAN METRIK (SUMMARY CARDS)
            _buildSummaryCards(context, pos),
            const SizedBox(height: 16),

            // 3. GRAFIK INTERAKTIF (fl_chart)
            _buildChartCard(context, pos),
            const SizedBox(height: 16),

            // 4. DAFTAR TRANSAKSI PERIODE AKTIF
            _buildTransactionsListSection(context, pos),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- 1. FILTER WAKTU CHIPS ---
  Widget _buildFilterChips(BuildContext context, PosProvider pos) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('Hari Ini', ReportFilter.today, pos),
          const SizedBox(width: 8),
          _buildChip('1 Minggu', ReportFilter.week, pos),
          const SizedBox(width: 8),
          _buildChip('1 Bulan', ReportFilter.month, pos),
          const SizedBox(width: 8),
          _buildChip('1 Tahun', ReportFilter.year, pos),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.date_range, size: 16),
            label: Text(
              pos.currentFilter == ReportFilter.custom && pos.customDateRange != null
                  ? '${_formatShort(pos.customDateRange!.start)} - ${_formatShort(pos.customDateRange!.end)}'
                  : 'Custom Tanggal',
              style: TextStyle(
                color: pos.currentFilter == ReportFilter.custom ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
            backgroundColor: pos.currentFilter == ReportFilter.custom ? const Color(0xFFD63384) : Colors.white,
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                initialDateRange: pos.customDateRange ??
                    DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 7)),
                      end: DateTime.now(),
                    ),
              );
              if (range != null) {
                pos.setReportFilter(ReportFilter.custom, customRange: range);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, ReportFilter filter, PosProvider pos) {
    final isSelected = pos.currentFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFD63384),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE0E0E0)),
      onSelected: (val) {
        if (val) pos.setReportFilter(filter);
      },
    );
  }

  // --- 2. KARTU RINGKASAN METRIK ---
  Widget _buildSummaryCards(BuildContext context, PosProvider pos) {
    return Column(
      children: [
        // Baris 1: Omzet & HPP (Modal)
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Total Penjualan (Omzet)',
                formula: 'Σ (Harga Jual × Qty)',
                value: CurrencyFormat.formatWithRp(pos.reportTotalSales),
                color: const Color(0xFF0D6EFD), // Blue
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Total Modal (HPP)',
                formula: 'Σ (Harga Modal × Qty)',
                value: CurrencyFormat.formatWithRp(pos.reportTotalCost),
                color: const Color(0xFFFD7E14), // Orange
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Baris 2: Laba Kotor & Biaya Operasional
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Laba Kotor (Gross Profit)',
                formula: 'Omzet - HPP Modal',
                value: CurrencyFormat.formatWithRp(pos.reportGrossProfit),
                color: const Color(0xFF198754), // Green
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _showEditExpenseDialog(context, pos),
                borderRadius: BorderRadius.circular(10),
                child: _buildMetricTile(
                  title: 'Biaya Operasional',
                  formula: 'Input Manual (Tekan Edit)',
                  value: CurrencyFormat.formatWithRp(pos.operationalExpense),
                  color: Colors.blueGrey,
                  icon: Icons.edit_note,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Baris 3: Laba Bersih & Transaksi/Unit
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Laba Bersih (Net Profit)',
                formula: 'Laba Kotor - Operasional',
                value: CurrencyFormat.formatWithRp(pos.reportNetProfit),
                color: const Color(0xFFD63384), // Magenta / Solosfly Pink
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Total Transaksi & Unit',
                formula: '${pos.reportTotalTransactions} Transaksi',
                value: '${pos.reportTotalUnitsSold} Unit Barang',
                color: const Color(0xFF6F42C1), // Indigo
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String formula,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            formula,
            style: const TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  // --- 3. GRAFIK INTERAKTIF ---
  Widget _buildChartCard(BuildContext context, PosProvider pos) {
    final transactions = pos.filteredTransactions;

    // Aggregate data into points
    final chartData = _generateChartData(transactions);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Perbandingan Finansial',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  _useBarChart ? 'Mode Bar Chart' : 'Mode Line Chart',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Legenda Warna
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Omzet', const Color(0xFF0D6EFD)),
                const SizedBox(width: 14),
                _buildLegendItem('Laba Kotor', const Color(0xFF198754)),
                const SizedBox(width: 14),
                _buildLegendItem('Laba Bersih', const Color(0xFFD63384)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: chartData.isEmpty
                  ? const Center(child: Text('Tidak ada transaksi pada periode ini.'))
                  : _useBarChart
                      ? _buildBarChart(chartData)
                      : _buildLineChart(chartData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  Widget _buildBarChart(List<_ChartPoint> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (data.map((e) => e.sales).fold(0.0, (a, b) => a > b ? a : b) * 1.25).clamp(100000.0, double.infinity),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[group.x.toInt()];
              String name = rodIndex == 0 ? 'Omzet' : (rodIndex == 1 ? 'Laba Kotor' : 'Laba Bersih');
              return BarTooltipItem(
                '${item.label}\n$name: ${CurrencyFormat.formatWithRp(rod.toY)}',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(data[idx].label, style: const TextStyle(fontSize: 10)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (val, meta) {
                return Text(CurrencyFormat.formatCompact(val), style: const TextStyle(fontSize: 9));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          final idx = e.key;
          final d = e.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(toY: d.sales, color: const Color(0xFF0D6EFD), width: 7, borderRadius: BorderRadius.circular(2)),
              BarChartRodData(toY: d.gross, color: const Color(0xFF198754), width: 7, borderRadius: BorderRadius.circular(2)),
              BarChartRodData(toY: d.net, color: const Color(0xFFD63384), width: 7, borderRadius: BorderRadius.circular(2)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(List<_ChartPoint> data) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final names = ['Omzet', 'Laba Kotor', 'Laba Bersih'];
                final colors = [const Color(0xFF0D6EFD), const Color(0xFF198754), const Color(0xFFD63384)];
                return LineTooltipItem(
                  '${names[spot.barIndex]}: ${CurrencyFormat.formatWithRp(spot.y)}',
                  TextStyle(color: colors[spot.barIndex], fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(data[idx].label, style: const TextStyle(fontSize: 10)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (val, meta) {
                return Text(CurrencyFormat.formatCompact(val), style: const TextStyle(fontSize: 9));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Omzet Line
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.sales)).toList(),
            isCurved: true,
            color: const Color(0xFF0D6EFD),
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
          // Gross Profit Line
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.gross)).toList(),
            isCurved: true,
            color: const Color(0xFF198754),
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
          // Net Profit Line
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.net)).toList(),
            isCurved: true,
            color: const Color(0xFFD63384),
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  // --- 4. DAFTAR TRANSAKSI PERIODE AKTIF ---
  Widget _buildTransactionsListSection(BuildContext context, PosProvider pos) {
    final list = pos.filteredTransactions;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Transaksi Periode Ini (${list.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Tidak ada data transaksi.', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 10),
                itemBuilder: (ctx, idx) {
                  final t = list[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFF0F5),
                      child: Text(
                        '#${t.id ?? idx + 1}',
                        style: const TextStyle(color: Color(0xFFD63384), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    title: Text(
                      t.invoiceNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${_formatDate(t.dateTime)} ${_formatTime(t.dateTime)} • ${t.paymentMethod} • ${t.customerName}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormat.format(t.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Laba: +${CurrencyFormat.format(t.grossProfit)}',
                          style: const TextStyle(fontSize: 10, color: Colors.teal),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditExpenseDialog(BuildContext context, PosProvider pos) {
    double expense = pos.operationalExpense;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Biaya Operasional Periode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan total biaya operasional (sewa, listrik, kantong, gaji, dll) untuk menghitung Laba Bersih:'),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: expense > 0 ? expense.toStringAsFixed(0) : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal Biaya Operasional',
                  prefixText: 'Rp ',
                ),
                onChanged: (val) => expense = double.tryParse(val) ?? 0.0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                pos.setOperationalExpense(expense);
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  List<_ChartPoint> _generateChartData(List<TransactionRecord> list) {
    if (list.isEmpty) return [];

    // Grouping: by date string DD/MM
    final Map<String, _ChartPoint> map = {};

    // Sort ascending
    final sorted = List<TransactionRecord>.from(list)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    for (var t in sorted) {
      final key = '${t.dateTime.day}/${t.dateTime.month}';
      if (!map.containsKey(key)) {
        map[key] = _ChartPoint(label: key, sales: 0, gross: 0, net: 0);
      }
      map[key]!.sales += t.totalAmount;
      map[key]!.gross += t.grossProfit;
      map[key]!.net += t.grossProfit; // before flat period expense
    }

    // Limit to 7 points for clean layout
    final result = map.values.toList();
    if (result.length > 7) {
      return result.sublist(result.length - 7);
    }
    return result;
  }

  static String _formatShort(DateTime dt) => '${dt.day}/${dt.month}';
  static String _formatDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  static String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ChartPoint {
  final String label;
  double sales;
  double gross;
  double net;

  _ChartPoint({
    required this.label,
    required this.sales,
    required this.gross,
    required this.net,
  });
}
