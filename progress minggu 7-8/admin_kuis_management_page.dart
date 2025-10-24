// lib/admin_kuis_management_page.dart // Lokasi file: Halaman untuk mengelola daftar kuis dalam satu Bab (Admin).

import 'package:flutter/material.dart'; // Mengimpor pustaka Flutter Material.
import 'dart:convert'; // Mengimpor pustaka untuk encoding/decoding JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk permintaan jaringan.
import 'package:visualink_app/kuis_models.dart'; // Import model data kuis (misalnya KuisItem).
import 'package:visualink_app/admin_kuis_detail_page.dart'; // Import halaman detail kuis untuk navigasi.

class AdminKuisManagementPage extends StatefulWidget {
  // Mendefinisikan widget Stateful.
  final String babId; // Variabel final untuk menyimpan ID Bab.
  final String babJudul; // Variabel final untuk menyimpan Judul Bab.
  const AdminKuisManagementPage({
    // Konstruktor.
    super.key,
    required this.babId, // Wajib menerima ID Bab.
    required this.babJudul, // Wajib menerima Judul Bab.
  });
  @override // Menandai metode override.
  State<AdminKuisManagementPage> createState() =>
      _AdminKuisManagementPageState(); // Membuat dan mengembalikan state.
}

class _AdminKuisManagementPageState extends State<AdminKuisManagementPage> {
  // Kelas state.
  List<KuisItem> _daftarKuis =
      []; // List untuk menyimpan daftar kuis dalam Bab ini.
  bool _isLoading = true; // State boolean untuk melacak status loading data.
  String?
  _error; // Variabel untuk menyimpan pesan error jika terjadi kegagalan fetch data.

  @override // Menandai metode override.
  void initState() {
    // Dipanggil sekali saat objek State dibuat.
    super.initState();
    _fetchDaftarKuis(); // Memulai pengambilan data daftar kuis.
  }

  Future<void> _fetchDaftarKuis() async {
    // Fungsi asinkron untuk mengambil daftar kuis dari API.
    setState(() {
      // Memperbarui state UI.
      _isLoading = true; // Mengatur loading menjadi true.
      _error = null; // Menghapus error sebelumnya.
    });
    // URL API untuk mengambil semua kuis di bawah Bab tertentu.
    final url = Uri.parse('http://192.168.1.17:3000/bab/${widget.babId}/kuis');
    try {
      // Blok try-catch untuk penanganan error jaringan.
      final response = await http.get(url); // Melakukan permintaan GET HTTP.
      if (!mounted) return; // Keluar jika widget sudah tidak ada (unmounted).
      if (response.statusCode == 200) {
        // Jika status kode 200 (Sukses).
        final List<dynamic> data = jsonDecode(
          response.body,
        ); // Mendecode body response JSON.
        setState(() {
          // Memperbarui state.
          _daftarKuis = data
              .map((json) => KuisItem.fromJson(json))
              .toList(); // Memetakan data JSON ke list objek KuisItem.
          _isLoading = false; // Mengatur loading menjadi false.
        });
      } else {
        // Jika status kode bukan 200.
        if (response.statusCode == 404) // Jika 404 (tidak ditemukan/kosong).
          setState(() {
            _daftarKuis = []; // Mengosongkan daftar kuis.
            _isLoading = false; // Mengatur loading menjadi false.
          });
        else // Untuk error status code lainnya.
          throw Exception(
            'Gagal memuat Kuis: Status ${response.statusCode}',
          ); // Melemparkan exception.
      }
    } catch (e) {
      // Menangkap exception (error koneksi, dll.).
      if (!mounted) return; // Keluar jika widget unmounted.
      setState(() {
        // Memperbarui state error.
        _error = 'Error: ${e.toString()}'; // Menyimpan pesan error.
        _isLoading = false; // Mengatur loading menjadi false.
      });
    }
  }

  Future<void> _tambahKuisBaru(String judul, String deskripsi) async {
    // Fungsi asinkron untuk menambah kuis baru.
    if (judul.isEmpty) {
      // Validasi: Judul tidak boleh kosong.
      /* validasi */
      // Tambahan: Menampilkan SnackBar untuk validasi.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul kuis tidak boleh kosong.'),
          backgroundColor: Colors.orange,
        ),
      );
      return; // Batalkan proses.
    }
    // URL API POST kuis baru di bawah Bab tertentu.
    final url = Uri.parse('http://192.168.1.17:3000/bab/${widget.babId}/kuis');
    try {
      // Blok try-catch.
      final response = await http.post(
        // Melakukan permintaan POST.
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        }, // Header JSON.
        body: jsonEncode({
          'judul': judul,
          'deskripsi': deskripsi,
        }), // Data yang dikirim.
      );
      if (!mounted) return; // Cek mounted.
      if (response.statusCode == 201) {
        // Jika sukses dibuat (kode 201).
        _fetchDaftarKuis(); // Refresh daftar kuis.
        Navigator.pop(context); // Tutup dialog tambah kuis.
        ScaffoldMessenger.of(context).showSnackBar(
          // Tampilkan SnackBar sukses.
          const SnackBar(
            content: Text('Kuis baru berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Jika gagal.
        final errorData = jsonDecode(response.body); // Mendecode data error.
        Navigator.pop(context); // Tutup dialog (meskipun gagal).
        ScaffoldMessenger.of(context).showSnackBar(
          // Tampilkan SnackBar error.
          SnackBar(
            content: Text('Gagal: ${errorData['msg'] ?? response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Menangkap error koneksi/lainnya.
      if (!mounted) return; // Cek mounted.
      Navigator.pop(context); // Tutup dialog (meskipun error).
      ScaffoldMessenger.of(context).showSnackBar(
        // Tampilkan SnackBar error koneksi.
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddKuisDialog() {
    // Fungsi untuk menampilkan dialog tambah kuis.
    final TextEditingController judulController =
        TextEditingController(); // Controller Judul.
    final TextEditingController deskripsiController =
        TextEditingController(); // Controller Deskripsi.
    showDialog(
      // Menampilkan dialog.
      context: context,
      builder: (BuildContext dialogContext) {
        // Builder untuk konten dialog.
        return AlertDialog(
          // Mengembalikan AlertDialog.
          title: const Text('Tambah Kuis Baru'), // Judul dialog.
          content: Column(
            // Konten dialog (Judul dan Deskripsi).
            mainAxisSize: MainAxisSize.min, // Ukuran kolom minimal.
            children: [
              TextField(
                // Field Judul Kuis.
                controller: judulController,
                decoration: const InputDecoration(hintText: "Judul Kuis"),
                autofocus: true, // Auto fokus ke field ini.
              ),
              const SizedBox(height: 8), // Spasi.
              TextField(
                // Field Deskripsi Kuis.
                controller: deskripsiController,
                decoration: const InputDecoration(
                  hintText: "Deskripsi (Opsional)",
                ),
                maxLines: 2, // Maksimal 2 baris.
              ),
            ],
          ),
          actions: [
            // Aksi (tombol) di bagian bawah dialog.
            TextButton(
              // Tombol Batal.
              onPressed: () => Navigator.pop(dialogContext), // Menutup dialog.
              child: const Text('Batal'),
            ),
            TextButton(
              // Tombol Simpan.
              onPressed: () => _tambahKuisBaru(
                // Memanggil fungsi tambah kuis baru.
                judulController.text,
                deskripsiController.text,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleNilaiTampil(KuisItem kuis, bool newValue) async {
    // Fungsi asinkron untuk mengubah status tampilan nilai kuis.
    int index = _daftarKuis.indexWhere(
      (k) => k.id == kuis.id,
    ); // Mencari indeks kuis dalam list lokal.
    if (index != -1) // Jika kuis ditemukan.
      setState(() {
        // Perubahan: Menggunakan copyWith untuk update properti pada model (immutable)
        _daftarKuis[index] = kuis.copyWith(
          nilaiTampil: newValue,
        ); // Perbarui nilaiTampil secara lokal (optimistic update) menggunakan copyWith.
      });

    // URL API PUT untuk mengupdate kuis tertentu.
    final url = Uri.parse('http://192.168.1.17:3000/kuis/${kuis.id}');
    try {
      // Blok try-catch.
      final response = await http.put(
        // Melakukan permintaan PUT.
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        }, // Header JSON.
        body: jsonEncode({
          'nilaiTampil': newValue,
        }), // Mengirim data nilaiTampil baru.
      );
      if (!mounted) return; // Cek mounted.
      if (response.statusCode != 200) {
        // Jika status kode bukan 200 (gagal update).
        if (index != -1)
          setState(() {
            // Kembalikan nilaiTampil ke nilai semula (roll back).
            _daftarKuis[index] = kuis.copyWith(
              nilaiTampil: !newValue,
            ); // Rollback dengan copyWith.
          });
        ScaffoldMessenger.of(context).showSnackBar(
          // Tampilkan SnackBar error.
          SnackBar(
            content: Text('Gagal update: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Menangkap error koneksi.
      if (index != -1)
        setState(() {
          // Kembalikan nilaiTampil ke nilai semula.
          _daftarKuis[index] = kuis.copyWith(
            nilaiTampil: !newValue,
          ); // Rollback dengan copyWith.
        });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          // Tampilkan SnackBar error koneksi.
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
        title: Text(
          'Kelola Kuis - ${widget.babJudul}',
        ), // Judul AppBar (menyertakan judul Bab).
        backgroundColor: Colors.indigo, // Warna latar belakang AppBar.
        foregroundColor: Colors.white, // Warna teks/ikon AppBar.
        actions: [
          // Aksi di sisi kanan AppBar.
          IconButton(
            // Tombol Tambah Kuis Baru.
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Tambah Kuis Baru',
            onPressed: _showAddKuisDialog, // Memanggil fungsi tampilkan dialog.
          ),
          IconButton(
            // Tombol Refresh.
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Daftar Kuis',
            onPressed: _fetchDaftarKuis, // Memanggil fungsi refresh data.
          ),
        ],
      ),
      body:
          _isLoading // Cek status loading.
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Jika loading, tampilkan indikator loading.
          : _error !=
                null // Cek apakah ada error.
          ? Center(
              // Jika ada error, tampilkan pesan error.
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _daftarKuis
                .isEmpty // Cek apakah daftar kuis kosong.
          ? const Center(
              // Jika kosong, tampilkan pesan.
              child: Text(
                'Belum ada kuis untuk Bab ini. Tekan + untuk menambah.',
              ),
            )
          : ListView.builder(
              // Jika ada data, tampilkan dalam list.
              padding: const EdgeInsets.all(
                8.0,
              ), // Padding di sekitar ListView.
              itemCount: _daftarKuis.length, // Jumlah item.
              itemBuilder: (context, index) {
                // Fungsi pembuat item.
                final kuis = _daftarKuis[index]; // Mengambil objek kuis.
                return Card(
                  // Menggunakan Card untuk setiap kuis.
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    // Item list.
                    title: Text(kuis.judul), // Judul Kuis.
                    trailing: Row(
                      // Widget di sisi kanan (Switch dan Arrow).
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          // Tooltip untuk tombol Switch.
                          message:
                              kuis
                                  .nilaiTampil // Pesan tooltip berdasarkan status.
                              ? 'Nilai ditampilkan'
                              : 'Nilai disembunyikan',
                          child: Switch(
                            // Widget Switch untuk toggle nilaiTampil.
                            value: kuis.nilaiTampil, // Nilai boolean saat ini.
                            onChanged:
                                (bool value) => // Fungsi saat Switch diubah.
                                _toggleNilaiTampil(
                                  kuis,
                                  value,
                                ), // Memanggil fungsi update nilaiTampil.
                            activeColor: Colors.green, // Warna aktif.
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ), // Ikon panah.
                      ],
                    ),
                    onTap: () {
                      // Fungsi saat item list diklik.
                      Navigator.push(
                        // Navigasi ke halaman detail kuis.
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminKuisDetailPage(
                            kuisId: kuis.id, // Meneruskan ID kuis.
                            kuisJudul: kuis.judul, // Meneruskan Judul kuis.
                          ),
                        ),
                      ).then(
                        (_) => _fetchDaftarKuis(),
                      ); // Setelah kembali dari halaman detail, refresh daftar kuis.
                    },
                  ),
                );
              },
            ),
    );
  }
}
