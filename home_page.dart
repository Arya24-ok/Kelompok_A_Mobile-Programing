// lib/home_page.dart

import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  // Variabel untuk menampung data username yang dikirim dari halaman login
  final String username;
  
  // Constructor yang mewajibkan pengiriman data username saat halaman ini dibuat
  const HomePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      // SafeArea agar konten tidak menabrak status bar atau notch
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Column untuk menyusun widget secara vertikal
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Memanggil fungsi helper untuk membuat header
              _buildHeader(username),
              const SizedBox(height: 40),
              
              // Teks Judul "Menu"
              const Text('Menu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              
              // Baris untuk menampung tombol Materi dan Kuis
              Row(
                children: [
                  // Expanded agar tombol mengisi ruang yang tersedia secara merata
                  Expanded(child: _buildMenuButton(title: 'Materi', onTap: () {})),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMenuButton(title: 'Kuis', onTap: () {})),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tombol untuk Forum Diskusi
              _buildMenuButton(title: 'Forum Diskusi', onTap: () {}),
              
              // Spacer untuk mendorong konten di bawahnya ke posisi paling bawah
              const Spacer(),
              
              // Teks footer di bagian bawah tengah
              const Center(
                child: Column(
                  children: [
                    Text('Belajar Publikasi', style: TextStyle(fontSize: 20, color: Color(0xFF00B2FF))),
                    Text('Wujudkan Imajinasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00B2FF))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi helper (pembantu) untuk membuat widget header
  // Menerima parameter 'name' untuk ditampilkan
  Widget _buildHeader(String name) {
    return Row(
      children: [
        const Icon(Icons.account_circle, color: Color(0xFF00B2FF), size: 50),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Halo,', style: TextStyle(fontSize: 16, color: Colors.black54)),
            // Menampilkan nama pengguna yang login
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const Spacer(), // Mendorong ikon lonceng ke kanan
        const Icon(Icons.notifications, color: Color(0xFF00B2FF), size: 30),
      ],
    );
  }

  // Fungsi helper untuk membuat tombol menu agar tidak menulis kode yang sama berulang kali
  Widget _buildMenuButton({required String title, required VoidCallback onTap}) {
    // InkWell membuat widget di dalamnya bisa di-klik dan memiliki efek "ripple"
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: const Color(0xFFF875A1),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}