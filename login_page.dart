// lib/login_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kelompok_a/home_page.dart'; // Ganti "kelompok_a" jika nama proyek beda
import 'package:kelompok_a/admin_page.dart'; // Ganti "kelompok_a" jika nama proyek beda

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller untuk mengambil teks dari TextField username
  final _usernameController = TextEditingController();
  // Controller untuk mengambil teks dari TextField password
  final _passwordController = TextEditingController();

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

    // Tentukan alamat URL API login di server backend Anda
    // PENTING: GANTI 'GANTI_DENGAN_IP_ANDA' dengan alamat IP komputer Anda
    final url = Uri.parse('http://GANTI_DENGAN_IP_ANDA:3000/login');

    // Gunakan try-catch untuk menangani error jika koneksi ke server gagal total
    // (misalnya: server mati, tidak ada internet, atau IP salah)
    try {
      // Kirim data ke server menggunakan method POST dan tunggu (await) jawabannya
      final response = await http.post(
        url,
        // Beri tahu server bahwa format data yang kita kirim adalah JSON
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        // Ubah data username & password dari format Dart ke format string JSON
        body: jsonEncode({'username': username, 'password': password}),
      );

      // Cek apakah widget/halaman ini masih ada di layar sebelum melakukan aksi.
      // Ini adalah praktik terbaik untuk menghindari error.
      if (mounted) {
        // Cek status jawaban dari server. Kode 200 artinya "OK" atau sukses.
        if (response.statusCode == 200) {
          // Jika sukses, ubah balasan JSON dari server (yang masih berupa teks)
          // menjadi format Map (key-value) yang bisa dibaca oleh Dart.
          final data = jsonDecode(response.body);
          
          // Ambil nilai 'role' dan 'username' dari data balasan server
          final String role = data['role'];
          final String loggedInUsername = data['username'];

          // Periksa nilai dari 'role'
          if (role == 'admin') {
            // Jika rolenya adalah 'admin', pindah ke halaman AdminPage
            // sambil mengirim data username
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPage(username: loggedInUsername)),
            );
          } else {
            // Jika rolenya bukan 'admin' (misal: 'siswa'), pindah ke halaman HomePage
            // sambil mengirim data username
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage(username: loggedInUsername)),
            );
          }
        } else {
          // Jika statusnya bukan 200 (misal: 400), berarti login gagal
          // Tampilkan pesan error di bagian bawah layar (SnackBar)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Gagal! Username atau password salah.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      // Blok ini akan dijalankan jika terjadi error koneksi
      if (mounted) {
        // Tampilkan pesan error koneksi di SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa terhubung ke server. Periksa koneksi Anda.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainPinkColor = Color(0xFFF875A1);
    const darkPinkColor = Color(0xFFDD618A);

    return Scaffold(
      backgroundColor: mainPinkColor,
      body: Stack(
        children: [
          // Widget untuk lingkaran-lingkaran dekoratif di latar belakang
          Positioned(
            bottom: -100, left: -100,
            child: Container(width: 300, height: 300, decoration: const BoxDecoration(color: darkPinkColor, shape: BoxShape.circle)),
          ),
          Positioned(
            top: 150, right: -150,
            child: Container(width: 250, height: 250, decoration: const BoxDecoration(color: darkPinkColor, shape: BoxShape.circle)),
          ),
          // Widget SafeArea agar konten tidak tertutup status bar di atas
          SafeArea(
            child: Center(
              // Widget SingleChildScrollView agar halaman bisa di-scroll jika keyboard muncul
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Teks Judul
                    const Text('Sebelum Belajar,\nLogin dulu yuk!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 50),
                    // Container putih sebagai kartu untuk form
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        children: [
                          // Input field untuk Username
                          TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black,
                              hintText: 'Masukkan Username',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.person_outline, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Input field untuk Password
                          TextField(
                            controller: _passwordController,
                            obscureText: true, // Membuat inputan menjadi ••••
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black,
                              hintText: 'Masukkan Password',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Tombol Login
                          ElevatedButton(
                            onPressed: _handleLogin, // Memanggil fungsi login saat ditekan
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B2FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                            ),
                            child: const Text('Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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