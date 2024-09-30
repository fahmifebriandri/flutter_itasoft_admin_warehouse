import 'dart:convert'; // Untuk jsonDecode

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config.dart';

class TransactionPage extends StatefulWidget {
  final Map<String, dynamic>? selectedItem;
  final Function(int) onBackTap;

  const TransactionPage({Key? key, this.selectedItem, required this.onBackTap}) : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String? idBarang;

  @override
  void initState() {
    super.initState();
    // Inisialisasi idBarang di sini
    idBarang = widget.selectedItem?['id'];
  }

  @override
  void dispose() {
    // Reset nilai ketika halaman ditinggalkan
    _resetSelections();
    super.dispose();
  }

  void _resetSelections() {
    idBarang = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: idBarang != null
          ? FutureBuilder<Map<String, dynamic>>(
              future: fetchData(idBarang!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load data'));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No data found'));
                }

                final data = snapshot.data!;
                bool isExpired = data['expired'] != null && DateTime.parse(data['expired']).isBefore(DateTime.now());
                bool isLowStock = (int.tryParse(data['stok']) ?? 0) < (int.tryParse(data['safety_stok']) ?? 0);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildRow('ID Gudang', data['gudang']),
                        buildRow('Kategori', data['kategori']),
                        buildRow('Nama Barang', data['nama_barang']),
                        buildRow('Exp Date', data['expired']),
                        buildRow('Quantity/Stock', data['stok']),
                        buildRow('Safety Stock', data['safety_stok']),
                        const SizedBox(height: 30), // Jarak 30px
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // Tindakan berdasarkan kondisi
                              if (isExpired || isLowStock) {
                                // Lakukan tindakan untuk meminta item
                                requestItem(data);
                              } else {
                                // Kembali ke halaman sebelumnya
                                widget.onBackTap(0);
                              }
                            },
                            child: Text(isExpired || isLowStock ? 'Request Item' : 'Back'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No item selected')),
            ),
    );
  }

  // Fungsi untuk membuat row dengan label dan value
  Widget buildRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(value.toString()),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mengambil data dari API berdasarkan id_barang
  Future<Map<String, dynamic>> fetchData(String idBarang) async {
    const String url = 'https://itasoft.int.joget.cloud/jw/api/form/formStokBarang/'; // URL base
    final Uri fullUrl = Uri.parse('$url$idBarang'); // URL lengkap dengan id_barang

    try {
      final response = await http.get(
        fullUrl,
        headers: {
          'api_key': globalApiKey,
      'api_id': globalApiId,
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  // Fungsi untuk melakukan POST request
  Future<void> requestItem(Map<String, dynamic> data) async {
    const String url = 'https://itasoft.int.joget.cloud/jw/api/form/adjustmentStok';

    final headers = {
      'api_key': globalApiKey,
      'api_id': globalApiId,
      'Content-Type': 'application/json', // Menambahkan content type
    };

    // Mengirim data sebagai body request
    final body = jsonEncode(data); // Mengonversi data menjadi JSON

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Tindakan jika POST berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item request successful!')),
        );
        // Kembali ke halaman sebelumnya setelah berhasil
        //widget.onBackTap(0);
      } else {
        // Tindakan jika terjadi kesalahan
        throw Exception('Failed to request item: ${response.body}');
      }
    } catch (e) {
      // Menangani error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting item: $e')),
      );
    }
  }
}
