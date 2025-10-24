// lib/admin_edit_materi_page.dart // Lokasi file: Halaman untuk mengedit detail materi.

import 'package:flutter/material.dart'; // Mengimpor pustaka Flutter Material untuk komponen UI.
import 'dart:convert'; // Mengimpor pustaka untuk encoding/decoding JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk permintaan jaringan.
// Import model MateriDetail
import 'package:visualink_app/materi_detail_page.dart'
    show MateriDetail; // Mengimpor definisi model data MateriDetail.

class AdminEditMateriPage extends StatefulWidget {
  // Mendefinisikan widget Stateful untuk halaman edit.
  // Terima data materi yang akan diedit
  final MateriDetail
  materi; // Variabel final untuk menyimpan objek data materi yang akan diedit.

  const AdminEditMateriPage({
    super.key,
    required this.materi,
  }); // Konstruktor yang wajib menerima objek materi.

  @override // Menandai metode override.
  State<AdminEditMateriPage> createState() => _AdminEditMateriPageState(); // Membuat dan mengembalikan state.
}

class _AdminEditMateriPageState extends State<AdminEditMateriPage> {
  // Kelas state yang mengelola data dan perilaku widget.
  // Controller diinisialisasi dengan data awal
  late TextEditingController
  _judulController; // Deklarasi controller untuk judul (akan diinisialisasi nanti).
  late TextEditingController
  _deskripsiController; // Deklarasi controller untuk deskripsi.
  late TextEditingController
  _youtubeController; // Deklarasi controller untuk link YouTube.
  late TextEditingController
  _driveVideoController; // Deklarasi controller untuk link Video Drive.
  late TextEditingController
  _driveFileController; // Deklarasi controller untuk link File Drive.
  late TextEditingController
  _audioController; // Deklarasi controller untuk link Audio.
  bool _isLoading =
      false; // State boolean untuk melacak status loading tombol submit.

  @override // Menandai metode override.
  void initState() {
    // Dipanggil sekali saat objek State pertama kali dibuat.
    super.initState(); // Memanggil initState kelas induk.
    // Isi controller dengan data materi yang diterima
    _judulController = TextEditingController(
      text: widget.materi.judul,
    ); // Inisialisasi controller Judul dengan data materi.
    _deskripsiController = TextEditingController(
      text: widget.materi.deskripsi,
    ); // Inisialisasi controller Deskripsi.
    _youtubeController = TextEditingController(
      // Inisialisasi controller YouTube.
      text:
          widget.materi.youtubeUrl ??
          '', // Menggunakan data YouTube URL, jika null gunakan string kosong.
    );
    // Inisialisasi controller lain jika ada datanya di MateriDetail
    // CATATAN: Kode asli di bawah ini TIDAK menggunakan data materi.id untuk inisialisasi controller lain.
    _driveVideoController = TextEditingController(
      text: widget.materi.driveVideoUrl ?? '',
    ); // Mengisi dengan data Video Drive.
    _driveFileController = TextEditingController(
      text: widget.materi.driveFileUrl ?? '',
    ); // Mengisi dengan data File Drive.
    _audioController = TextEditingController(
      text: widget.materi.audioUrl ?? '',
    ); // Mengisi dengan data Audio.
  }

  Future<void> _simpanPerubahan() async {
    // Fungsi asinkron untuk menyimpan perubahan ke backend.
    if (_judulController.text.isEmpty || _deskripsiController.text.isEmpty) {
      // Validasi dasar: Cek Judul atau Deskripsi kosong.
      /* ... validasi ... */
      // Tambahan: Menampilkan SnackBar untuk validasi yang hilang.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan Deskripsi tidak boleh kosong!'),
          backgroundColor: Colors.orange,
        ),
      );
      return; // Menghentikan eksekusi jika validasi gagal.
    }
    setState(() {
      // Memperbarui state UI.
      _isLoading = true; // Mengatur status loading menjadi true.
    });
    // !!! GANTI IP ANDA !!! // Komentar: Ganti dengan IP address server Anda.
    // Gunakan endpoint PUT dengan ID materi
    final url = Uri.parse(
      'http://192.168.1.17/materi/${widget.materi.id}',
    ); // Mendefinisikan URL API PUT, menyertakan ID materi.

    try {
      // Memulai blok try-catch untuk penanganan error.
      final response = await http.put(
        // Melakukan permintaan PUT HTTP.
        // <-- Gunakan http.put
        url, // URL tujuan.
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        }, // Header: Menentukan format body adalah JSON.
        body: jsonEncode({
          // Mengubah data Dart Map menjadi string JSON.
          'judul': _judulController.text, // Mengirim data Judul Materi.
          'deskripsi':
              _deskripsiController.text, // Mengirim data Deskripsi Materi.
          'youtubeUrl':
              _youtubeController
                  .text
                  .isNotEmpty // Cek link YouTube.
              ? _youtubeController.text
              : null, // Kirim null jika kosong.
          'driveVideoUrl':
              _driveVideoController
                  .text
                  .isNotEmpty // Cek link Video Drive.
              ? _driveVideoController.text
              : null, // Kirim null jika kosong.
          'driveFileUrl':
              _driveFileController
                  .text
                  .isNotEmpty // Cek link File Drive.
              ? _driveFileController.text
              : null, // Kirim null jika kosong.
          'audioUrl':
              _audioController
                  .text
                  .isNotEmpty // Cek link Audio.
              ? _audioController.text
              : null, // Kirim null jika kosong.
        }),
      );

      if (mounted) {
        // Memastikan widget masih ada.
        if (response.statusCode == 200) {
          // Jika status kode 200 (OK/Sukses update).
          // Sukses update biasanya 200 OK // Komentar sukses.
          ScaffoldMessenger.of(context).showSnackBar(
            // Tampilkan SnackBar sukses.
            const SnackBar(
              content: Text('Materi berhasil diperbarui'), // Pesan sukses.
              backgroundColor: Colors.green, // Warna hijau.
            ),
          );
          // Kembali ke halaman detail dengan membawa sinyal sukses
          Navigator.pop(
            context,
            true,
          ); // Menutup halaman edit, mengirim 'true' (sinyal perubahan).
        } else {
          // Jika terjadi error (selain 200).
          ScaffoldMessenger.of(context).showSnackBar(
            // Tampilkan SnackBar error backend.
            SnackBar(
              content: Text(
                'Gagal memperbarui: ${response.body}',
              ), // Pesan gagal dengan detail respon backend.
              backgroundColor: Colors.red, // Warna merah.
            ),
          );
        }
      }
    } catch (e) {
      // Menangkap exception (misalnya, error koneksi).
      /* ... handle error ... */
      // Tambahan: Menampilkan SnackBar untuk error koneksi yang hilang.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error Koneksi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Blok yang selalu dieksekusi.
      if (mounted) {
        // Memastikan widget masih mounted.
        setState(() {
          // Memperbarui state.
          _isLoading = false; // Mengatur status loading menjadi false.
        });
      }
    }
  }

  @override // Menandai metode override.
  void dispose() {
    // Dipanggil saat State object dihapus dari pohon widget.
    /* ... dispose semua controller ... */
    _judulController.dispose(); // Membuang controller judul.
    _deskripsiController.dispose(); // Membuang controller deskripsi.
    _youtubeController.dispose(); // Membuang controller YouTube.
    _driveVideoController.dispose(); // Membuang controller video Drive.
    _driveFileController.dispose(); // Membuang controller file Drive.
    _audioController.dispose(); // Membuang controller audio.
    super.dispose(); // Memanggil dispose kelas induk.
  }

  @override // Menandai metode override.
  Widget build(BuildContext context) {
    // Metode yang membangun UI.
    return Scaffold(
      // Mengembalikan Scaffold.
      appBar: AppBar(
        title: Text('Edit Materi: ${widget.materi.judul}'),
      ), // AppBar dengan judul materi yang diedit.
      body: SingleChildScrollView(
        // Konten utama yang dapat di-scroll.
        padding: const EdgeInsets.all(16.0), // Padding 16 di sekeliling.
        child: Column(
          // Mengatur widget anak secara vertikal.
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Meregangkan elemen anak secara horizontal.
          children: [
            // Daftar widget anak.
            Text(
              // Teks judul bagian.
              'Edit Detail Materi',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ), // Gaya teks tebal.
            ),
            const SizedBox(height: 16), // Spasi vertikal.
            TextField(
              // Kolom input untuk Judul Materi.
              controller: _judulController, // Terhubung ke controller Judul.
              decoration: const InputDecoration(
                labelText: 'Judul Materi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16), // Spasi vertikal.
            TextField(
              // Kolom input untuk Deskripsi Materi.
              controller:
                  _deskripsiController, // Terhubung ke controller Deskripsi.
              maxLines: 5, // Input multiline.
              decoration: const InputDecoration(
                labelText: 'Deskripsi Materi',
                border: OutlineInputBorder(),
                alignLabelWithHint:
                    true, // Penempatan label yang baik untuk multiline.
              ),
            ),
            const SizedBox(height: 16), // Spasi vertikal.
            TextField(
              // Kolom input untuk Link Video YouTube.
              controller:
                  _youtubeController, // Terhubung ke controller YouTube.
              decoration: const InputDecoration(
                labelText: 'Link Video YouTube (Opsional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url, // Jenis keyboard URL.
            ),
            const SizedBox(height: 16), // Spasi vertikal.
            TextField(
              // Kolom input untuk Link Video Google Drive.
              controller:
                  _driveVideoController, // Terhubung ke controller Video Drive.
              decoration: const InputDecoration(
                labelText: 'Link Video Google Drive (Opsional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url, // Jenis keyboard URL.
            ),
            const SizedBox(height: 16), // Spasi vertikal.
            TextField(
              // Kolom input untuk Link File Google Drive.
              controller:
                  _driveFileController, // Terhubung ke controller File Drive.
              decoration: const InputDecoration(
                labelText: 'Link File Google Drive (Opsional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url, // Jenis keyboard URL.
            ),
            const SizedBox(height: 16), // Spasi vertikal.
            TextField(
              // Kolom input untuk Link Audio.
              controller: _audioController, // Terhubung ke controller Audio.
              decoration: const InputDecoration(
                labelText: 'Link Audio (Opsional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url, // Jenis keyboard URL.
            ),
            const SizedBox(height: 24), // Spasi vertikal sebelum tombol.
            ElevatedButton(
              // Tombol Simpan Perubahan.
              onPressed:
                  _isLoading // Cek status loading.
                  ? null // Jika loading, tombol dinonaktifkan.
                  : _simpanPerubahan, // Panggil fungsi simpan perubahan.
              style: ElevatedButton.styleFrom(
                // Gaya tombol.
                backgroundColor: Colors.indigo, // Warna latar belakang.
                foregroundColor: Colors.white, // Warna teks.
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ), // Padding internal.
              ),
              child:
                  _isLoading // Cek status loading.
                  ? const SizedBox(
                      // Jika loading, tampilkan indikator.
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        // Indikator loading.
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Simpan Perubahan',
                    ), // Jika tidak loading, tampilkan teks.
            ),
          ],
        ),
      ),
    );
  }
}
