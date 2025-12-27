// lib/admin_materi_list_page.dart // Lokasi file: Halaman list materi untuk Bab tertentu (Admin).

import 'package:flutter/material.dart'; // Mengimpor pustaka Flutter Material.
import 'dart:convert'; // Mengimpor pustaka untuk encoding/decoding JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk permintaan jaringan.

// --- IMPORTS FINAL ---
import 'package:visualink_app/admin_add_materi_form.dart'; // Import form tambah materi.
import 'package:visualink_app/admin_edit_materi_page.dart'; // Import halaman edit materi (pop-up menu).
// Halaman Detail Siswa (MateriDetailPage) - Dibiarkan untuk referensi model
import 'package:visualink_app/materi_detail_page.dart'; // Import halaman detail (siswa/umum).
// Halaman Detail Admin (BARU DITAMBAHKAN)
import 'package:visualink_app/admin_materi_detail_page.dart'; // Import halaman detail untuk Admin (saat list item diklik).
// Import model MateriDetail dari file definisinya
import 'package:visualink_app/materi_detail_page.dart'
    show
        MateriDetail; // Import model MateriDetail untuk kebutuhan edit (pop-up menu).
// --- AKHIR IMPORTS ---

// Model MateriItem // Model sederhana untuk menampilkan daftar materi (hanya perlu ID, Judul, Deskripsi).
class MateriItem {
  final String id; // ID unik materi.
  final String judul; // Judul materi.
  final String deskripsi; // Deskripsi singkat materi.

  // Konstruktor utama.
  MateriItem({required this.id, required this.judul, required this.deskripsi});

  // Factory constructor untuk membuat objek dari data JSON (list view).
  factory MateriItem.fromJson(Map<String, dynamic> json) {
    return MateriItem(
      id: json['_id'], // Mengambil ID.
      judul: json['judul'], // Mengambil judul.
      deskripsi: json['deskripsi'], // Mengambil deskripsi.
    );
  }
}

class AdminMateriListPage extends StatefulWidget {
  // Mendefinisikan widget Stateful.
  final String babId; // ID Bab yang materinya akan ditampilkan.
  final String babJudul; // Judul Bab (untuk ditampilkan di AppBar).

  const AdminMateriListPage({
    // Konstruktor.
    super.key,
    required this.babId,
    required this.babJudul,
  });

  @override // Menandai metode override.
  State<AdminMateriListPage> createState() => _AdminMateriListPageState(); // Membuat dan mengembalikan state.
}

class _AdminMateriListPageState extends State<AdminMateriListPage> {
  // Kelas state.
  List<MateriItem> _daftarMateri =
      []; // List untuk menyimpan daftar materi di Bab ini.
  bool _isLoading = true; // State boolean untuk melacak status loading data.
  String? _error; // Variabel untuk menyimpan pesan error.

  @override // Menandai metode override.
  void initState() {
    // Dipanggil sekali saat objek State dibuat.
    super.initState();
    _fetchDaftarMateri(); // Memulai pengambilan data daftar materi.
  }

  // Fungsi fetch detail SEMUA materi di bawah Bab tertentu
  Future<void> _fetchDaftarMateri() async {
    setState(() {
      // Atur state loading.
      _isLoading = true;
      _error = null;
    });
    // URL API untuk mengambil semua materi di bawah Bab tertentu.
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/bab/${widget.babId}/materi',
    );
    try {
      // Blok try-catch untuk penanganan error jaringan.
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      ); // Melakukan permintaan GET HTTP.
      if (!mounted) return; // Batalkan jika widget unmounted.

      if (response.statusCode == 200) {
        // Jika status kode 200 (Sukses).
        final List<dynamic> data = jsonDecode(
          response.body,
        ); // Mendecode body response JSON.
        setState(() {
          // Memperbarui state.
          _daftarMateri =
              data // Memetakan data JSON ke list objek MateriItem.
                  .map((json) => MateriItem.fromJson(json))
                  .toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // Jika 404 (tidak ditemukan/kosong).
        setState(() {
          _daftarMateri = []; // Kosongkan daftar materi.
          _isLoading = false;
        });
      } else {
        // Untuk error status code lainnya.
        throw Exception('Gagal memuat Materi: Status ${response.statusCode}');
      }
    } catch (e) {
      // Menangkap exception (error koneksi, dll.).
      if (!mounted) return;
      setState(() {
        _error =
            'Error fetching Materi: ${e.toString()}'; // Menyimpan pesan error.
        _isLoading = false;
      });
    }
  }

  // Fungsi asinkron untuk menghapus satu materi
  Future<void> _hapusMateri(String materiId) async {
    // 1. Tampilkan Dialog Konfirmasi
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // Dialog konfirmasi.
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus materi ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false), // Tombol Batal.
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true), // Tombol Hapus.
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true) {
      // Jika pengguna membatalkan.
      return;
    }

    // 2. Lakukan Permintaan DELETE
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/materi/$materiId',
    ); // URL DELETE materi.
    try {
      final response = await http.delete(
        url,
      ); // Melakukan permintaan DELETE HTTP.
      if (!mounted) return;

      if (response.statusCode == 200) {
        // Jika sukses (200 OK).
        ScaffoldMessenger.of(context).showSnackBar(
          // Tampilkan SnackBar sukses.
          const SnackBar(
            content: Text('Materi berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchDaftarMateri(); // Refresh daftar materi.
      } else {
        // Jika gagal.
        ScaffoldMessenger.of(context).showSnackBar(
          // Tampilkan SnackBar error.
          SnackBar(
            content: Text('Gagal menghapus: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Menangkap error koneksi.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error koneksi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override // Menandai metode override.
  Widget build(BuildContext context) {
    // Metode untuk membangun UI.
    return Scaffold(
      // Mengembalikan Scaffold.
      appBar: AppBar(
        // Bilah aplikasi.
        title: Text('Materi: ${widget.babJudul}'), // Judul AppBar.
        backgroundColor: Colors.indigo, // Warna Admin.
        foregroundColor: Colors.white, // Warna teks.
        actions: [
          // Aksi di sisi kanan AppBar.
          IconButton(
            // Tombol Refresh.
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Daftar Materi',
            onPressed: _fetchDaftarMateri,
          ),
        ],
      ),
      body:
          _isLoading // Cek status loading.
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Tampilkan loading.
          : _error !=
                null // Cek apakah ada error.
          ? Center(
              // Tampilkan pesan error.
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _daftarMateri
                .isEmpty // Cek apakah daftar materi kosong.
          ? const Center(
              // Tampilkan pesan kosong.
              child: Text('Belum ada materi ditambahkan untuk Bab ini.'),
            )
          : ListView.builder(
              // Jika ada data, tampilkan dalam list.
              padding: const EdgeInsets.all(8.0),
              itemCount: _daftarMateri.length,
              itemBuilder: (context, index) {
                // Fungsi pembuat item list.
                final materi = _daftarMateri[index];
                return Card(
                  // Menggunakan Card untuk setiap materi.
                  margin: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: ListTile(
                    // Item list.
                    title: Text(materi.judul), // Judul materi.
                    subtitle: Text(
                      // Deskripsi materi (maksimal 2 baris).
                      materi.deskripsi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // === NAVIGASI KE HALAMAN ADMIN DETAIL ===
                    onTap: () {
                      // Aksi saat item list diklik.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Navigasi ke AdminMateriDetailPage (detail materi dengan kontrol media & edit).
                          builder: (context) => AdminMateriDetailPage(
                            materiId: materi.id, // Meneruskan ID materi.
                            babJudul: widget.babJudul, // Meneruskan judul Bab.
                          ),
                        ),
                      ).then(
                        (_) => _fetchDaftarMateri(),
                      ); // Refresh list setelah kembali.
                    },

                    // === AKHIR NAVIGASI ===
                    trailing: PopupMenuButton<String>(
                      // Tombol menu opsi (Edit/Hapus).
                      icon: const Icon(Icons.more_vert),
                      onSelected: (String result) async {
                        if (result == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Memanggil AdminEditMateriPage
                              builder: (context) => AdminEditMateriPage(
                                // Mengirim MateriDetail sederhana (data lengkap akan di-fetch ulang di halaman Edit).
                                materi: MateriDetail(
                                  id: materi.id,
                                  judul: materi.judul,
                                  deskripsi: materi.deskripsi,
                                  youtubeUrl:
                                      null, // Dianggap null karena data ini belum ada di MateriItem.
                                  driveVideoUrl: null,
                                  driveFileUrl: null,
                                  audioUrl: null,
                                ),
                              ),
                            ),
                          ).then((updated) {
                            if (updated == true)
                              _fetchDaftarMateri(); // Refresh jika ada update.
                          });
                        } else if (result == 'delete') {
                          _hapusMateri(materi.id); // Panggil fungsi hapus.
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              // Opsi Edit.
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              // Opsi Hapus.
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                    ),
                  ),
                );
              },
            ),
      // Floating Action Button untuk menambah materi baru.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            // Navigasi ke form tambah materi.
            context,
            MaterialPageRoute(
              builder: (context) => AdminAddMateriForm(
                babId: widget.babId,
                babJudul: widget.babJudul,
              ),
            ),
          ).then((value) {
            _fetchDaftarMateri(); // Refresh list setelah kembali dari form tambah.
          });
        },
        label: const Text('Tambah Materi'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange, // Warna oranye untuk tombol tambah.
      ),
    );
  }
}
