// lib/admin_page.dart

import 'package:flutter/material.dart';
// --- TAMBAHAN IMPORT ---
import 'package:visualink_app/admin_materi_management_page.dart'; // Import halaman pilih Bab (gerbang Materi/Kuis)
import 'package:url_launcher/url_launcher.dart'; // Import untuk membuka link eksternal
// --- AKHIR TAMBAHAN IMPORT ---

class AdminPage extends StatelessWidget {
  final String username;
  const AdminPage({super.key, required this.username});

  // --- TAMBAHAN FUNGSI UNTUK LINK WHATSAPP ---
  // Fungsi untuk membuka link WhatsApp Group
  Future<void> _launchWhatsAppUrl(BuildContext context) async {
    // Link Group WhatsApp (pastikan ini adalah link yang valid)
    final Uri url = Uri.parse('https://chat.whatsapp.com/LDXgOhth0LjD2P14OvqxGe');
    
    // Gunakan canLaunchUrl untuk cek apakah link bisa dibuka
    if (await canLaunchUrl(url)) {
      // Buka URL menggunakan mode aplikasi eksternal (browser/WhatsApp app)
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Gunakan context yang diterima dari build method untuk menampilkan SnackBar
      if (context.mounted) { 
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal membuka link WhatsApp. Pastikan aplikasi WhatsApp terinstal.'), backgroundColor: Colors.red),
          );
      }
    }
  }
  // --- AKHIR TAMBAHAN FUNGSI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, username), // Header dengan nama Admin dan tombol Logout
              const SizedBox(height: 40),
              const Text('Menu Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMenuButton(
                      title: 'Kelola Materi',
                      icon: Icons.book,
                      onTap: () {
                        // Navigasi ke halaman pemilihan Bab dengan tipe 'materi'
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminMateriManagementPage(managementType: 'materi')
                          ), 
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMenuButton(
                      title: 'Kelola Kuis',
                      icon: Icons.quiz,
                      // --- TAMBAHAN AKSI NAVIGASI KUIS ---
                      onTap: () {
                        // Navigasi ke halaman pemilihan Bab dengan tipe 'kuis'
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminMateriManagementPage(managementType: 'kuis')
                          ),
                        );
                      }
                      // --- AKHIR TAMBAHAN AKSI ---
                    )
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                title: 'Lihat Forum Diskusi',
                icon: Icons.chat,
                // --- TAMBAHAN AKSI BUKA LINK WA ---
                onTap: () => _launchWhatsAppUrl(context), // Panggil fungsi launch WA
                // --- AKHIR TAMBAHAN AKSI ---
              ),
              const Spacer(), // Spacer untuk mendorong konten ke bawah
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

  // Fungsi _buildHeader untuk menampilkan info admin dan tombol logout
  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      children: [
        const Icon(Icons.admin_panel_settings, color: Colors.indigo, size: 50),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin:', style: TextStyle(fontSize: 16, color: Colors.black54)),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red, size: 30),
          tooltip: 'Logout',
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun Admin?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Batal'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Tutup dialog
                        // Aksi Logout (kembali ke halaman sebelumnya/login)
                        Navigator.pop(context); 
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Fungsi _buildMenuButton untuk membuat kotak menu interaktif
  Widget _buildMenuButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.indigo[400],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}