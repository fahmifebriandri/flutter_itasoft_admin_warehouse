import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onCategoryTap;
  final Function(Map<String, dynamic>?) sendDataTransaction;

  const DashboardPage({Key? key, required this.onCategoryTap, required this.sendDataTransaction}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<String> _kodeGudangList = [];
  List<Map<String, dynamic>> _listStokBarang = [];
  String? _selectedKodeGudang;
  String username = '';
  bool _isLoading = true;

  // Variabel untuk pencarian
  String _searchNamaKategori = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchData();
  }

  void _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'User';
    });
  }

  Future<void> _fetchData() async {
    try {
      await Future.wait([_fetchKodeGudang()]);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchKodeGudang() async {
    final url = 'https://itasoft.int.joget.cloud/jw/api/list/list_frmUserMapping?pageSize=5&startOffset=1';
    final headers = {
      'api_key': globalApiKey,
      'api_id': globalApiId,
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      Set<String> kodeGudangSet = {};

      for (var item in data['data']) {
        kodeGudangSet.add(item['kode_gudang']);
      }

      setState(() {
        _kodeGudangList = kodeGudangSet.toList()..sort();
      });
    } else {
      throw Exception('Failed to load kode gudang');
    }
  }

  Future<void> _fetchListStokBarang(String kodeGudang) async {
    final url = 'https://itasoft.int.joget.cloud/jw/api/list/list_formStokBarang?pageSize=10&startOffset=1';
    final headers = {
      'api_key': globalApiKey,
      'api_id': globalApiId,
    };

    final body = jsonEncode({
      "d-1558783-fn_c_gudang": kodeGudang,
    });

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        // Memfilter data berdasarkan kode gudang yang dipilih
        _listStokBarang = List<Map<String, dynamic>>.from(data['data'])
            .where((item) => item['c_gudang'] == kodeGudang) // Filter berdasarkan c_gudang
            .where((item) => _searchNamaKategori.isEmpty || (item['c_kategori'] ?? '').toLowerCase().contains(_searchNamaKategori.toLowerCase())) // Filter berdasarkan nama barang
            .where((item) => _selectedDate == null || DateTime.parse(item['c_expired']).isAtSameMomentAs(_selectedDate!)) // Filter berdasarkan tanggal expired
            .toList();
      });
    } else {
      throw Exception('Failed to load stok barang');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ikon Profil
              Icon(
                Icons.person, // Ganti dengan ikon yang diinginkan
                size: 50.0, // Atur ukuran ikon sesuai kebutuhan
              ),
              SizedBox(width: 10.0), // Memberi jarak antara ikon dan teks
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $username!',
                    style: TextStyle(
                      fontSize: 18.0, // Ukuran teks
                      fontWeight: FontWeight.bold, // Bold
                    ),
                  ),
                  Text(
                    'Admin Warehouse',
                    style: TextStyle(
                      fontSize: 12.0, // Ukuran teks untuk "admin gudang"
                      color: Colors.grey, // Warna teks, bisa diubah sesuai kebutuhan
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _isLoading ? Center(child: CircularProgressIndicator()) : _buildDropdown(),
          const SizedBox(height: 20),
          _buildSearchFilters(),
          const SizedBox(height: 20),
          Expanded(child: _isLoading ? _buildLoadingList() : _buildStokBarangList()),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select Kode Gudang'),
          value: _selectedKodeGudang,
          items: _kodeGudangList.map((String kode) {
            return DropdownMenuItem<String>(
              value: kode,
              child: Text(kode),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedKodeGudang = newValue;
              // Ambil data stok barang sesuai kode gudang yang dipilih
              if (newValue != null) {
                _fetchListStokBarang(newValue);
              } else {
                _listStokBarang.clear(); // Kosongkan daftar jika tidak ada kode gudang yang dipilih
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Cari Nama Kategori',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchNamaKategori = value;
                if (_selectedKodeGudang != null) {
                  _fetchListStokBarang(_selectedKodeGudang!);
                }
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Pilih Tanggal Expired',
              border: OutlineInputBorder(),
            ),
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode()); // Menyembunyikan keyboard
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                  if (_selectedKodeGudang != null) {
                    _fetchListStokBarang(_selectedKodeGudang!);
                  }
                });
              }
            },
            controller: TextEditingController(
              text: _selectedDate != null ? "${_selectedDate!.toLocal()}".split(' ')[0] : '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStokBarangList() {
    return ListView.builder(
      itemCount: (_listStokBarang.length / 2).ceil(),
      itemBuilder: (context, index) {
        var item1 = _listStokBarang[index * 2];
        var item2 = index * 2 + 1 < _listStokBarang.length ? _listStokBarang[index * 2 + 1] : null;

        // Mendapatkan tanggal hari ini
        DateTime today = DateTime.now();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  widget.onCategoryTap(1);
                  widget.sendDataTransaction(item1);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Menyelaraskan ikon secara vertikal
                    children: [
                      // Kolom pertama: Icon
                      Icon(
                        Icons.shopping_bag, // Ikon yang mencerminkan barang
                        size: 40, // Ukuran ikon, bisa disesuaikan
                      ),
                      const SizedBox(width: 10), // Jarak antara ikon dan teks

                      // Kolom kedua: Nama Kategori dan Tanggal Expired
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item1['c_kategori'] ?? 'Unknown Product',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item1['c_expired'] ?? 'No Expiry Date',
                            style: TextStyle(
                                fontSize: 14,
                                color: DateTime.parse(item1['c_expired']).isBefore(today) || DateTime.parse(item1['c_expired']).isAtSameMomentAs(today)
                                    ? Colors.red // Jika tanggal kedaluwarsa <= hari ini
                                    : Colors.black // Jika tidak
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (item2 != null)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onCategoryTap(1);
                    widget.sendDataTransaction(item2);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // Menyelaraskan secara vertikal
                      children: [
                        // Kolom pertama: Icon
                        Icon(
                          Icons.shopping_bag, // Ikon yang mencerminkan barang
                          size: 40, // Ukuran ikon, bisa disesuaikan
                        ),
                        const SizedBox(width: 10), // Jarak antara ikon dan teks

                        // Kolom kedua: Nama Kategori dan Tanggal Expired
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item2['c_kategori'] ?? 'Unknown Product',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item2['c_expired'] ?? 'No Expiry Date',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: DateTime.parse(item2['c_expired']).isBefore(today) || DateTime.parse(item2['c_expired']).isAtSameMomentAs(today)
                                      ? Colors.red // Jika tanggal kedaluwarsa <= hari ini
                                      : Colors.black // Jika tidak
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return Center(child: CircularProgressIndicator());
  }
}
