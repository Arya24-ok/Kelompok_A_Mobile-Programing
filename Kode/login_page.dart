// lib/login_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visualink_app/home_page.dart';
import 'package:visualink_app/admin_page.dart';

// Widget utama (Stateless) untuk Halaman Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Stateful Widget untuk mengelola input form dan proses login
class _LoginPageState extends State<LoginPage> {
  // Controller untuk mengambil teks dari TextField username
  final _usernameController = TextEditingController();
  // Controller untuk mengambil teks dari TextField password
  final _passwordController = TextEditingController();

  // State untuk mengontrol status loading saat tombol ditekan
  bool _isLoading = false;

  // Fungsi untuk membersihkan controller dari memori saat halaman ditutup
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi utama yang dijalankan saat tombol login ditekan
  Future<void> _handleLogin() async {
    // Ambil teks yang diketik pengguna dari masing-masing TextField
    final username = _usernameController.text;
    final password = _passwordController.text;

    // Aktifkan status loading
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/login',
    );

    // Gunakan try-catch untuk menangani error jika koneksi ke server gagal total
    try {
      // Kirim data ke server menggunakan method POST dan tunggu jawabannya
      final response = await http.post(
        url,
        // Beri tahu server bahwa format data yang dikirim adalah JSON
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        // Ubah data username & password dari format Dart ke format string JSON
        body: jsonEncode({'username': username, 'password': password}),
      );

      // Cek apakah widget masih ada di layar
      if (!mounted) {
        return;
      }

      // Nonaktifkan status loading setelah respons diterima
      setState(() {
        _isLoading = false;
      });

      // Cek status jawaban dari server. Kode 200 artinya "OK" atau sukses.
      if (response.statusCode == 200) {
        // Jika sukses, parsing balasan JSON
        final data = jsonDecode(response.body);

        // --- DEBUGGING: CETAK RESPON LENGKAP SERVER ---
        print('--- RESPON LOGIN BERHASIL (DEBUG) ---');
        print('Response Body: ${response.body}');
        print('-------------------------------------');
        // --- END DEBUGGING ---

        // Ambil nilai 'role', 'username', dan **AMBIL TOKEN DENGAN KEY YANG BENAR**
        final String role = data['role'];
        final String loggedInUsername = data['username'];

        // [PERBAIKAN FINAL]: Ambil token langsung dari root key 'token'
        final String? token = data['token']; // KODE SUDAH BENAR

        if (token != null) {
          // [LOGIKA OTORISASI] Simpan token ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userToken', token);
          print('Token berhasil disimpan: $token');
        } else {
          print('Peringatan: Token tidak ditemukan!');
        }

        // Periksa nilai dari 'role' untuk menentukan navigasi
        if (role == 'admin') {
          // Jika rolenya adalah 'admin', pindah ke halaman AdminPage (menggantikan halaman saat ini)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminPage(username: loggedInUsername),
            ),
          );
        } else {
          // Jika rolenya adalah 'siswa', pindah ke halaman HomePage (menggantikan halaman saat ini)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(username: loggedInUsername),
            ),
          );
        }
      } else {
        // Jika status bukan 200 (misal: 400), berarti login gagal
        // Tampilkan pesan error di SnackBar, parsing body untuk detail error
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Username atau password salah.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Gagal! $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Blok ini akan dijalankan jika terjadi error koneksi
      if (!mounted) {
        return;
      }

      // Nonaktifkan status loading saat terjadi error
      setState(() {
        _isLoading = false;
      });

      // Tampilkan pesan error koneksi di SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak bisa terhubung ke server. Error: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainPinkColor = Color(0xFFF875A1);
    const darkPinkColor = Color(0xFFDD618A);

    return Scaffold(
      backgroundColor: mainPinkColor, // Warna latar belakang utama
      body: Stack(
        children: [
          // Widget dekoratif: lingkaran-lingkaran di latar belakang
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: darkPinkColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: -150,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                color: darkPinkColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Konten utama Login (diapit SafeArea agar tidak tertutup status bar)
          SafeArea(
            child: Center(
              // SingleChildScrollView agar form tidak terpotong saat keyboard muncul
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Teks Judul Selamat Datang
                    const Text(
                      'Sebelum Belajar,\nLogin dulu yuk!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Container putih sebagai kartu untuk form input
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Input field untuk Username
                          TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black, // Background hitam
                              hintText: 'Masukkan Username',
                              // Mengatasi warning 'withOpacity' dengan langsung menggunakan nilai heksadesimal transparan
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Input field untuk Password
                          TextField(
                            controller: _passwordController,
                            obscureText:
                                true, // Menyembunyikan teks (menjadi ••••)
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black, // Background hitam
                              hintText: 'Masukkan Password',
                              // Mengatasi warning 'withOpacity' dengan langsung menggunakan nilai heksadesimal transparan
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Tombol Login
                          ElevatedButton(
                            // Menonaktifkan tombol saat sedang loading
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF00B2FF,
                              ), // Warna biru
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 80,
                                vertical: 15,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    // Tampilkan loading spinner jika sedang memproses
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    // Teks tombol normal
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
