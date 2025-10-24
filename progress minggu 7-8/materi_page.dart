// lib/materi_page.dart

import 'package:flutter/material.dart'; // Mengimpor pustaka dasar Flutter untuk UI.
import 'dart:convert'; // Mengimpor 'dart:convert' untuk dekode data JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk mengambil data Bab.
// Import halaman list materi siswa
import 'package:visualink_app/materi_list_page.dart'; // Mengimpor halaman list materi per Bab.

// Model Bab
class Bab {
  final String id; // ID unik dari Bab.
  final String judul; // Judul Bab.
  Bab({required this.id, required this.judul}); // Constructor model Bab.
  factory Bab.fromJson(Map<String, dynamic> json) {
    return Bab(
      id: json['_id'],
      judul: json['judul'],
    ); // Mapping data JSON ke properti model.
  }
}

class MateriPage extends StatefulWidget {
  const MateriPage({super.key}); // Widget utama untuk menampilkan daftar Bab.

  @override
  State<MateriPage> createState() => _MateriPageState(); // Membuat State untuk widget ini.
}

class _MateriPageState extends State<MateriPage> {
  List<Bab> _daftarBab = []; // List untuk menyimpan data Bab yang dimuat.
  bool _isLoading = true; // Status loading data Bab.
  String? _error; // Variabel untuk menyimpan pesan error.

  @override
  void initState() {
    super.initState();
    _fetchDaftarBab(); // Panggil fungsi untuk mengambil data saat inisialisasi.
  }

  Future<void> _fetchDaftarBab() async {
    setState(() {
      _isLoading = true; // Set status loading.
      _error = null; // Hapus pesan error sebelumnya.
    });
    // !!! GANTI IP ANDA !!!
    final url = Uri.parse(
      'http://192.168.1.17:3000/bab',
    ); // URL API untuk mengambil semua daftar Bab.
    try {
      final response = await http.get(url); // Lakukan permintaan GET.
      if (!mounted) return; // Keluar jika widget sudah tidak ada.
      if (response.statusCode == 200) {
        // Jika berhasil (OK).
        final List<dynamic> data = jsonDecode(
          response.body,
        ); // Dekode respons JSON.
        setState(() {
          _daftarBab = data
              .map((json) => Bab.fromJson(json))
              .toList(); // Konversi JSON array ke List<Bab>.
          _isLoading = false; // Hentikan loading.
        });
      } else {
        throw Exception(
          'Gagal memuat Bab: Status ${response.statusCode}',
        ); // Lempar error jika status non-200.
      }
    } catch (e) {
      if (!mounted) return; // Keluar jika widget sudah tidak ada.
      setState(() {
        _error = 'Error: ${e.toString()}'; // Set pesan error.
        _isLoading = false; // Hentikan loading.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainPinkColor = Color(0xFFF875A1); // Warna utama aplikasi (Pink).
    const lightPinkBackground = Color(
      0xFFFFF0F3,
    ); // Warna latar belakang yang lebih terang.

    return Scaffold(
      backgroundColor:
          lightPinkBackground, // Atur warna latar belakang Scaffold.
      appBar: AppBar(
        title: const Text('Materi'), // Judul halaman di AppBar.
        backgroundColor: mainPinkColor, // Warna latar belakang AppBar.
        foregroundColor: Colors.white, // Warna teks/ikon AppBar.
        elevation: 0, // Hilangkan bayangan AppBar.
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Daftar Bab',
            onPressed: _fetchDaftarBab, // Fungsi untuk memuat ulang daftar Bab.
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Desain Publikasi', // Judul Mata Pelajaran (statis).
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF00B2FF), // Warna Biru.
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30), // Jarak vertikal.

            _isLoading // Cek status loading.
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Tampilkan loading.
                : _error !=
                      null // Cek status error.
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : Expanded(
                    // Mengisi sisa ruang dengan daftar Bab.
                    child:
                        _daftarBab
                            .isEmpty // Cek jika daftar Bab kosong.
                        ? const Center(
                            child: Text('Belum ada Bab materi.'),
                          ) // Tampilkan pesan kosong.
                        : GridView.builder(
                            // Tampilkan Bab dalam format Grid.
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // 2 kolom per baris.
                                  crossAxisSpacing: 16, // Spasi horizontal.
                                  mainAxisSpacing: 16, // Spasi vertikal.
                                  childAspectRatio:
                                      1.5, // Rasio lebar:tinggi setiap item.
                                ),
                            itemCount: _daftarBab.length,
                            itemBuilder: (context, index) {
                              final bab =
                                  _daftarBab[index]; // Ambil objek Bab saat ini.
                              return ElevatedButton(
                                // Gunakan ElevatedButton sebagai item Grid.
                                onPressed: () {
                                  // Navigasi ke halaman DAFTAR MATERI untuk Bab ini
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MateriListPage(
                                        // Navigasi ke MateriListPage.
                                        babId: bab
                                            .id, // Kirim ID Bab yang dipilih.
                                        babJudul: bab
                                            .judul, // Kirim Judul Bab yang dipilih.
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mainPinkColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      20,
                                    ), // Bentuk tombol bulat.
                                  ),
                                ),
                                child: Text(
                                  bab.judul, // Tampilkan judul Bab.
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
