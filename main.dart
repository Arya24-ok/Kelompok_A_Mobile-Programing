// lib/main.dart

import 'package:flutter/material.dart';
// Import file login_page.dart agar bisa pindah ke halaman tersebut
import 'package:kelompok_a/login_page.dart'; // Ganti "kelompok_a" jika nama proyek beda

// Fungsi utama yang akan dijalankan pertama kali saat aplikasi dibuka
void main() {
  // Menjalankan widget MyApp sebagai akar dari semua widget
  runApp(const MyApp());
}

// Widget utama aplikasi, membungkus keseluruhan aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp adalah widget dasar yang menyediakan banyak fitur standar
    // seperti navigasi, tema, dll.
    return const MaterialApp(
      // Menghilangkan banner "DEBUG" di pojok kanan atas layar
      debugShowCheckedModeBanner: false,
      // Menetapkan WelcomeScreen sebagai halaman pertama yang ditampilkan
      home: WelcomeScreen(),
    );
  }
}

// Widget untuk halaman "Selamat Datang"
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold menyediakan struktur dasar halaman (latar belakang, app bar, dll)
    return Scaffold(
      backgroundColor: Colors.white,
      // Stack digunakan untuk menumpuk beberapa widget di atas satu sama lain
      body: Stack(
        children: [
          // Widget #1 (lapisan paling bawah): Latar belakang bentuk pink
          const BackgroundShapes(),
          // Widget #2 (lapisan di atasnya): Konten utama (teks dan tombol)
          SafeArea(
            child: Center(
              child: Column(
                // Mengatur alignment vertikal untuk anak-anak widget Column
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Spacer digunakan untuk mengisi ruang kosong secara fleksibel
                  const Spacer(flex: 2),
                  // Teks judul "Selamat Datang"
                  const Text(
                    'Selamat Datang\ndi Visualink',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00B2FF)),
                  ),
                  const Spacer(flex: 2),
                  // Teks slogan di tengah
                  const Text(
                    'Belajar Publikasi\nKapan Aja!\nDimana Aja!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  // Tombol untuk masuk
                  ElevatedButton(
                    // Aksi yang dijalankan saat tombol ditekan
                    onPressed: () {
                      // Perintah untuk pindah ke halaman lain
                      Navigator.push(
                        context,
                        // MaterialPageRoute mendefinisikan transisi halaman standar
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    // Mengatur gaya visual tombol
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                      elevation: 5,
                    ),
                    child: const Text('Klik untuk Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(flex: 3),
                  // Teks slogan di bawah (di dalam area pink)
                  const Text(
                    'Belajar Publikasi\nWujudkan Imajinasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget terpisah khusus untuk menangani bentuk-bentuk di latar belakang
class BackgroundShapes extends StatelessWidget {
  const BackgroundShapes({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil ukuran layar untuk penempatan yang responsif
    final size = MediaQuery.of(context).size;
    const pinkColor = Color(0xFFF875A1);
    const darkPinkColor = Color(0xFFDD618A);

    return Stack(
      children: [
        // Widget untuk membuat bentuk lengkung pink
        Align(
          alignment: Alignment.bottomCenter,
          // ClipPath memotong child-nya (Container) sesuai bentuk dari clipper
          child: ClipPath(
            clipper: WaveClipper(),
            child: Container(
              width: size.width,
              height: size.height * 0.6, // Tinggi 60% dari layar
              color: pinkColor,
            ),
          ),
        ),
        // Positioned digunakan untuk menempatkan widget di posisi tertentu di dalam Stack
        Positioned(
          bottom: size.height * 0.1,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 0.5,
            height: size.width * 0.5,
            decoration: const BoxDecoration(color: darkPinkColor, shape: BoxShape.circle),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.15,
          left: -size.width * 0.1,
          child: Container(
            width: size.width * 0.4,
            height: size.width * 0.4,
            decoration: const BoxDecoration(color: darkPinkColor, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

// Class untuk "menggambar" path atau jalur berbentuk lengkung
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    // Menggambar garis-garis dan kurva untuk membentuk area yang diinginkan
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height * 0.2);
    var firstControlPoint = Offset(size.width * 0.75, 0);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.2);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(size.width * 0.25, size.height * 0.4);
    var secondEndPoint = Offset(0, size.height * 0.2);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    path.close(); // Menutup path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}