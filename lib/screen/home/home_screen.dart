import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adjustment_page.dart';
import 'dashboard_page.dart';
import 'transaction_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _selectedItem = null;
  @override
  void initState() {
    super.initState();
    // Inisialisasi nilai awal ketika halaman dimuat
    _resetSelections();
  }

  @override
  void dispose() {
    // Reset nilai ketika halaman ditinggalkan
    _resetSelections();
    super.dispose();
  }

  void _resetSelections() {
    _selectedIndex = 0;
    _selectedItem = null;
  }

  void _onItemTapped(int index) {
    setState(() {
      _resetSelections();
      _selectedIndex = index;
    });
  }

  void _onSendDataTransaction(Map<String, dynamic>? item) {
    setState(() {
      _selectedItem = item;
    });
  }

  void _logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('token'),
      prefs.remove('username'),
    ]);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    // Memindahkan _widgetOptions ke dalam build
    final List<Widget> _widgetOptions = <Widget>[
      DashboardPage(
        onCategoryTap: (index) => _onItemTapped(index),
        sendDataTransaction: (item) => _onSendDataTransaction(item),
      ),
      TransactionPage(
        selectedItem: _selectedItem,
        onBackTap: (index) => _onItemTapped(index),
      ),
      AdjustmentPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_selectedIndex == 0
                ? 'Dashboard'
                : _selectedIndex == 1
                    ? 'Transaction'
                    : 'Adjustment'),
            if (_selectedIndex == 0)
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logOut,
              ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Transaction',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Adjustment',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
