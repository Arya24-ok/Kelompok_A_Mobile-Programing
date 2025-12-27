// lib/admin_hasil_kuis_page.dart
// Halaman untuk admin melihat semua hasil kuis dari siswa

import 'package:flutter/material.dart'; // Import pustaka Flutter UI
import 'dart:convert'; // Import pustaka untuk JSON encoding/decoding
import 'package:http/http.dart' as http; // Import pustaka HTTP untuk API
import 'package:visualink_app/kuis_models.dart'; // Import model data (asumsi HasilSiswa ada di sini)
import 'package:intl/intl.dart'; // Import pustaka untuk format tanggal
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences untuk penyimpanan token [PERBAIKAN]

class AdminHasilKuisPage extends StatefulWidget {
  // Mendefinisikan StatefulWidget untuk halaman hasil kuis admin
  final String kuisId; // Variabel wajib: ID kuis yang hasilnya akan ditampilkan
  final String kuisJudul; // Variabel wajib: Judul kuis

  const AdminHasilKuisPage({
    // Constructor
    super.key,
    required this.kuisId, // ID kuis
    required this.kuisJudul, // Judul kuis
  });

  @override
  State<AdminHasilKuisPage> createState() =>
      _AdminHasilKuisPageState(); // Membuat state
}

class _AdminHasilKuisPageState extends State<AdminHasilKuisPage> {
  // Kelas State

  List<HasilSiswa> _daftarHasil =
      []; // Variabel untuk menyimpan daftar hasil kuis dari siswa
  bool _isLoading = true; // Status loading data
  String? _error; // Variabel untuk menyimpan pesan error

  @override
  void initState() {
    // Dipanggil saat widget dibuat
    super.initState();
    _fetchHasilSiswa(); // Memuat data hasil kuis segera
  }

  Future<void> _fetchHasilSiswa() async {
    // Fungsi untuk mengambil data hasil kuis dari API
    setState(() {
      // Mulai proses loading
      _isLoading = true;
      _error = null;
    });

    // Ganti IP di sini
    final url = Uri.parse(
      // URL endpoint API untuk mengambil hasil kuis
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/kuis/${widget.kuisId}/hasil',
    );

    try {
      // 1. Ambil token admin yang tersimpan dari SharedPreferences
      final prefs = await SharedPreferences
          .getInstance(); // Mendapatkan instance SharedPreferences
      // [PERBAIKAN] Mengambil dari 'userToken' (key yang digunakan saat login)
      String? token = prefs.getString('userToken'); // Mengambil token

      if (token == null) {
        // Jika token tidak ada
        if (!mounted) return; // Cek status widget
        setState(() {
          _error =
              'Error: Sesi Anda berakhir. Silakan login ulang.'; // Set pesan error otentikasi
          _isLoading = false;
        });
        return; // Hentikan fungsi
      }

      // 2. Lakukan permintaan GET dengan menyertakan token di header
      final response = await http.get(
        // Melakukan permintaan GET
        url,
        headers: {
          'Content-Type': 'application/json',
          // [PERBAIKAN]: Menggunakan header yang disinkronkan dengan backend
          'x-auth-token': token, // Menyertakan token untuk otentikasi
          // [TAMBAHAN BARU] Header wajib untuk bypass Ngrok warning page
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (!mounted) return; // Cek status widget setelah async call

      // Debugging output
      print("Fetch Hasil Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Sukses (Status 200 OK)
        final List<dynamic> data = jsonDecode(response.body); // Decode JSON
        setState(() {
          _daftarHasil = // Memetakan data JSON ke list model HasilSiswa
              data.map((json) => HasilSiswa.fromJson(json)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // Belum ada hasil (Status 404 Not Found)
        setState(() {
          _daftarHasil = []; // Set list kosong
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Error otentikasi (Status 401 Unauthorized)
        setState(() {
          _error =
              'Error 401: Token tidak valid atau sesi habis. Silakan login ulang.'; // Set pesan error otentikasi
          _isLoading = false;
        });
      } else {
        // Error status code lainnya
        // Coba baca body error jika ada
        String errorMsg = 'Gagal memuat hasil: Status ${response.statusCode}';
        try {
           // Jika body mengandung pesan error HTML ngrok, tampilkan sebagian
           if(response.body.contains("<!DOCTYPE html>")) {
             errorMsg += " (HTML Error/Ngrok Issue)";
           } else {
             errorMsg += " - ${response.body}";
           }
        } catch (_) {}

        throw Exception(errorMsg); // Lempar exception
      }
    } catch (e) {
      // Menangkap error umum (koneksi, dll.)
      if (!mounted) return;
      setState(() {
        _error = 'Error: ${e.toString()}'; // Set pesan error
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Metode pembangunan UI
    return Scaffold(
      appBar: AppBar(
        // AppBar (kepala halaman)
        title: Text(
          // Judul AppBar
          'Hasil Kuis - ${widget.kuisJudul}',
          overflow: TextOverflow
              .ellipsis, // Jika judul terlalu panjang, tampilkan elipsis
        ),
        backgroundColor: Colors.indigo, // Warna latar belakang AppBar
        foregroundColor: Colors.white, // Warna ikon dan teks
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Ikon refresh
            tooltip: 'Refresh',
            onPressed:
                _fetchHasilSiswa, // Panggil fungsi ambil data saat tombol ditekan
          ),
        ],
      ),
      body: _isLoading // Konten utama halaman
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Tampilkan loading spinner jika isLoading true
          : _error !=
                  null // Jika ada error
              ? Center(
                  // Tampilkan pesan error
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!, // Pesan error
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                )
              : _daftarHasil
                      .isEmpty // Jika tidak loading, tidak error, dan daftar hasil kosong
                  ? const Center(
                      // Tampilkan pesan data kosong
                      child: Text(
                        'Belum ada siswa yang mengerjakan kuis ini.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      // Tampilkan daftar hasil jika ada data
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _daftarHasil.length, // Jumlah item dalam daftar
                      itemBuilder: (context, index) {
                        // Fungsi pembuat item daftar
                        final hasil = _daftarHasil[index]; // Hasil siswa saat ini
                        return Card(
                          // Menggunakan Card untuk setiap item hasil
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            // Item daftar standar
                            leading: CircleAvatar(
                              // Lingkaran di sebelah kiri menampilkan skor
                              backgroundColor: hasil.skor >=
                                      75 // Warna background Avatar (Hijau jika skor >= 75, Merah jika < 75)
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              foregroundColor: hasil.skor >=
                                      75 // Warna teks Avatar
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              child: Text(
                                hasil.skor.toString(), // Tampilkan skor
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              // Judul ListTile (Username Siswa)
                              hasil.username,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              // Subjudul ListTile (Tanggal Pengerjaan)
                              'Dikerjakan: ${DateFormat('dd MMM yyyy, HH:mm').format(hasil.tanggal.toLocal())}', // Format tanggal
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}