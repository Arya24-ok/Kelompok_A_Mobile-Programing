// lib/materi_list_page.dart (Untuk Siswa)

import 'package:flutter/material.dart'; // Mengimpor pustaka dasar Flutter untuk UI.
import 'dart:convert'; // Mengimpor 'dart:convert' untuk dekode JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk mengambil data.
import 'package:visualink_app/materi_detail_page.dart'; // Mengimpor halaman detail materi yang akan dinavigasi.

// Model MateriItem
class MateriItem {
  final String id; // ID unik dari materi.
  final String judul; // Judul materi.
  final String deskripsi; // Deskripsi singkat materi.
  MateriItem({
    required this.id,
    required this.judul,
    required this.deskripsi,
  }); // Constructor model.
  factory MateriItem.fromJson(Map<String, dynamic> json) {
    return MateriItem(
      id: json['_id'], // Mapping ID dari JSON respons server.
      judul: json['judul'], // Mapping judul.
      deskripsi: json['deskripsi'], // Mapping deskripsi.
    );
  }
}

class MateriListPage extends StatefulWidget {
  final String babId; // ID Bab yang materinya akan dimuat (properti wajib).
  final String babJudul; // Judul Bab (untuk ditampilkan di AppBar).
  const MateriListPage({
    super.key,
    required this.babId, // Menerima ID Bab.
    required this.babJudul, // Menerima Judul Bab.
  });

  @override
  State<MateriListPage> createState() => _MateriListPageState(); // Membuat State untuk widget ini.
}

class _MateriListPageState extends State<MateriListPage> {
  List<MateriItem> _daftarMateri =
      []; // List untuk menyimpan data materi yang dimuat.
  bool _isLoading =
      true; // Status loading, default true saat mulai memuat data.
  String? _error; // Variabel untuk menyimpan pesan error jaringan/API.

  @override
  void initState() {
    super.initState();
    _fetchDaftarMateri(); // Panggil fungsi untuk mengambil data saat inisialisasi.
  }

  Future<void> _fetchDaftarMateri() async {
    setState(() {
      _isLoading = true; // Set status loading.
      _error = null; // Hapus pesan error sebelumnya.
    });
    // !!! GANTI IP ANDA !!!
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/bab/${widget.babId}/materi', // URL API untuk mendapatkan list materi berdasarkan Bab ID.
    );
    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      ); // Lakukan permintaan GET.
      if (!mounted) return; // Keluar jika widget sudah tidak ada.
      if (response.statusCode == 200) {
        // Jika berhasil (OK).
        final List<dynamic> data = jsonDecode(
          response.body,
        ); // Dekode respons JSON.
        setState(() {
          _daftarMateri =
              data // Konversi list JSON ke List<MateriItem>.
                  .map((json) => MateriItem.fromJson(json))
                  .toList();
          _isLoading = false; // Hentikan loading.
        });
      } else if (response.statusCode == 404) {
        // Jika Bab ditemukan tapi belum ada materi (Not Found).
        setState(() {
          _daftarMateri = []; // Kosongkan daftar materi.
          _isLoading = false; // Hentikan loading.
        });
      } else {
        throw Exception(
          'Gagal memuat Materi: Status ${response.statusCode}',
        ); // Lempar error jika status lain.
      }
    } catch (e) {
      if (!mounted) return; // Keluar jika widget sudah tidak ada.
      setState(() {
        _error = 'Error fetching Materi: ${e.toString()}'; // Set pesan error.
        _isLoading = false; // Hentikan loading.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainPinkColor = Color(
      0xFFF875A1,
    ); // Definisi warna utama (pink) untuk siswa.

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.babJudul), // Tampilkan Judul Bab di AppBar.
        backgroundColor: mainPinkColor, // Warna latar belakang AppBar.
        foregroundColor: Colors.white, // Warna teks/ikon AppBar.
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchDaftarMateri, // Fungsi untuk memuat ulang data.
          ),
        ],
      ),
      body:
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
              ), // Tampilkan error.
            )
          : _daftarMateri
                .isEmpty // Cek apakah daftar materi kosong.
          ? const Center(
              child: Text('Belum ada materi untuk Bab ini.'),
            ) // Tampilkan pesan kosong.
          : ListView.builder(
              // Jika ada data, tampilkan sebagai list.
              padding: const EdgeInsets.all(8.0),
              itemCount: _daftarMateri.length, // Jumlah item dalam list.
              itemBuilder: (context, index) {
                // Fungsi untuk membangun setiap item list.
                final materi =
                    _daftarMateri[index]; // Ambil objek materi saat ini.
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: ListTile(
                    // Widget List Tile untuk setiap materi.
                    title: Text(materi.judul), // Tampilkan judul materi.
                    subtitle: Text(
                      materi.deskripsi, // Tampilkan deskripsi sebagai subtitle.
                      maxLines: 2, // Batasi hingga 2 baris.
                      overflow: TextOverflow
                          .ellipsis, // Gunakan elipsis jika teks terlalu panjang.
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ), // Ikon panah di ujung.
                    onTap: () {
                      // Fungsi yang dipanggil saat item ditekan.
                      // Navigasi ke Halaman Detail Materi
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MateriDetailPage(
                            // Kirim ID Bab dan Judul Bab
                            babId: widget.babId,
                            babJudul: widget.babJudul,
                            // Kirim ID Materi Spesifik
                            materiId: materi.id, // ID materi yang dipilih.
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
