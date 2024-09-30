import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';

class AdjustmentPage extends StatefulWidget {
  const AdjustmentPage({Key? key}) : super(key: key);

  @override
  _AdjustmentPageState createState() => _AdjustmentPageState();
}

class _AdjustmentPageState extends State<AdjustmentPage> {
  List<String> _kodeGudangList = [];
  List<Map<String, dynamic>> _listAdjustment = [];
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

  Future<void> _fetchListAdjustment(String kodeGudang) async {
    final url = 'https://itasoft.int.joget.cloud/jw/api/list/listAdjustmentStok';
    final headers = {
      'Content-Type': 'application/json',
      'api_key': globalApiKey,
      'api_id': globalApiId,
    };

    final body = jsonEncode({
      "d-1566518-fn_gudang": kodeGudang,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        _listAdjustment = List<Map<String, dynamic>>.from(data['data'])
            .where((item) => item['gudang'] == kodeGudang)
            .where((item) => _searchNamaKategori.isEmpty || (item['kategori'] ?? '').toLowerCase().contains(_searchNamaKategori.toLowerCase()))
            .where((item) {
          // Cek apakah 'exipred' kosong, jika kosong set jadi null
          String? expiredDate = item['exipred']?.isEmpty == true ? null : item['exipred'];
          // Filter berdasarkan tanggal expired
          return _selectedDate == null || (expiredDate != null && DateTime.parse(expiredDate).isAtSameMomentAs(_selectedDate!));
        }).toList();
        print(_listAdjustment);
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
          //Text('Welcome back, $username!'),
          _isLoading ? Center(child: CircularProgressIndicator()) : _buildDropdown(),
          const SizedBox(height: 20),
          _buildSearchFilters(),
          const SizedBox(height: 20),
          Expanded(child: _isLoading ? _buildLoadingList() : _buildAdjustmentList()),
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
                _fetchListAdjustment(newValue);
              } else {
                _listAdjustment.clear(); // Kosongkan daftar jika tidak ada kode gudang yang dipilih
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
                  _fetchListAdjustment(_selectedKodeGudang!);
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
                    _fetchListAdjustment(_selectedKodeGudang!);
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

  Widget _buildAdjustmentList() {
    return ListView.builder(
      itemCount: (_listAdjustment.length / 2).ceil(),
      itemBuilder: (context, index) {
        var item1 = _listAdjustment[index * 2];
        var item2 = index * 2 + 1 < _listAdjustment.length ? _listAdjustment[index * 2 + 1] : null;

        // Mendapatkan tanggal hari ini
        DateTime today = DateTime.now();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Untuk merenggangkan antara kategori dan stok
                        children: [
                          Text(
                            item1['kategori'] ?? 'Unknown Product',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Stok: ${item1['stok'] ?? 'N/A'}', // Menampilkan stok, jika null tampilkan 'N/A'
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item1['nama_barang']?.isNotEmpty == true ? item1['nama_barang'] : 'Unknown Product',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item1['exipred']?.isNotEmpty == true ? item1['exipred'] : 'No Expiry Date',
                        style: TextStyle(
                          fontSize: 14,
                          color: (item1['exipred'] != null && item1['exipred']!.isNotEmpty && DateTime.tryParse(item1['exipred']!) != null) &&
                                  (DateTime.parse(item1['exipred']!).isBefore(today) || DateTime.parse(item1['exipred']!).isAtSameMomentAs(today))
                              ? Colors.red // Jika tanggal kedaluwarsa <= hari ini
                              : Colors.black, // Jika tidak
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (item2 != null)
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Untuk merenggangkan antara kategori dan stok
                          children: [
                            Text(
                              item2['kategori'] ?? 'Unknown Product',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Stok: ${item2['stok'] ?? 'N/A'}', // Menampilkan stok, jika null tampilkan 'N/A'
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item2['nama_barang']?.isNotEmpty == true ? item2['nama_barang'] : 'Unknown Product',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item2['exipred']?.isNotEmpty == true ? item2['exipred'] : 'No Expiry Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: (item2['exipred'] != null && item2['exipred']!.isNotEmpty && DateTime.tryParse(item2['exipred']!) != null) &&
                                    (DateTime.parse(item2['exipred']!).isBefore(today) || DateTime.parse(item2['exipred']!).isAtSameMomentAs(today))
                                ? Colors.red // Jika tanggal kedaluwarsa <= hari ini
                                : Colors.black, // Jika tidak
                          ),
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
