import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:visualink_app/kuis_list_page.dart';
import 'package:visualink_app/materi_page.dart' show Bab;

// Halaman utama untuk memilih Bab Kuis yang akan dimainkan.
class KuisPage extends StatefulWidget {
  const KuisPage({super.key});

  @override
  State<KuisPage> createState() => _KuisPageState();
}

class _KuisPageState extends State<KuisPage> {
  // Daftar Bab (Bab) yang dimuat dari API
  List<Bab> _daftarBab = [];
  // Status loading data dari API
  bool _isLoading = true;
  // Pesan error jika terjadi kegagalan saat fetch data
  String? _error;

  @override
  void initState() {
    super.initState();
    // Memulai proses pengambilan data bab saat widget dibuat
    _fetchDaftarBab();
  }

  // Fungsi untuk mengambil daftar Bab dari API
  Future<void> _fetchDaftarBab() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // URL API untuk mengambil daftar bab
    // !!! GANTI IP ANDA SESUAI ALAMAT BACKEND !!!
    final url = Uri.parse('http://192.168.1.17:3000/bab');
    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        // Parsing respons JSON ke dalam list Bab
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          // Menggunakan Bab.fromJson untuk mengubah data JSON menjadi objek Bab
          _daftarBab = data.map((json) => Bab.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        // Melempar exception jika status code bukan 200
        throw Exception('Gagal memuat Bab: Status ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      // Menangani error koneksi atau parsing
      setState(() {
        _error =
            'Error: ${e.toString()}. Pastikan server backend berjalan dan alamat IP benar.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna yang digunakan di halaman ini
    const mainPinkColor = Color(0xFFF875A1);
    const lightPinkBackground = Color(0xFFFFF0F3);

    return Scaffold(
      backgroundColor: lightPinkBackground,
      appBar: AppBar(
        title: const Text('Pilih Bab Kuis'),
        backgroundColor: mainPinkColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tombol refresh untuk memuat ulang daftar bab
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchDaftarBab,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Judul halaman
            const Text(
              'Uji Pemahamanmu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF00B2FF),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            // Bagian yang menampilkan konten utama (Loading, Error, atau Grid Bab)
            Expanded(
              // Menggunakan Expanded agar GridView mengisi sisa ruang
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: mainPinkColor),
                    ) // Tampilkan indikator loading
                  : _error != null
                  ? Center(
                      // Tampilkan pesan error dan tombol coba lagi
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
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _fetchDaftarBab,
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
                  : _daftarBab.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada Bab yang tersedia untuk Kuis.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ) // Tampilkan pesan kosong
                  : GridView.builder(
                      // Menampilkan daftar bab dalam Grid 2 kolom
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2, // Aspek rasio tombol bab
                          ),
                      itemCount: _daftarBab.length,
                      itemBuilder: (context, index) {
                        final bab = _daftarBab[index];
                        return Container(
                          // Efek bayangan (shadow) untuk estetika
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: mainPinkColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigasi ke halaman DAFTAR KUIS (KuisListPage) untuk Bab yang dipilih
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => KuisListPage(
                                    babId: bab.id, // Meneruskan ID bab
                                    babJudul: bab.judul, // Meneruskan Judul bab
                                  ),
                                ),
                              );
                            },
                            // Styling tombol bab
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainPinkColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.school,
                                  size: 30,
                                ), // Ikon untuk Bab
                                const SizedBox(height: 8),
                                Text(
                                  bab.judul,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
