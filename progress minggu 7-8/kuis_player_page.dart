// lib/kuis_player_page.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Tambah: Untuk mengambil token
import 'package:visualink_app/kuis_models.dart'; // Import model Pertanyaan, JawabanSiswa, HasilKuis

// Halaman utama untuk memainkan kuis (menampilkan soal satu per satu)
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
  // Daftar pertanyaan yang dimuat dari API
  List<Pertanyaan> _daftarPertanyaan = [];
  bool _isLoading = true; // Status loading data
  String? _error; // Pesan error jika gagal memuat

  // Untuk mengontrol navigasi PageView (digunakan untuk menampilkan soal satu per satu)
  final PageController _pageController = PageController();
  // Index halaman/soal yang sedang ditampilkan
  int _halamanSekarang = 0;

  // Untuk menyimpan jawaban siswa.
  // Key: ID Pertanyaan (String), Value: Jawaban (String: index opsi untuk pilgan, atau teks untuk esai)
  final Map<String, String> _jawaban = {};

  // Map untuk menyimpan controllers esai agar stateful (memperbaiki masalah mengetik mundur)
  final Map<String, TextEditingController> _esaiControllers = {};

  // Status saat mengirim jawaban ke backend
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Memuat pertanyaan kuis saat halaman dibuka
    _fetchPertanyaan();
  }

  // Fungsi untuk mengambil daftar Pertanyaan kuis dari API
  Future<void> _fetchPertanyaan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // URL API untuk mengambil pertanyaan berdasarkan kuisId
    // !!! GANTI IP ANDA SESUAI ALAMAT BACKEND !!!
    final url = Uri.parse(
      'http://192.168.1.17:3000/kuis/${widget.kuisId}/pertanyaan',
    );
    try {
      final response = await http.get(url);
      if (!mounted) {
        return; // Mencegah setState dipanggil setelah widget dibuang
      }

      if (response.statusCode == 200) {
        // Parsing respons JSON ke dalam list Pertanyaan
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _daftarPertanyaan =
              data.map((json) => Pertanyaan.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        // Penanganan jika kuis ditemukan tapi tidak ada pertanyaan (status 404 dari backend)
        if (response.statusCode == 404) {
          setState(() {
            _daftarPertanyaan = [];
            _isLoading = false;
          });
        } else {
          // Melempar exception jika status code lainnya
          throw Exception(
            'Gagal memuat pertanyaan: Status ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Menangani error koneksi atau lainnya
      setState(() {
        _error =
            'Error: ${e.toString()}. Pastikan koneksi dan API sudah benar.';
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk submit (mengirim) semua jawaban ke backend
  Future<void> _submitKuis() async {
    // Validasi: pastikan semua soal terjawab sebelum submit
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
        const SnackBar(
          content: Text('Otorisasi gagal. Token tidak ditemukan. Harap Login Ulang.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
      return; // Hentikan proses submit
    }

    // Ubah Map jawaban (_jawaban) menjadi List<JawabanSiswa> dalam format JSON
    final List<Map<String, dynamic>> jawabanList = _jawaban.entries.map((
      entry,
    ) {
      return JawabanSiswa(
        pertanyaanId: entry.key,
        jawabanTeks: entry.value,
      ).toJson();
    }).toList();

    // URL API untuk submit kuis
    // !!! GANTI IP ANDA SESUAI ALAMAT BACKEND !!!
    final url = Uri.parse(
      'http://192.168.1.17:3000/kuis/${widget.kuisId}/submit',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userToken, 
        },
        body: jsonEncode({'jawaban': jawabanList}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // --- PERUBAHAN UTAMA DI SINI ---
        if (data['isNilaiDisembunyikan'] == true) {
             // Jika backend memberitahu nilai disembunyikan
             _showNilaiDisembunyikanDialog();
        } else {
             // Jika nilai ditampilkan, tampilkan dialog hasil
             final hasil = HasilKuis.fromJson(data);
             _showHasilDialog(hasil);
        }
        // --- AKHIR PERUBAHAN UTAMA ---

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
  
  // Fungsi baru untuk dialog nilai disembunyikan
  void _showNilaiDisembunyikanDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Kuis Selesai!'),
        content: const Text(
          'Jawaban Anda telah dikirim dan disimpan. Nilai kuis ini disembunyikan oleh guru dan akan ditampilkan kemudian.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); 
              Navigator.of(context).pop(); // Kembali ke halaman list kuis
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menampilkan dialog hasil kuis (Hanya jika nilaiTampil = true)
  void _showHasilDialog(HasilKuis hasil) {
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan klik di luar
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
              // Menampilkan skor tanpa desimal
              'Skor Anda: ${hasil.skor.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),
            Text('Total Soal: ${hasil.totalSoal}'),
            Text('Jawaban Benar: ${hasil.totalBenar}'),
            // TODO: Tambahkan pengecekan 'nilaiTampil' dari Kuis
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Tutup dialog hasil
              Navigator.of(context).pop(); // Kembali ke halaman list kuis
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
    // Dispose semua controller esai yang telah dibuat
    for (final controller in _esaiControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Widget untuk membangun tampilan soal, menyesuaikan Pilgan atau Esai
  Widget _buildPertanyaanWidget(Pertanyaan pertanyaan) {
    const mainPinkColor = Color(0xFFF875A1);
    String? jawabanTersimpan = _jawaban[pertanyaan.id];

    TextEditingController? esaiController;

    if (pertanyaan.tipe == 'esai') {
      // Ambil atau buat controller dari map (memperbaiki masalah mengetik mundur)
      esaiController = _esaiControllers.putIfAbsent(
        pertanyaan.id,
        () => TextEditingController(text: jawabanTersimpan ?? ''),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding disesuaikan
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teks Pertanyaan
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                // Menampilkan nomor dan teks pertanyaan
                '${_halamanSekarang + 1}. ${pertanyaan.teks}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tampilan Jawaban (Pilgan atau Esai)
          if (pertanyaan.tipe == 'pilgan')
            // Opsi Pilihan Ganda (menggunakan RadioListTile)
            Column(
              children: List.generate(pertanyaan.opsi.length, (index) {
                // Konversi index ke huruf A, B, C, D...
                final label = String.fromCharCode('A'.codeUnitAt(0) + index);
                final valueIndex =
                    index.toString(); // Nilai yang disimpan sebagai jawaban

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: jawabanTersimpan == valueIndex
                      ? 4
                      : 1, // Elevasi ditingkatkan jika terpilih
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      // Border berwarna pink jika terpilih
                      color: jawabanTersimpan == valueIndex
                          ? mainPinkColor
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text('$label. ${pertanyaan.opsi[index]}'),
                    value: valueIndex, // Simpan jawaban sebagai index (String)
                    groupValue:
                        jawabanTersimpan, // Ambil jawaban yang tersimpan
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _jawaban[pertanyaan.id] =
                              value; // Simpan/perbarui jawaban
                        });
                      }
                    },
                    activeColor:
                        mainPinkColor, // Warna pink untuk pilihan aktif
                  ),
                );
              }),
            )
          else // Tipe Esai (menggunakan TextField)
            TextField(
              // Gunakan controller yang stateful
              controller: esaiController,
              decoration: InputDecoration(
                labelText: 'Ketik jawaban Anda di sini',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 5,
              // Cukup update map _jawaban. JANGAN PANGGIL setState()
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
          ? const Center(
              child: CircularProgressIndicator(color: mainPinkColor),
            ) // Tampilkan loading
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)),
                )
              : _daftarPertanyaan.isEmpty
                  ? const Center(
                      child: Text('Kuis ini belum memiliki pertanyaan.'))
                  // Tampilkan PageView untuk soal
                  : Column(
                      children: [
                        // Indikator halaman/progress bar
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Teks indikator pertanyaan ke-X dari Y
                              Text(
                                'Pertanyaan ${_halamanSekarang + 1} dari ${_daftarPertanyaan.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Progress Bar
                              LinearProgressIndicator(
                                value: (_halamanSekarang + 1) /
                                    _daftarPertanyaan.length,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  mainPinkColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Konten Soal (menggunakan PageView untuk navigasi swipe)
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _daftarPertanyaan.length,
                            // Memperbarui index halaman saat berpindah
                            onPageChanged: (index) {
                              setState(() {
                                _halamanSekarang = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final pertanyaan = _daftarPertanyaan[index];
                              // Panggil widget pembangun soal untuk soal saat ini
                              return _buildPertanyaanWidget(pertanyaan);
                            },
                          ),
                        ),
                        // Tombol Navigasi Bawah
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Tombol Sebelumnya (Hanya muncul jika bukan halaman pertama)
                              if (_halamanSekarang > 0)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeIn,
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Sebelumnya'),
                                )
                              else
                                const SizedBox
                                    .shrink(), // Kosongkan tempat tombol jika di soal pertama

                              const Spacer(), // Memberi jarak fleksibel
                              // Tombol Selanjutnya / Selesai
                              if (_halamanSekarang <
                                  _daftarPertanyaan.length - 1)
                                // Tombol Selanjutnya (Jika belum di halaman terakhir)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
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
                              else // Tombol Selesai (Jika di halaman terakhir)
                                ElevatedButton.icon(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _submitKuis, // Dinonaktifkan saat sedang submit
                                  icon: _isSubmitting
                                      // Tampilkan indikator loading saat submit
                                      ? const SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.done_all),
                                  label: Text(
                                    _isSubmitting
                                        ? 'Mengirim...'
                                        : 'Selesai & Kirim Jawaban',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
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
