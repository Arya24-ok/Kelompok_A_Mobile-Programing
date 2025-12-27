// lib/kuis_player_page.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Untuk token
import 'package:visualink_app/kuis_models.dart'; // Model

class KuisPlayerPage extends StatefulWidget {
  final String kuisId;
  final String kuisJudul;

  const KuisPlayerPage({
    super.key,
    required this.kuisId,
    required this.kuisJudul,
  });

  @override
  State<KuisPlayerPage> createState() => _KuisPlayerPageState();
}

class _KuisPlayerPageState extends State<KuisPlayerPage> {
  List<Pertanyaan> _daftarPertanyaan = [];
  bool _isLoading = true;
  String? _error;

  final PageController _pageController = PageController();
  int _halamanSekarang = 0;
  final Map<String, String> _jawaban = {};
  final Map<String, TextEditingController> _esaiControllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchPertanyaan();
  }

  // --- FUNGSI FETCH PERTANYAAN DENGAN CEK BATASAN ---
  Future<void> _fetchPertanyaan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 1. Ambil Token Siswa
    final prefs = await SharedPreferences.getInstance();
    final String? userToken = prefs.getString('userToken');

    if (userToken == null) {
      if (!mounted) return;
      setState(() {
        _error = 'Otorisasi gagal. Token tidak ditemukan. Silakan login ulang.';
        _isLoading = false;
      });
      return;
    }

    // URL API
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/kuis/${widget.kuisId}/pertanyaan',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Anti-Ngrok Warning
          'x-auth-token': userToken, // Token Siswa (Wajib untuk cek limit)
        },
      );

      if (!mounted) return;

      // Debugging
      print("Fetch Pertanyaan Status: ${response.statusCode}");

      // 2. Cek Status Code
      if (response.statusCode == 200) {
        // SUKSES: Masih ada kesempatan
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _daftarPertanyaan =
              data.map((json) => Pertanyaan.fromJson(json)).toList();
          _isLoading = false;
        });
      } 
      else if (response.statusCode == 403) {
        // BATAS HABIS (Forbidden)
        // Server mengirim sinyal bahwa siswa sudah melebih batas max_attempt
        String pesan = "Kesempatan mengerjakan kuis ini sudah habis.";
        try {
           final errData = jsonDecode(response.body);
           if(errData['msg'] != null) pesan = errData['msg'];
        } catch (_) {}

        // Tampilkan dialog blokir
        _showLimitReachedDialog(pesan);
      } 
      else if (response.statusCode == 404) {
        // Kuis kosong
        setState(() {
          _daftarPertanyaan = [];
          _isLoading = false;
        });
      } 
      else {
        // Error lain
        throw Exception(
            'Gagal memuat pertanyaan: Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // --- FUNGSI SUBMIT JAWABAN ---
  Future<void> _submitKuis() async {
    // Validasi: Harus jawab semua
    if (_jawaban.length != _daftarPertanyaan.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap jawab semua pertanyaan terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String? userToken = prefs.getString('userToken');

    if (userToken == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi habis. Silakan login ulang.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final List<Map<String, dynamic>> jawabanList = _jawaban.entries.map((entry) {
      return JawabanSiswa(
        pertanyaanId: entry.key,
        jawabanTeks: entry.value,
      ).toJson();
    }).toList();

    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/kuis/${widget.kuisId}/submit',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'ngrok-skip-browser-warning': 'true',
          'x-auth-token': userToken,
        },
        body: jsonEncode({'jawaban': jawabanList}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['isNilaiDisembunyikan'] == true) {
          _showNilaiDisembunyikanDialog();
        } else {
          final hasil = HasilKuis.fromJson(data);
          _showHasilDialog(hasil);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal submit: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // --- DIALOG JIKA BATAS HABIS ---
  void _showLimitReachedDialog(String pesan) {
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa klik luar untuk tutup
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // Tombol back HP dinonaktifkan
        child: AlertDialog(
          title: const Text(
            'Akses Ditolak',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                pesan,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Tutup dialog
                Navigator.of(context).pop(); // Keluar dari halaman kuis
              },
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Nilai Disembunyikan
  void _showNilaiDisembunyikanDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Kuis Selesai!'),
        content: const Text(
          'Jawaban Anda telah dikirim. Nilai kuis ini disembunyikan oleh guru.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  // Dialog Hasil
  void _showHasilDialog(HasilKuis hasil) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Kuis Selesai!',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skor: ${hasil.skor.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),
            Text('Total Soal: ${hasil.totalSoal}'),
            Text('Jawaban Benar: ${hasil.totalBenar}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _esaiControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- WIDGET UI PERTANYAAN ---
  Widget _buildPertanyaanWidget(Pertanyaan pertanyaan) {
    const mainPinkColor = Color(0xFFF875A1);
    String? jawabanTersimpan = _jawaban[pertanyaan.id];
    TextEditingController? esaiController;

    if (pertanyaan.tipe == 'esai') {
      esaiController = _esaiControllers.putIfAbsent(
        pertanyaan.id,
        () => TextEditingController(text: jawabanTersimpan ?? ''),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${_halamanSekarang + 1}. ${pertanyaan.teks}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (pertanyaan.tipe == 'pilgan')
            Column(
              children: List.generate(pertanyaan.opsi.length, (index) {
                final label = String.fromCharCode('A'.codeUnitAt(0) + index);
                final valueIndex = index.toString();
                final isSelected = jawabanTersimpan == valueIndex;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? mainPinkColor : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text('$label. ${pertanyaan.opsi[index]}'),
                    value: valueIndex,
                    groupValue: jawabanTersimpan,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _jawaban[pertanyaan.id] = value;
                        });
                      }
                    },
                    activeColor: mainPinkColor,
                  ),
                );
              }),
            )
          else
            TextField(
              controller: esaiController,
              decoration: InputDecoration(
                labelText: 'Ketik jawaban Anda di sini',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 5,
              onChanged: (value) {
                _jawaban[pertanyaan.id] = value;
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainPinkColor = Color(0xFFF875A1);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kuisJudul),
        backgroundColor: mainPinkColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: mainPinkColor))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _daftarPertanyaan.isEmpty
                  ? const Center(child: Text('Pertanyaan tidak tersedia.'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Pertanyaan ${_halamanSekarang + 1} dari ${_daftarPertanyaan.length}',
                                style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (_halamanSekarang + 1) / _daftarPertanyaan.length,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation<Color>(mainPinkColor),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _daftarPertanyaan.length,
                            onPageChanged: (index) {
                              setState(() {
                                _halamanSekarang = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return _buildPertanyaanWidget(_daftarPertanyaan[index]);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_halamanSekarang > 0)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeIn,
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Sebelumnya'),
                                )
                              else
                                const SizedBox.shrink(),
                              const Spacer(),
                              if (_halamanSekarang < _daftarPertanyaan.length - 1)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeIn,
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('Selanjutnya'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: mainPinkColor,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _submitKuis,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.done_all),
                                  label: Text(_isSubmitting
                                      ? 'Mengirim...'
                                      : 'Selesai & Kirim'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}