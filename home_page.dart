import 'package:flutter/material.dart';
import 'package:visualink_app/materi_page.dart'; // Pastikan path ini benar
import 'package:url_launcher/url_launcher.dart';   // Import untuk membuka link

class HomePage extends StatelessWidget {
  final String username;
  
  const HomePage({super.key, required this.username});

  // Fungsi untuk membuka link WhatsApp
  Future<void> _launchWhatsAppUrl() async {
    final Uri url = Uri.parse('https://chat.whatsapp.com/LDXgOhth0LjD2P14OvqxGe');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

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
              _buildHeader(username),
              const SizedBox(height: 40),
              
              const Text('Menu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildMenuButton(
                      title: 'Materi',
                      // Aksi 1: Pindah ke halaman Materi
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MateriPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMenuButton(title: 'Kuis', onTap: () {})),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildMenuButton(
                title: 'Forum Diskusi',
                // Aksi 2: Membuka link WhatsApp
                onTap: _launchWhatsAppUrl,
              ),
              
              const Spacer(),
              
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

  Widget _buildHeader(String name) {
    return Row(
      children: [
        const Icon(Icons.account_circle, color: Color(0xFF00B2FF), size: 50),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Halo,', style: TextStyle(fontSize: 16, color: Colors.black54)),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const Spacer(),
        const Icon(Icons.notifications, color: Color(0xFF00B2FF), size: 30),
      ],
    );
  }

  Widget _buildMenuButton({required String title, required VoidCallback onTap}) {
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