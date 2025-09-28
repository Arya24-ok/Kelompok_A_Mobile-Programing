// lib/admin_page.dart

import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  // Variabel untuk menampung username admin yang login
  final String username;

  // Constructor yang mewajibkan pengiriman data username
  const AdminPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    // Halaman sederhana dengan AppBar dan teks di tengah
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        // Menampilkan pesan selamat datang dengan nama admin
        child: Text(
          'Selamat datang, Admin $username!',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}