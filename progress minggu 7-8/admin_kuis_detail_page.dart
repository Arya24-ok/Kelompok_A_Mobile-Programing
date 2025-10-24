// lib/admin_kuis_detail_page.dart // Lokasi file: Halaman detail untuk mengelola pertanyaan dan melihat hasil kuis (Admin).

import 'package:flutter/material.dart'; // Mengimpor pustaka Flutter Material.
import 'dart:convert'; // Mengimpor pustaka untuk encoding/decoding JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk permintaan jaringan.
import 'package:visualink_app/kuis_models.dart'; // Import model data kuis (seperti Pertanyaan).
import 'package:visualink_app/admin_hasil_kuis_page.dart'; // Import halaman untuk navigasi ke hasil kuis siswa.

class AdminKuisDetailPage extends StatefulWidget {
  // Mendefinisikan widget Stateful (memiliki state yang bisa berubah).
  final String
  kuisId; // Variabel final untuk menyimpan ID kuis yang sedang dikelola.
  final String kuisJudul; // Variabel final untuk menyimpan Judul kuis.

  const AdminKuisDetailPage({
    // Konstruktor.
    super.key,
    required this.kuisId, // Wajib menerima ID kuis.
    required this.kuisJudul, // Wajib menerima Judul kuis.
  });

  @override // Menandai metode override.
  State<AdminKuisDetailPage> createState() => _AdminKuisDetailPageState(); // Membuat dan mengembalikan state.
}

class _AdminKuisDetailPageState extends State<AdminKuisDetailPage> {
  // Kelas state.
  List<Pertanyaan> _daftarPertanyaan =
      []; // List untuk menyimpan objek pertanyaan dari kuis ini.
  bool _isLoadingPertanyaan =
      true; // State untuk melacak status loading daftar pertanyaan.
  String?
  _errorPertanyaan; // Variabel untuk menyimpan pesan error saat fetch pertanyaan.

  // State untuk form tambah pertanyaan
  final _pertanyaanController =
      TextEditingController(); // Controller untuk teks pertanyaan baru.
  String _tipePertanyaanDipilih =
      'pilgan'; // Tipe pertanyaan default: Pilihan Ganda.
  final List<TextEditingController> _opsiControllers = [
    // List controller untuk opsi jawaban Pilihan Ganda (default 4 opsi).
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _jawabanBenarController =
      TextEditingController(); // Controller untuk jawaban benar (berupa indeks pilgan atau teks esai).
  bool _isLoadingTambah =
      false; // State untuk melacak status loading saat menambahkan pertanyaan baru.

  @override // Menandai metode override.
  void initState() {
    // Dipanggil sekali saat objek State dibuat.
    super.initState();
    _fetchDaftarPertanyaan(); // Memulai pengambilan data daftar pertanyaan kuis.
  }

  Future<void> _fetchDaftarPertanyaan() async {
    // Fungsi asinkron untuk mengambil daftar pertanyaan.
    setState(() {
      // Memperbarui state UI.
      _isLoadingPertanyaan = true; // Atur loading menjadi true.
      _errorPertanyaan = null; // Hapus error sebelumnya.
    });
    // URL API untuk mengambil semua pertanyaan di kuis tertentu.
    final url = Uri.parse(
      'http://192.168.1.17:3000/kuis/${widget.kuisId}/pertanyaan',
    );
    try {
      // Blok try-catch untuk penanganan error.
      final response = await http.get(url); // Melakukan permintaan GET.
      if (!mounted) return; // Keluar jika widget sudah tidak ada (unmounted).
      if (response.statusCode == 200) {
        // Jika sukses (kode 200).
        final List<dynamic> data = jsonDecode(response.body); // Mendecode JSON.
        setState(() {
          // Memperbarui state.
          _daftarPertanyaan =
              data // Memetakan data JSON ke list objek Pertanyaan.
                  .map((json) => Pertanyaan.fromJson(json))
                  .toList();
          _isLoadingPertanyaan = false; // Selesai loading.
        });
      } else {
        // Jika status kode bukan 200.
        if (response.statusCode == 404) // Jika 404 (tidak ditemukan/kosong).
          setState(() {
            _daftarPertanyaan = []; // Kosongkan daftar.
            _isLoadingPertanyaan = false; // Selesai loading.
          });
        else // Untuk error status code lainnya.
          throw Exception(
            'Gagal memuat pertanyaan: Status ${response.statusCode}',
          ); // Melemparkan exception.
      }
    } catch (e) {
      // Menangkap exception (error koneksi, dll.).
      if (!mounted) return; // Keluar jika widget unmounted.
      setState(() {
        // Memperbarui state error.
        _errorPertanyaan = 'Error: ${e.toString()}'; // Simpan pesan error.
        _isLoadingPertanyaan = false; // Selesai loading.
      });
    }
  }

  Future<void> _tambahPertanyaanBaru() async {
    // Fungsi asinkron untuk menambah pertanyaan baru.
    if (_pertanyaanController.text.isEmpty) {
      // Validasi: Teks pertanyaan wajib diisi.
      ScaffoldMessenger.of(context).showSnackBar(
        // Tampilkan SnackBar peringatan.
        const SnackBar(
          content: Text('Teks pertanyaan wajib diisi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return; // Batalkan proses.
    }
    setState(() {
      // Memperbarui state.
      _isLoadingTambah = true; // Atur loading tombol tambah menjadi true.
    });

    List<String> opsiJawaban =
        []; // Variabel untuk menyimpan opsi jawaban (hanya untuk pilgan).
    if (_tipePertanyaanDipilih == 'pilgan') {
      // Logika validasi untuk Pilihan Ganda.
      opsiJawaban =
          _opsiControllers // Ambil teks dari controller opsi.
              .map((controller) => controller.text)
              .where(
                (opsi) => opsi.isNotEmpty,
              ) // Filter hanya opsi yang tidak kosong.
              .toList();
      if (opsiJawaban.length < 2) {
        // Validasi: Minimal harus ada 2 opsi terisi.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pilihan ganda harus memiliki minimal 2 opsi terisi.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoadingTambah = false; // Batalkan loading.
        });
        return; // Batalkan proses.
      }
      if (int.tryParse(_jawabanBenarController.text) == null) {
        // Validasi: Jawaban benar harus berupa angka (indeks).
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Jawaban benar untuk pilgan harus berupa angka indeks (0, 1, 2, ...).',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoadingTambah = false; // Batalkan loading.
        });
        return; // Batalkan proses.
      }
    } else {
      // Logika validasi untuk Esai.
      // Esai
      if (_jawabanBenarController.text.isEmpty) {
        // Validasi: Jawaban benar esai wajib diisi.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jawaban benar untuk esai wajib diisi.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoadingTambah = false; // Batalkan loading.
        });
        return; // Batalkan proses.
      }
    }

    final url = Uri.parse(
      // URL API POST pertanyaan ke kuis tertentu.
      'http://192.168.1.17:3000/kuis/${widget.kuisId}/pertanyaan',
    );
    try {
      // Blok try-catch.
      final response = await http.post(
        // Melakukan permintaan POST.
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        }, // Header JSON.
        body: jsonEncode({
          // Data yang dikirim ke backend.
          'teks': _pertanyaanController.text, // Teks pertanyaan.
          'tipe': _tipePertanyaanDipilih, // Tipe pertanyaan.
          'opsi': opsiJawaban, // Opsi jawaban (hanya diisi jika pilgan).
          'jawabanBenar':
              _jawabanBenarController.text, // Jawaban benar (indeks atau teks).
        }),
      );
      if (!mounted) return; // Cek mounted.
      if (response.statusCode == 201) {
        // Jika sukses dibuat (kode 201).
        _fetchDaftarPertanyaan(); // Refresh daftar pertanyaan.
        _pertanyaanController.clear(); // Bersihkan field pertanyaan.
        for (var controller in _opsiControllers) {
          // Bersihkan semua field opsi.
          controller.clear();
        }
        _jawabanBenarController.clear(); // Bersihkan field jawaban benar.
        ScaffoldMessenger.of(context).showSnackBar(
          // Tampilkan SnackBar sukses.
          const SnackBar(
            content: Text('Pertanyaan berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Jika gagal.
        final errorData = jsonDecode(response.body); // Mendecode data error.
        ScaffoldMessenger.of(context).showSnackBar(
          // Tampilkan SnackBar error dari backend.
          SnackBar(
            content: Text('Gagal: ${errorData['msg'] ?? response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Menangkap error koneksi/lainnya.
      if (!mounted) return; // Cek mounted.
      ScaffoldMessenger.of(context).showSnackBar(
        // Tampilkan SnackBar error.
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Selalu dieksekusi.
      if (mounted) {
        // Cek mounted.
        setState(() {
          _isLoadingTambah = false; // Matikan loading tombol.
        });
      }
    }
  }

  @override // Menandai metode override.
  void dispose() {
    // Dipanggil saat State object dihapus.
    _pertanyaanController.dispose(); // Membuang controller pertanyaan.
    for (var controller in _opsiControllers) {
      // Membuang semua controller opsi.
      controller.dispose();
    }
    _jawabanBenarController.dispose(); // Membuang controller jawaban benar.
    super.dispose(); // Memanggil dispose kelas induk.
  }

  @override // Menandai metode override.
  Widget build(BuildContext context) {
    // Metode untuk membangun UI.
    return Scaffold(
      // Mengembalikan Scaffold.
      appBar: AppBar(
        // Bilah aplikasi.
        title: Text('Kelola Pertanyaan - ${widget.kuisJudul}'), // Judul AppBar.
        backgroundColor: Colors.indigo, // Warna latar belakang AppBar.
        foregroundColor: Colors.white, // Warna teks/ikon AppBar.
        actions: [
          // Aksi di sisi kanan AppBar.
          // Tombol untuk melihat hasil siswa
          IconButton(
            // Tombol Lihat Hasil Siswa.
            icon: const Icon(Icons.bar_chart), // Ikon diagram batang.
            tooltip: 'Lihat Hasil Siswa', // Tooltip.
            onPressed: () {
              // Fungsi saat tombol ditekan.
              Navigator.push(
                // Navigasi ke halaman AdminHasilKuisPage.
                context,
                MaterialPageRoute(
                  builder: (context) => AdminHasilKuisPage(
                    // Membuat instance AdminHasilKuisPage.
                    kuisId: widget.kuisId, // Meneruskan ID kuis.
                    kuisJudul: widget.kuisJudul, // Meneruskan Judul kuis.
                  ),
                ),
              );
            },
          ),
          IconButton(
            // Tombol Refresh.
            icon: const Icon(Icons.refresh), // Ikon refresh.
            tooltip: 'Refresh',
            onPressed:
                _fetchDaftarPertanyaan, // Memanggil fungsi refresh daftar pertanyaan.
          ),
        ],
      ),
      // Gunakan ListView agar form bisa di-scroll
      body: SingleChildScrollView(
        // Konten utama yang dapat di-scroll.
        padding: const EdgeInsets.all(16.0), // Padding 16.
        child: Column(
          // Mengatur widget anak secara vertikal.
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Meregangkan elemen secara horizontal.
          children: [
            // Daftar widget anak.
            // --- Area Daftar Pertanyaan ---
            const Text(
              // Judul Daftar Pertanyaan.
              'Daftar Pertanyaan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _isLoadingPertanyaan // Cek status loading pertanyaan.
                ? const Center(
                    // Jika loading, tampilkan indikator.
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _errorPertanyaan !=
                      null // Cek error.
                ? Center(
                    // Jika ada error, tampilkan pesan error.
                    child: Text(
                      _errorPertanyaan!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _daftarPertanyaan
                      .isEmpty // Cek apakah daftar kosong.
                ? const Center(
                    // Jika kosong, tampilkan pesan.
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Belum ada pertanyaan.'),
                    ),
                  )
                : ListView.builder(
                    // Jika ada data, tampilkan dalam list.
                    shrinkWrap:
                        true, // Penting di dalam SingleChildScrollView (ambil ruang seperlunya).
                    physics:
                        const NeverScrollableScrollPhysics(), // Menonaktifkan scroll ListView (agar dikendalikan oleh SingleChildScrollView).
                    itemCount: _daftarPertanyaan.length, // Jumlah pertanyaan.
                    itemBuilder: (context, index) {
                      // Fungsi pembuat item.
                      final p =
                          _daftarPertanyaan[index]; // Mengambil objek pertanyaan.
                      return Card(
                        // Menggunakan Card untuk setiap pertanyaan.
                        margin: const EdgeInsets.only(top: 8.0),
                        child: ListTile(
                          // Item list.
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ), // Nomor urut pertanyaan.
                          title: Text(p.teks), // Teks pertanyaan.
                          subtitle: Text(
                            // Detail tipe dan jawaban benar.
                            'Tipe: ${p.tipe} | Jawaban: ${p.jawabanBenar}',
                          ),
                          // TODO: Tambahkan tombol edit/hapus pertanyaan // Komentar: Perlu ditambahkan tombol aksi.
                        ),
                      );
                    },
                  ),

            const Divider(
              height: 40,
              thickness: 2,
            ), // Garis pemisah horizontal.
            // --- Form Tambah Pertanyaan ---
            Card(
              // Card untuk membungkus form tambah pertanyaan.
              elevation: 2, // Efek bayangan.
              child: Padding(
                // Padding di dalam card.
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  // Kolom untuk elemen form.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      // Judul form.
                      'Tambah Pertanyaan Baru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12), // Spasi.
                    TextField(
                      // Field Teks Pertanyaan.
                      controller:
                          _pertanyaanController, // Terhubung ke controller.
                      decoration: const InputDecoration(
                        labelText: 'Teks Pertanyaan',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3, // Multiline.
                    ),
                    const SizedBox(height: 12), // Spasi.
                    DropdownButtonFormField<String>(
                      // Dropdown untuk memilih Tipe Pertanyaan.
                      value:
                          _tipePertanyaanDipilih, // Nilai yang dipilih saat ini.
                      items: const [
                        // Pilihan item dropdown.
                        DropdownMenuItem(
                          value: 'pilgan',
                          child: Text('Pilihan Ganda'),
                        ),
                        DropdownMenuItem(value: 'esai', child: Text('Esai')),
                      ],
                      onChanged: (value) {
                        // Fungsi saat nilai diubah.
                        if (value != null)
                          setState(() {
                            // Memperbarui state tipe pertanyaan.
                            _tipePertanyaanDipilih = value;
                          });
                      },
                      decoration: const InputDecoration(
                        // Dekorasi dropdown.
                        labelText: 'Tipe Pertanyaan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12), // Spasi.
                    // Tampilan kondisional untuk Pilgan atau Esai
                    AnimatedCrossFade(
                      // Widget untuk transisi tampilan (Pilgan vs Esai).
                      duration: const Duration(
                        milliseconds: 300,
                      ), // Durasi transisi.
                      // Tampilan Pilgan
                      firstChild: Column(
                        // Tampilan untuk Pilihan Ganda.
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Opsi Jawaban:'), // Label opsi.
                          ...List.generate(
                            // Membangun 4 field opsi jawaban.
                            _opsiControllers.length,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: TextField(
                                // Field input opsi.
                                controller: _opsiControllers[index],
                                decoration: InputDecoration(
                                  labelText:
                                      'Opsi ${index + 1}', // Label: Opsi 1, Opsi 2, dst.
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8), // Spasi.
                          TextField(
                            // Field Jawaban Benar (Indeks).
                            controller: _jawabanBenarController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Indeks Jawaban Benar (0, 1, 2, ...)', // Petunjuk untuk indeks.
                              border: OutlineInputBorder(),
                            ),
                            keyboardType:
                                TextInputType.number, // Jenis keyboard angka.
                          ),
                        ],
                      ),
                      // Tampilan Esai
                      secondChild: TextField(
                        // Tampilan untuk Esai.
                        controller: _jawabanBenarController,
                        decoration: const InputDecoration(
                          labelText:
                              'Jawaban Benar Esai', // Label jawaban esai (teks).
                          border: OutlineInputBorder(),
                        ),
                      ),
                      // Logika toggle tampilan
                      crossFadeState:
                          _tipePertanyaanDipilih ==
                              'pilgan' // Menentukan tampilan mana yang akan ditampilkan.
                          ? CrossFadeState
                                .showFirst // Jika Pilgan, tampilkan firstChild (Opsi + Indeks).
                          : CrossFadeState
                                .showSecond, // Jika Esai, tampilkan secondChild (Jawaban Teks).
                    ),

                    const SizedBox(height: 16), // Spasi.
                    ElevatedButton.icon(
                      // Tombol Simpan Pertanyaan.
                      onPressed:
                          _isLoadingTambah // Cek loading.
                          ? null // Jika loading, dinonaktifkan.
                          : _tambahPertanyaanBaru, // Panggil fungsi tambah pertanyaan.
                      icon:
                          _isLoadingTambah // Tampilan ikon/loading.
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ), // Indikator loading.
                            )
                          : const Icon(Icons.add), // Ikon Tambah.
                      label: Text(
                        // Teks tombol.
                        _isLoadingTambah ? 'Menyimpan...' : 'Tambah Pertanyaan',
                      ),
                      style: ElevatedButton.styleFrom(
                        // Gaya tombol.
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
