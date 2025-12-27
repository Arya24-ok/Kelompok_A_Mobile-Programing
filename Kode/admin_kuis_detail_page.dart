// lib/admin_kuis_detail_page.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visualink_app/kuis_models.dart';
import 'package:visualink_app/admin_hasil_kuis_page.dart';

class AdminKuisDetailPage extends StatefulWidget {
  final String kuisId;
  final String kuisJudul;

  const AdminKuisDetailPage({
    super.key,
    required this.kuisId,
    required this.kuisJudul,
  });

  @override
  State<AdminKuisDetailPage> createState() => _AdminKuisDetailPageState();
}

class _AdminKuisDetailPageState extends State<AdminKuisDetailPage> {
  List<Pertanyaan> _daftarPertanyaan = [];
  bool _isLoadingPertanyaan = true;
  String? _errorPertanyaan;

  // Controller untuk form Tambah
  final _pertanyaanController = TextEditingController();
  String _tipePertanyaanDipilih = 'pilgan';
  final List<TextEditingController> _opsiControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _jawabanBenarController = TextEditingController();
  bool _isLoadingTambah = false;

  @override
  void initState() {
    super.initState();
    _fetchDaftarPertanyaan();
  }

  // Helper Header
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken') ?? '';
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'ngrok-skip-browser-warning': 'true',
      'x-auth-token': token,
    };
  }

  Future<void> _fetchDaftarPertanyaan() async {
    setState(() {
      _isLoadingPertanyaan = true;
      _errorPertanyaan = null;
    });

    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/kuis/${widget.kuisId}/pertanyaan',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _daftarPertanyaan = data.map((json) => Pertanyaan.fromJson(json)).toList();
          _isLoadingPertanyaan = false;
        });
      } else {
         setState(() {
            _daftarPertanyaan = [];
            _isLoadingPertanyaan = false;
         });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorPertanyaan = 'Error: ${e.toString()}';
        _isLoadingPertanyaan = false;
      });
    }
  }

  // --- FUNGSI HAPUS PERTANYAAN ---
  Future<void> _hapusPertanyaan(String pertanyaanId) async {
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/pertanyaan/$pertanyaanId',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        _fetchDaftarPertanyaan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pertanyaan dihapus'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Gagal hapus: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- FUNGSI UPDATE PERTANYAAN ---
  Future<void> _updatePertanyaan(
      String id, String teks, String tipe, List<String> opsi, String jawabanBenar) async {
    
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/pertanyaan/$id',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'teks': teks,
          'tipe': tipe,
          'opsi': opsi,
          'jawabanBenar': jawabanBenar,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context); // Tutup dialog edit
        _fetchDaftarPertanyaan(); // Refresh data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pertanyaan diperbarui'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Gagal update: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _tambahPertanyaanBaru() async {
    if (_pertanyaanController.text.isEmpty) return;
    setState(() => _isLoadingTambah = true);

    List<String> opsiJawaban = [];
    if (_tipePertanyaanDipilih == 'pilgan') {
      opsiJawaban = _opsiControllers
          .map((c) => c.text).where((t) => t.isNotEmpty).toList();
      if (opsiJawaban.length < 2) {
         setState(() => _isLoadingTambah = false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Min. 2 opsi untuk Pilgan')));
         return;
      }
    }

    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/kuis/${widget.kuisId}/pertanyaan',
    );
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers, 
        body: jsonEncode({
          'teks': _pertanyaanController.text,
          'tipe': _tipePertanyaanDipilih,
          'opsi': opsiJawaban,
          'jawabanBenar': _jawabanBenarController.text,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        _fetchDaftarPertanyaan();
        _pertanyaanController.clear();
        for (var c in _opsiControllers) c.clear();
        _jawabanBenarController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil ditambah'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${response.body}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingTambah = false);
    }
  }

  // --- DIALOG EDIT PERTANYAAN ---
  void _showEditDialog(Pertanyaan p) {
    final textCtrl = TextEditingController(text: p.teks);
    final jawabanCtrl = TextEditingController(text: p.jawabanBenar);
    String tipe = p.tipe;
    
    // Siapkan controller opsi (isi dengan data lama jika ada)
    List<TextEditingController> opsiCtrls = List.generate(4, (index) {
        return TextEditingController(
            text: (index < p.opsi.length) ? p.opsi[index] : ''
        );
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Pertanyaan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: textCtrl, 
                        decoration: const InputDecoration(labelText: 'Teks Soal'),
                        maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tipe,
                      items: const [
                        DropdownMenuItem(value: 'pilgan', child: Text('Pilihan Ganda')),
                        DropdownMenuItem(value: 'esai', child: Text('Esai')),
                      ],
                      onChanged: (val) {
                         setStateDialog(() => tipe = val!);
                      },
                      decoration: const InputDecoration(labelText: 'Tipe'),
                    ),
                    const SizedBox(height: 10),
                    if (tipe == 'pilgan') ...[
                        const Text('Opsi Jawaban:'),
                        ...List.generate(4, (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: TextField(
                                controller: opsiCtrls[i],
                                decoration: InputDecoration(labelText: 'Opsi ${i+1}', border: const OutlineInputBorder()),
                            ),
                        )),
                        const SizedBox(height: 10),
                        TextField(
                            controller: jawabanCtrl,
                            decoration: const InputDecoration(labelText: 'Indeks Jawaban Benar (0-3)'),
                            keyboardType: TextInputType.number,
                        )
                    ] else ...[
                        TextField(
                            controller: jawabanCtrl,
                            decoration: const InputDecoration(labelText: 'Kunci Jawaban Esai'),
                        )
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                    onPressed: () {
                        List<String> opsiFinal = [];
                        if (tipe == 'pilgan') {
                            opsiFinal = opsiCtrls.map((c) => c.text).where((t) => t.isNotEmpty).toList();
                        }
                        _updatePertanyaan(p.id, textCtrl.text, tipe, opsiFinal, jawabanCtrl.text);
                    },
                    child: const Text('Update'),
                )
              ],
            );
          }
        );
      },
    );
  }

  // --- DIALOG KONFIRMASI HAPUS ---
  void _confirmDelete(String id) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: const Text('Hapus Soal?'),
              content: const Text('Yakin ingin menghapus soal ini?'),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                  TextButton(
                      onPressed: () {
                          Navigator.pop(ctx);
                          _hapusPertanyaan(id);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Hapus'),
                  )
              ],
          )
      );
  }

  @override
  void dispose() {
    _pertanyaanController.dispose();
    for (var c in _opsiControllers) c.dispose();
    _jawabanBenarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Pertanyaan - ${widget.kuisJudul}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Lihat Hasil Siswa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminHasilKuisPage(
                    kuisId: widget.kuisId,
                    kuisJudul: widget.kuisJudul,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchDaftarPertanyaan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Daftar Pertanyaan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _isLoadingPertanyaan
                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                : _errorPertanyaan != null
                    ? Center(child: Text(_errorPertanyaan!, style: const TextStyle(color: Colors.red)))
                    : _daftarPertanyaan.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Belum ada pertanyaan.')))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _daftarPertanyaan.length,
                            itemBuilder: (context, index) {
                              final p = _daftarPertanyaan[index];
                              return Card(
                                margin: const EdgeInsets.only(top: 8.0),
                                child: ListTile(
                                  leading: CircleAvatar(child: Text('${index + 1}')),
                                  title: Text(p.teks),
                                  subtitle: Text('Tipe: ${p.tipe} | Kunci: ${p.jawabanBenar}'),
                                  // [BAGIAN PENTING] Ini adalah tombol Edit & Hapus
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showEditDialog(p),
                                        ),
                                        IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _confirmDelete(p.id),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

            const Divider(height: 40, thickness: 2),
            
            // --- FORM TAMBAH ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Tambah Pertanyaan Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pertanyaanController,
                      decoration: const InputDecoration(labelText: 'Teks Pertanyaan', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _tipePertanyaanDipilih,
                      items: const [
                        DropdownMenuItem(value: 'pilgan', child: Text('Pilihan Ganda')),
                        DropdownMenuItem(value: 'esai', child: Text('Esai')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _tipePertanyaanDipilih = value);
                      },
                      decoration: const InputDecoration(labelText: 'Tipe Pertanyaan', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      firstChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Opsi Jawaban:'),
                          ...List.generate(
                            _opsiControllers.length,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: TextField(
                                controller: _opsiControllers[index],
                                decoration: InputDecoration(labelText: 'Opsi ${index + 1}', border: const OutlineInputBorder()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _jawabanBenarController,
                            decoration: const InputDecoration(labelText: 'Indeks Jawaban Benar (0, 1, 2, ...)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      secondChild: TextField(
                        controller: _jawabanBenarController,
                        decoration: const InputDecoration(labelText: 'Jawaban Benar Esai', border: OutlineInputBorder()),
                      ),
                      crossFadeState: _tipePertanyaanDipilih == 'pilgan' ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoadingTambah ? null : _tambahPertanyaanBaru,
                      icon: _isLoadingTambah 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.add),
                      label: Text(_isLoadingTambah ? 'Menyimpan...' : 'Tambah Pertanyaan'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}