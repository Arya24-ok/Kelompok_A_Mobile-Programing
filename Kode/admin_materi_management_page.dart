import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:visualink_app/admin_materi_list_page.dart';
import 'package:visualink_app/admin_kuis_management_page.dart';

// Model Bab
class Bab {
  final String id;
  final String judul;
  Bab({required this.id, required this.judul});

  factory Bab.fromJson(Map<String, dynamic> json) {
    // Perbaikan typo kecil dari kode asli: json['judul') menjadi json['judul']
    return Bab(id: json['_id'], judul: json['judul']);
  }
}

class AdminMateriManagementPage extends StatefulWidget {
  final String managementType;

  const AdminMateriManagementPage({super.key, required this.managementType});

  @override
  State<AdminMateriManagementPage> createState() =>
      _AdminMateriManagementPageState();
}

class _AdminMateriManagementPageState extends State<AdminMateriManagementPage> {
  List<Bab> _daftarBab = [];
  bool _isLoadingBab = true;
  String? _errorBab;

  // URL Base (Disimpan agar mudah dipakai ulang)
  final String baseUrl = 'https://khedivial-semiplastic-valentine.ngrok-free.dev/bab';

  @override
  void initState() {
    super.initState();
    _fetchDaftarBab();
  }

  // --- FUNGSI FETCH DAFTAR BAB ---
  Future<void> _fetchDaftarBab() async {
    setState(() {
      _isLoadingBab = true;
      _errorBab = null;
    });

    final url = Uri.parse(baseUrl);

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = jsonDecode(response.body);
          setState(() {
            _daftarBab = data.map((json) => Bab.fromJson(json)).toList();
            _isLoadingBab = false;
          });
        } catch (e) {
          throw Exception("Format data salah (bukan JSON): ${response.body}");
        }
      } else {
        throw Exception('Gagal memuat Bab: Status ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorBab = 'Error: ${e.toString()}';
        _isLoadingBab = false;
      });
    }
  }

  // --- FUNGSI TAMBAH BAB BARU ---
  Future<void> _tambahBabBaru(String judul) async {
    if (judul.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul Bab tidak boleh kosong'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final url = Uri.parse(baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'judul': judul}),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pop(context);
        _fetchDaftarBab(); // Refresh data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bab baru berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMsg;
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['msg'] ?? response.body;
        } catch (_) {
          errorMsg = response.body;
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- [BARU] FUNGSI EDIT BAB ---
  Future<void> _editBab(String id, String judulBaru) async {
    final url = Uri.parse('$baseUrl/$id'); // Asumsi endpoint: /bab/{id}

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'judul': judulBaru}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context); // Tutup dialog
        _fetchDaftarBab(); // Refresh data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bab berhasil diperbarui'), backgroundColor: Colors.green),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- [BARU] FUNGSI HAPUS BAB ---
  Future<void> _hapusBab(String id) async {
    final url = Uri.parse('$baseUrl/$id'); // Asumsi endpoint: /bab/{id}

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context); // Tutup dialog konfirmasi
        _fetchDaftarBab(); // Refresh data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bab berhasil dihapus'), backgroundColor: Colors.green),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- DIALOG TAMBAH ---
  void _showAddBabDialog() {
    final TextEditingController babController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Bab Baru'),
          content: TextField(
            controller: babController,
            decoration: const InputDecoration(hintText: "Masukkan Judul Bab"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _tambahBabBaru(babController.text);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // --- [BARU] DIALOG EDIT ---
  void _showEditBabDialog(Bab bab) {
    final TextEditingController babController = TextEditingController(text: bab.judul);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Judul Bab'),
          content: TextField(
            controller: babController,
            decoration: const InputDecoration(hintText: "Masukkan Judul Baru"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (babController.text.isNotEmpty) {
                  _editBab(bab.id, babController.text);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // --- [BARU] DIALOG KONFIRMASI HAPUS ---
  void _showDeleteConfirmationDialog(Bab bab) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Bab'),
          content: Text('Apakah Anda yakin ingin menghapus bab "${bab.judul}"? Data terkait mungkin akan hilang.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                _hapusBab(bab.id);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = widget.managementType == 'kuis'
        ? 'Pilih Bab untuk Kelola Kuis'
        : 'Pilih Bab untuk Kelola Materi';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Tambah Bab Baru',
            onPressed: _showAddBabDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Daftar Bab',
            onPressed: _fetchDaftarBab,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Bab:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _isLoadingBab
                ? const Center(child: CircularProgressIndicator())
                : _errorBab != null
                    ? Center(
                        child: Text(
                          _errorBab!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : Expanded(
                        child: _daftarBab.isEmpty
                            ? const Center(
                                child: Text('Belum ada Bab. Tambahkan Bab baru.'),
                              )
                            : ListView.builder(
                                itemCount: _daftarBab.length,
                                itemBuilder: (context, index) {
                                  final bab = _daftarBab[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    child: ListTile(
                                      title: Text(bab.judul),
                                      // [DIPERBARUI] Menambahkan tombol Edit dan Hapus di sini
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showEditBabDialog(bab),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _showDeleteConfirmationDialog(bab),
                                          ),
                                          const VerticalDivider(),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        if (widget.managementType == 'kuis') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AdminKuisManagementPage(
                                                babId: bab.id,
                                                babJudul: bab.judul,
                                              ),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AdminMateriListPage(
                                                babId: bab.id,
                                                babJudul: bab.judul,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
          ],
        ),
      ),
    );
  }
}