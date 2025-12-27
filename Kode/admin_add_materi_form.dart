// lib/admin_add_materi_form.dart // Lokasi file: Menunjukkan ini adalah formulir untuk menambah materi.

import 'package:flutter/material.dart'; // Mengimpor pustaka Flutter Material untuk komponen UI.
import 'dart:convert'; // Mengimpor pustaka untuk encoding/decoding JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk permintaan jaringan.

class AdminAddMateriForm extends StatefulWidget {
  // Mendefinisikan widget Stateful (memiliki state yang bisa berubah).
  final String
  babId; // Variabel untuk menyimpan ID bab (diterima dari halaman sebelumnya).
  final String
  babJudul; // Variabel untuk menyimpan judul bab (diterima dari halaman sebelumnya).

  const AdminAddMateriForm({
    // Konstruktor kelas AdminAddMateriForm.
    super.key, // Key widget.
    required this.babId, // Wajib menerima ID bab.
    required this.babJudul, // Wajib menerima Judul bab.
  });
  @override // Menandai metode override.
  State<AdminAddMateriForm> createState() => _AdminAddMateriFormState(); // Membuat dan mengembalikan state.
}

class _AdminAddMateriFormState extends State<AdminAddMateriForm> {
  // Kelas state yang mengelola data widget.
  // Controllers for text fields // Pengendali untuk kolom teks.
  final _judulController =
      TextEditingController(); // Controller untuk judul materi.
  final _deskripsiController =
      TextEditingController(); // Controller untuk deskripsi materi.
  final _youtubeController =
      TextEditingController(); // Controller untuk link YouTube.
  final _driveVideoController =
      TextEditingController(); // Controller untuk link Video Google Drive.
  final _driveFileController =
      TextEditingController(); // Controller untuk link File Google Drive.
  final _audioController =
      TextEditingController(); // Controller untuk link Audio.
  bool _isLoading =
      false; // State boolean untuk melacak status loading tombol submit.

  // Function to submit new material data to the backend // Fungsi untuk mengirim data materi baru ke backend.
  Future<void> _tambahMateri() async {
    // Mendefinisikan fungsi asinkron untuk submit.
    // Basic validation // Validasi dasar.
    if (_judulController.text.isEmpty || _deskripsiController.text.isEmpty) {
      // Cek jika Judul atau Deskripsi kosong.
      ScaffoldMessenger.of(context).showSnackBar(
        // Menampilkan SnackBar (pesan singkat).
        const SnackBar(
          // Widget SnackBar.
          content: Text(
            'Judul dan Deskripsi tidak boleh kosong!',
          ), // Konten pesan peringatan.
          backgroundColor: Colors.orange, // Warna latar belakang oranye.
        ),
      );
      return; // Menghentikan eksekusi jika validasi gagal.
    }
    setState(() {
      // Memperbarui state UI.
      _isLoading = true; // Mengatur status loading menjadi true.
    });
    // !!! REPLACE WITH YOUR IP ADDRESS !!! // Komentar: Ganti dengan IP address server Anda.
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/materi',
    ); // Mendefinisikan URL API POST materi.

    try {
      // Memulai blok try-catch untuk menangani kesalahan jaringan/API.
      final response = await http.post(
        // Melakukan permintaan POST HTTP.
        url, // URL tujuan.
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'ngrok-skip-browser-warning': 'true',
        }, // Header: Menentukan format body adalah JSON.
        body: jsonEncode({
          // Mengubah data Dart Map menjadi string JSON.
          'babId': widget.babId, // Menyertakan ID bab spesifik.
          'judul': _judulController.text, // Data Judul Materi.
          'deskripsi': _deskripsiController.text, // Data Deskripsi Materi.
          'youtubeUrl':
              _youtubeController
                  .text
                  .isNotEmpty // Cek jika link YouTube tidak kosong.
              ? _youtubeController
                    .text // Jika tidak kosong, kirim nilainya.
              : null, // Jika kosong, kirim null.
          'driveVideoUrl':
              _driveVideoController
                  .text
                  .isNotEmpty // Cek link Video Drive.
              ? _driveVideoController
                    .text // Jika tidak kosong, kirim nilainya.
              : null, // Jika kosong, kirim null.
          'driveFileUrl':
              _driveFileController
                  .text
                  .isNotEmpty // Cek link File Drive.
              ? _driveFileController
                    .text // Jika tidak kosong, kirim nilainya.
              : null, // Jika kosong, kirim null.
          'audioUrl':
              _audioController
                  .text
                  .isNotEmpty // Cek link Audio.
              ? _audioController
                    .text // Jika tidak kosong, kirim nilainya.
              : null, // Jika kosong, kirim null.
        }),
      );

      if (mounted) {
        // Memastikan widget masih ada (mounted) sebelum memanggil setState/SnackBar.
        if (response.statusCode == 201) {
          // Jika status kode 201 (Created/Berhasil dibuat).
          // Success // Blok penanganan sukses.
          ScaffoldMessenger.of(context).showSnackBar(
            // Tampilkan SnackBar sukses.
            const SnackBar(
              content: Text('Materi berhasil ditambahkan'), // Pesan sukses.
              backgroundColor: Colors.green, // Warna latar belakang hijau.
            ),
          );
          // Clear all fields after success // Bersihkan semua field setelah sukses.
          _judulController.clear(); // Bersihkan field judul.
          _deskripsiController.clear(); // Bersihkan field deskripsi.
          _youtubeController.clear(); // Bersihkan field YouTube.
          _driveVideoController.clear(); // Bersihkan field video Drive.
          _driveFileController.clear(); // Bersihkan field file Drive.
          _audioController.clear(); // Bersihkan field audio.
          // Go back to the previous screen (material list) after success // Kembali ke halaman sebelumnya (daftar materi).
          Navigator.pop(
            // Fungsi untuk menutup halaman saat ini.
            context,
            true, // Mengirim nilai 'true' untuk mengindikasikan sukses (opsional).
          );
        } else {
          // Jika status kode bukan 201 (Error dari backend).
          // Handle backend error // Tangani kesalahan dari backend.
          ScaffoldMessenger.of(context).showSnackBar(
            // Tampilkan SnackBar error.
            SnackBar(
              content: Text(
                'Gagal: ${response.body}',
              ), // Pesan gagal dengan detail respon backend.
              backgroundColor: Colors.red, // Warna latar belakang merah.
            ),
          );
        }
      }
    } catch (e) {
      // Menangkap exception (misalnya, error koneksi jaringan).
      // Handle connection error // Tangani kesalahan koneksi.
      if (mounted) {
        // Memastikan widget masih mounted.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ), // Menampilkan pesan error koneksi.
        );
      }
    } finally {
      // Blok yang selalu dieksekusi, terlepas dari hasil try/catch.
      // Stop loading indicator // Menghentikan indikator loading.
      if (mounted) {
        // Memastikan widget masih mounted.
        setState(() {
          // Memperbarui state.
          _isLoading = false; // Mengatur status loading menjadi false.
        });
      }
    }
  }

  // Clean up controllers when the widget is disposed // Membersihkan controller saat widget dibuang untuk mencegah memory leak.
  @override // Menandai metode override.
  void dispose() {
    // Dipanggil saat State object dihapus.
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
    // Metode yang membangun UI widget.
    return Scaffold(
      // Mengembalikan Scaffold sebagai struktur halaman dasar.
      appBar: AppBar(
        // Bilah aplikasi di bagian atas.
        title: Text(
          'Tambah Materi: ${widget.babJudul}',
        ), // Menampilkan judul halaman dan judul bab.
      ), // Show chapter title in AppBar
      body: SingleChildScrollView(
        // Konten utama yang dapat di-scroll (jika overflow).
        // Allows scrolling if content overflows
        padding: const EdgeInsets.all(16.0), // Padding 16 di sekeliling konten.
        child: Column(
          // Mengatur widget anak secara vertikal.
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Membuat elemen anak meregang penuh lebar horizontal.
          children: [
            // Daftar widget anak.
            Text(
              // Teks judul formulir.
              'Detail Materi (Bab: ${widget.babJudul})', // Teks detail materi.
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ), // Gaya teks.
            ),
            const SizedBox(height: 16), // Spasi vertikal 16.
            TextField(
              // Kolom input untuk Judul Materi.
              controller: _judulController, // Terhubung ke controller judul.
              decoration: const InputDecoration(
                // Dekorasi input.
                labelText: 'Judul Materi', // Label teks.
                border: OutlineInputBorder(), // Garis batas luar.
              ),
            ),
            const SizedBox(height: 16), // Spasi vertikal 16.
            TextField(
              // Kolom input untuk Deskripsi Materi.
              controller:
                  _deskripsiController, // Terhubung ke controller deskripsi.
              maxLines: 5, // Mengizinkan input hingga 5 baris.
              decoration: const InputDecoration(
                // Dekorasi input.
                labelText: 'Deskripsi Materi', // Label teks.
                border: OutlineInputBorder(), // Garis batas luar.
                alignLabelWithHint:
                    true, // Meratakan label dengan hint untuk input multiline.
              ),
            ),
            const SizedBox(height: 16), // Spasi vertikal 16.
            TextField(
              // Kolom input untuk Link Video YouTube.
              controller:
                  _youtubeController, // Terhubung ke controller YouTube.
              decoration: const InputDecoration(
                labelText: 'Link Video YouTube (Opsional)', // Label opsional.
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url, // Jenis keyboard URL.
            ),
            const SizedBox(height: 16), // Spasi vertikal 16.
            TextField(
              // Kolom input untuk Link Video Google Drive.
              controller:
                  _driveVideoController, // Terhubung ke controller video Drive.
              decoration: const InputDecoration(
                labelText: 'Link Video Google Drive (Opsional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url, // Jenis keyboard URL.
            ),
            const SizedBox(height: 16), // Spasi vertikal 16.
            TextField(
              // Kolom input untuk Link File Google Drive.
              controller:
                  _driveFileController, // Terhubung ke controller file Drive.
              decoration: const InputDecoration(
                labelText: 'Link File Google Drive (Opsional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url, // Jenis keyboard URL.
            ),
            const SizedBox(height: 16), // Spasi vertikal 16.
            TextField(
              // Kolom input untuk Link Audio.
              controller: _audioController, // Terhubung ke controller audio.
              decoration: const InputDecoration(
                labelText: 'Link Audio (Opsional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url, // Jenis keyboard URL.
            ),
            const SizedBox(height: 24), // Spasi vertikal 24 sebelum tombol.
            ElevatedButton(
              // Tombol untuk mengirim data.
              // Submit button
              onPressed:
                  _isLoading // Cek status loading.
                  ? null // Jika loading, tombol dinonaktifkan (null).
                  : _tambahMateri, // Jika tidak loading, panggil fungsi submit.
              style: ElevatedButton.styleFrom(
                // Gaya tombol.
                backgroundColor:
                    Colors.indigo, // Warna latar belakang biru-ungu.
                foregroundColor: Colors.white, // Warna teks/ikon putih.
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ), // Padding vertikal internal.
              ),
              child:
                  _isLoading // Cek status loading.
                  ? const SizedBox(
                      // Jika loading, tampilkan indikator.
                      height: 20, // Tinggi indikator.
                      width: 20, // Lebar indikator.
                      child: CircularProgressIndicator(
                        // Indikator loading melingkar.
                        color: Colors.white, // Warna putih.
                        strokeWidth: 3, // Ketebalan garis.
                      ),
                    )
                  : const Text(
                      'Simpan Detail Materi',
                    ), // Jika tidak loading, tampilkan teks tombol.
            ),
          ],
        ),
      ),
    );
  }
}
