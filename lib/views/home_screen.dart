import 'package:flutter/material.dart';
import 'kasir/kasir_screen.dart';
import 'preview/preview_screen.dart';
import 'laporan/laporan_screen.dart';
import 'katalog/katalog_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      KasirScreen(onNavigateTab: _navigateToTab),
      const PreviewScreen(),
      const LaporanScreen(),
      KatalogScreen(onNavigateTab: _navigateToTab),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD63384), // Solosfly Magenta
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Kasir & Edit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.print_outlined),
            activeIcon: Icon(Icons.print),
            label: 'Preview PDF',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Laporan & Grafik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Riwayat & Master',
          ),
        ],
      ),
    );
  }
}
