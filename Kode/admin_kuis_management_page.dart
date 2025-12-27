// lib/admin_kuis_management_page.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visualink_app/kuis_models.dart';
import 'package:visualink_app/admin_kuis_detail_page.dart';

class AdminKuisManagementPage extends StatefulWidget {
  final String babId;
  final String babJudul;

  const AdminKuisManagementPage({
    super.key,
    required this.babId,
    required this.babJudul,
  });

  @override
  State<AdminKuisManagementPage> createState() =>
      _AdminKuisManagementPageState();
}

class _AdminKuisManagementPageState extends State<AdminKuisManagementPage> {
  List<KuisItem> _daftarKuis = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDaftarKuis();
  }

  // --- HELPER HEADER (SOLUSI ERROR DUPLICATE KEYS) ---
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken') ?? '';
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'ngrok-skip-browser-warning': 'true',
      'x-auth-token': token,
    };
  }

  Future<void> _fetchDaftarKuis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/bab/${widget.babId}/kuis',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _daftarKuis = data.map((json) => KuisItem.fromJson(json)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _daftarKuis = [];
          _isLoading = false;
        });
      } else {
        throw Exception('Status ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // --- FUNGSI TAMBAH KUIS ---
  Future<void> _tambahKuisBaru(String judul, String deskripsi, int maxAttempts) async {
    if (judul.isEmpty) return;

    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/bab/${widget.babId}/kuis',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'judul': judul,
          'deskripsi': deskripsi,
          'maxAttempts': maxAttempts, // [PENTING] Kirim data batas ke server
          'nilaiTampil': true,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        _fetchDaftarKuis();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kuis berhasil ditambahkan'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Gagal: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- FUNGSI UPDATE / EDIT KUIS ---
  Future<void> _updateKuis(String kuisId, String judul, String deskripsi, int maxAttempts) async {
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/kuis/$kuisId',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'judul': judul,
          'deskripsi': deskripsi,
          'maxAttempts': maxAttempts, // [PENTING] Kirim data batas yang diedit
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _fetchDaftarKuis(); // Refresh agar tulisan Unlimited berubah jadi angka
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kuis berhasil diperbarui'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Gagal Update: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- FUNGSI HAPUS KUIS ---
  Future<void> _hapusKuis(String kuisId) async {
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/kuis/$kuisId',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        _fetchDaftarKuis();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kuis berhasil dihapus'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Gagal Hapus: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmDialog(String kuisId, String judulKuis) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kuis?'),
        content: Text('Hapus "$judulKuis"? Semua data akan hilang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _hapusKuis(kuisId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
  
  // --- FUNGSI TOGGLE NILAI ---
  Future<void> _toggleNilaiTampil(KuisItem kuis, bool newValue) async {
    int index = _daftarKuis.indexWhere((k) => k.id == kuis.id);
    if (index != -1) {
      setState(() {
        _daftarKuis[index] = kuis.copyWith(nilaiTampil: newValue);
      });
    }

    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/kuis/${kuis.id}',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({'nilaiTampil': newValue}),
      );

      if (response.statusCode != 200) {
        if (index != -1 && mounted) {
           setState(() {
            _daftarKuis[index] = kuis.copyWith(nilaiTampil: !newValue);
          });
        }
      }
    } catch (e) {
       if (index != -1 && mounted) {
           setState(() {
            _daftarKuis[index] = kuis.copyWith(nilaiTampil: !newValue);
          });
        }
    }
  }

  // --- DIALOG INPUT ---
  void _showKuisDialog({KuisItem? kuisToEdit}) {
    final TextEditingController judulController = TextEditingController(text: kuisToEdit?.judul ?? '');
    final TextEditingController deskripsiController = TextEditingController(text: kuisToEdit?.deskripsi ?? '');
    final TextEditingController limitController = TextEditingController(text: kuisToEdit?.maxAttempts.toString() ?? '1');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(kuisToEdit == null ? 'Tambah Kuis Baru' : 'Edit Kuis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: judulController,
                  decoration: const InputDecoration(labelText: "Judul Kuis"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: deskripsiController,
                  decoration: const InputDecoration(labelText: "Deskripsi (Opsional)"),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: limitController,
                  decoration: const InputDecoration(
                    labelText: "Batas Pengerjaan (0 = Tak Terbatas)",
                    hintText: "Contoh: 1"
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final int limit = int.tryParse(limitController.text) ?? 1;
                if (kuisToEdit == null) {
                    _tambahKuisBaru(judulController.text, deskripsiController.text, limit);
                } else {
                    _updateKuis(kuisToEdit.id, judulController.text, deskripsiController.text, limit);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kuis - ${widget.babJudul}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showKuisDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDaftarKuis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _daftarKuis.length,
                  itemBuilder: (context, index) {
                    final kuis = _daftarKuis[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(kuis.judul),
                        // [DISINI] Menampilkan Limit dengan benar
                        subtitle: Text(
                          "Limit: ${kuis.maxAttempts == 0 ? 'Unlimited' : '${kuis.maxAttempts}x'}",
                          style: TextStyle(
                            color: kuis.maxAttempts == 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             // Tombol Edit
                             IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showKuisDialog(kuisToEdit: kuis),
                             ),
                             // Tombol Hapus
                             IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmDialog(kuis.id, kuis.judul),
                             ),
                             // Toggle Nilai
                             Switch(
                                value: kuis.nilaiTampil,
                                onChanged: (val) => _toggleNilaiTampil(kuis, val),
                                activeColor: Colors.green,
                             ),
                             const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminKuisDetailPage(
                                kuisId: kuis.id,
                                kuisJudul: kuis.judul,
                              ),
                            ),
                          ).then((_) => _fetchDaftarKuis());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}