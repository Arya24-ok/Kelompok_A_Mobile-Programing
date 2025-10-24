// lib/admin_materi_management_page.dart // Lokasi file: Halaman utama manajemen Bab untuk Admin.

import 'package:flutter/material.dart'; // Mengimpor pustaka Flutter Material.
import 'dart:convert'; // Mengimpor pustaka untuk encoding/decoding JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk permintaan jaringan.
// Import Halaman List Materi (dibutuhkan untuk navigasi)
import 'package:visualink_app/admin_materi_list_page.dart'; // Halaman untuk mengelola Materi dalam Bab.
// --- TAMBAHAN IMPORT UNTUK KUIS --- //
import 'package:visualink_app/admin_kuis_management_page.dart'; // Import halaman untuk mengelola Kuis dalam Bab.
// --- AKHIR TAMBAHAN IMPORT ---

// Model Bab // Model data untuk Bab (hanya perlu ID dan Judul).
class Bab {
  final String id; // ID unik Bab.
  final String judul; // Judul Bab.
  Bab({required this.id, required this.judul});
  // Factory constructor untuk membuat objek Bab dari JSON.
  factory Bab.fromJson(Map<String, dynamic> json) {
    return Bab(id: json['_id'], judul: json['judul']);
  }
}

class AdminMateriManagementPage extends StatefulWidget {
  // Mendefinisikan widget Stateful.
  // --- TAMBAHAN PARAMETER --- //
  // Parameter ini menentukan apakah halaman ini digunakan untuk mengelola 'materi' atau 'kuis'.
  final String managementType;
  // --- AKHIR TAMBAHAN PARAMETER ---

  // Constructor diperbarui untuk menerima parameter
  const AdminMateriManagementPage({
    super.key,
    required this.managementType, // Wajib menerima tipe manajemen.
  });

  @override // Menandai metode override.
  State<AdminMateriManagementPage> createState() =>
      _AdminMateriManagementPageState(); // Membuat dan mengembalikan state.
}

class _AdminMateriManagementPageState extends State<AdminMateriManagementPage> {
  // Kelas state.
  List<Bab> _daftarBab =
      []; // List untuk menyimpan semua Bab yang diambil dari API.
  bool _isLoadingBab = true; // Status loading data Bab.
  String? _errorBab; // Pesan error jika gagal mengambil data Bab.

  @override // Menandai metode override.
  void initState() {
    // Dipanggil sekali saat objek State dibuat.
    super.initState();
    _fetchDaftarBab(); // Memulai pengambilan data daftar Bab.
  }

  // Fungsi fetch detail SEMUA Bab
  Future<void> _fetchDaftarBab() async {
    setState(() {
      // Atur state loading.
      _isLoadingBab = true;
      _errorBab = null;
    });
    // URL API untuk mengambil daftar Bab.
    final url = Uri.parse('http://192.168.1.17:3000/bab');
    try {
      // Blok try-catch untuk penanganan error jaringan.
      final response = await http.get(url);
      if (!mounted) return; // Tambahkan mounted check setelah await
      if (response.statusCode == 200) {
        // Jika status kode 200 (Sukses).
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _daftarBab = data
              .map((json) => Bab.fromJson(json))
              .toList(); // Konversi JSON ke model Bab.
          _isLoadingBab = false;
        });
      } else {
        // Penanganan error status kode lainnya.
        throw Exception('Gagal memuat Bab: Status ${response.statusCode}');
      }
    } catch (e) {
      // Menangkap exception (error koneksi, dll.).
      if (!mounted) return;
      setState(() {
        _errorBab = 'Error fetching Babs: ${e.toString()}';
        _isLoadingBab = false;
      });
    }
  }

  // --- FUNGSI TAMBAH BAB BARU (SUDAH DIPERBAIKI) ---
  Future<void> _tambahBabBaru(String judul) async {
    if (judul.isEmpty) {
      // Validasi judul Bab.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        // Tampilkan SnackBar jika judul kosong.
        const SnackBar(
          content: Text('Judul Bab tidak boleh kosong'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // URL API untuk menambah Bab baru.
    final url = Uri.parse('http://192.168.1.17:3000/bab');
    try {
      final response = await http.post(
        // Melakukan permintaan POST.
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'judul': judul,
        }), // Mengirim judul Bab dalam body JSON.
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Jika status kode 201 (Created/Sukses membuat).
        Navigator.pop(context); // Tutup dialog setelah berhasil.
        _fetchDaftarBab(); // Refresh daftar Bab.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bab baru berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Jika gagal.
        final errorData = jsonDecode(response.body);
        Navigator.pop(context); // Tutup dialog.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${errorData['msg'] ?? response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Menangkap error koneksi.
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // --- AKHIR FUNGSI TAMBAH BAB BARU ---

  // Fungsi untuk menampilkan dialog tambah Bab baru.
  void _showAddBabDialog() {
    final TextEditingController babController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Bab Baru'),
          content: TextField(
            controller: babController,
            decoration: const InputDecoration(hintText: "Masukkan Judul Bab"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _tambahBabBaru(
                  babController.text,
                ); // Panggil fungsi tambah Bab.
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override // Menandai metode override.
  Widget build(BuildContext context) {
    // Metode untuk membangun UI.
    // --- TAMBAHAN LOGIKA JUDUL --- //
    // Tentukan judul AppBar secara dinamis berdasarkan parameter managementType.
    String appBarTitle = widget.managementType == 'kuis'
        ? 'Pilih Bab untuk Kelola Kuis' // Judul jika mengelola kuis.
        : 'Pilih Bab untuk Kelola Materi'; // Judul default jika mengelola materi.
    // --- AKHIR TAMBAHAN LOGIKA JUDUL ---

    return Scaffold(
      // Mengembalikan Scaffold.
      appBar: AppBar(
        // Bilah aplikasi.
        title: Text(appBarTitle), // Gunakan judul dinamis.
        backgroundColor: Colors.indigo, // Warna Admin.
        foregroundColor: Colors.white,
        actions: [
          // Aksi (tombol) di sisi kanan AppBar.
          IconButton(
            // Tombol tambah Bab.
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Tambah Bab Baru',
            onPressed: _showAddBabDialog,
          ),
          IconButton(
            // Tombol refresh daftar Bab.
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Daftar Bab',
            onPressed: _fetchDaftarBab,
          ),
        ],
      ),
      body: Padding(
        // Isi body dengan padding.
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              // Judul sub-bagian.
              'Daftar Bab:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Tiga kondisi tampilan utama: Loading, Error, Data.
            _isLoadingBab
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Jika loading.
                : _errorBab !=
                      null // Jika error.
                ? Center(
                    child: Text(
                      _errorBab!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : Expanded(
                    // Jika ada data.
                    child: _daftarBab.isEmpty
                        ? const Center(
                            // Jika daftar Bab kosong.
                            child: Text('Belum ada Bab. Tambahkan Bab baru.'),
                          )
                        : ListView.builder(
                            // Tampilkan daftar Bab.
                            itemCount: _daftarBab.length,
                            itemBuilder: (context, index) {
                              final bab = _daftarBab[index];
                              return Card(
                                // Menggunakan Card untuk setiap Bab.
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  title: Text(bab.judul),
                                  trailing: const Icon(
                                    // Ikon panah di kanan.
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  // --- TAMBAHAN LOGIKA NAVIGASI --- //
                                  onTap: () {
                                    // Aksi saat item Bab diklik.
                                    // Pengecekan tipe manajemen untuk menentukan halaman tujuan.
                                    if (widget.managementType == 'kuis') {
                                      // Jika tipe 'kuis', navigasi ke AdminKuisManagementPage.
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminKuisManagementPage(
                                                babId: bab
                                                    .id, // Meneruskan ID Bab.
                                                babJudul: bab
                                                    .judul, // Meneruskan judul Bab.
                                              ),
                                        ),
                                      );
                                    } else {
                                      // Jika tipe 'materi' (default), navigasi ke AdminMateriListPage.
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminMateriListPage(
                                                babId: bab.id,
                                                babJudul: bab.judul,
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                  // --- AKHIR TAMBAHAN LOGIKA NAVIGASI ---
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
