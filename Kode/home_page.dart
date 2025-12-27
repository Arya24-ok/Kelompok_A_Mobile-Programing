import 'package:flutter/material.dart';
import 'package:visualink_app/materi_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visualink_app/kuis_page.dart';

class HomePage extends StatelessWidget {
  final String username;

  const HomePage({super.key, required this.username});

  Future<void> _launchWhatsAppUrl(BuildContext context) async {
    final Uri url = Uri.parse('https://chat.whatsapp.com/LDXgOhth0LjD2P14OvqxGe');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka link WhatsApp. Pastikan aplikasi WhatsApp terinstal.'), backgroundColor: Colors.red),
        );
      }
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
              _buildHeader(context, username),
              const SizedBox(height: 40),

              const Text('', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildMenuButton(
                      title: 'Materi',
                      icon: Icons.book,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MateriPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMenuButton(
                      title: 'Kuis',
                      icon: Icons.quiz,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const KuisPage()),
                        );
                      },
                    )
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tombol Forum Diskusi sekarang akan memanjang
              _buildMenuButton(
                title: 'Forum Diskusi',
                icon: Icons.group,
                onTap: () => _launchWhatsAppUrl(context),
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

  Widget _buildHeader(BuildContext context, String name) {
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
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red, size: 30),
          tooltip: 'Logout',
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Konfirmasi Keluar'),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
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
                        Navigator.of(dialogContext).pop();
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

  Widget _buildMenuButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity, // <--- PERUBAHAN DI SINI: Membuat tombol melebar penuh
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF875A1),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 35),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}