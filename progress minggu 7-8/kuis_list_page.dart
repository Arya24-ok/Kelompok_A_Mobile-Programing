import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:visualink_app/kuis_models.dart'; // Import model

import 'package:visualink_app/kuis_player_page.dart';

class KuisListPage extends StatefulWidget {
  final String babId;
  final String babJudul;
  const KuisListPage({super.key, required this.babId, required this.babJudul});

  @override
  State<KuisListPage> createState() => _KuisListPageState();
}

class _KuisListPageState extends State<KuisListPage> {
  List<KuisItem> _daftarKuis = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDaftarKuis();
  }

  Future<void> _fetchDaftarKuis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // URL API untuk mengambil daftar kuis berdasarkan babId
    // !!! GANTI IP ANDA !!!
    final url = Uri.parse('http://192.168.1.17:3000/bab/${widget.babId}/kuis');
    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _daftarKuis = data.map((json) => KuisItem.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        if (response.statusCode == 404) {
          // Jika 404, artinya tidak ada kuis, anggap berhasil tapi daftar kosong
          setState(() {
            _daftarKuis = [];
            _isLoading = false;
          });
        } else {
          throw Exception('Gagal memuat Kuis: Status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Error: ${e.toString()}. Pastikan server backend berjalan dan alamat IP benar.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainPinkColor = Color(0xFFF875A1);
    // Konstanta warna pink dengan 10% opacity untuk latar belakang ikon kuis
    // Ini adalah praktik terbaik untuk mengatasi warning withOpacity().
    const lightPinkColor = Color.fromARGB(0x1A, 0xF8, 0x75, 0xA1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kuis: ${widget.babJudul}',
        ), // Judul AppBar lebih deskriptif
        backgroundColor: mainPinkColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchDaftarKuis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: mainPinkColor),
            ) // Tambahkan warna
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _fetchDaftarKuis,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainPinkColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _daftarKuis.isEmpty
          ? const Center(
              child: Text(
                'Belum ada kuis yang tersedia untuk Bab ini.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _daftarKuis.length,
              itemBuilder: (context, index) {
                final kuis = _daftarKuis[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            lightPinkColor, // Menggunakan konstanta warna ringan
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.quiz, color: mainPinkColor),
                    ),
                    title: Text(
                      kuis.judul,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: const Text('Siap untuk Uji Coba Pengetahuan?'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: mainPinkColor,
                    ),
                    onTap: () {
                      // Navigasi ke Halaman Player Kuis
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KuisPlayerPage(
                            kuisId: kuis.id,
                            kuisJudul: kuis.judul,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
