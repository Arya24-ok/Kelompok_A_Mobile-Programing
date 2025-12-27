// lib/materi_detail_page.dart

import 'package:flutter/material.dart'; // Mengimpor pustaka dasar Flutter untuk membangun UI.
import 'dart:convert'; // Mengimpor 'dart:convert' untuk mengkonversi data JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk melakukan permintaan jaringan.
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Mengimpor pustaka untuk memutar video YouTube.
import 'package:video_player/video_player.dart'; // Mengimpor pustaka dasar untuk memutar video (digunakan untuk video Drive).
import 'package:chewie/chewie.dart'; // Mengimpor pustaka Chewie, menambahkan kontrol UI ke VideoPlayer.
import 'package:audioplayers/audioplayers.dart'
    as ap; // Mengimpor pustaka Audioplayers untuk memutar audio.
import 'package:url_launcher/url_launcher.dart'; // Mengimpor pustaka untuk membuka URL eksternal (link Drive).
import 'package:flutter/foundation.dart'
    show
        kIsWeb; // [PERBAIKAN]: Import kIsWeb untuk pengecekan platform yang aman di Web.
// import 'dart:io' show Platform; // [DIHAPUS]: dart:io tidak didukung di Web dan menyebabkan error Platform.operatingSystem.

// Model MateriDetail (DEFINISI UTAMA MODEL INI)
class MateriDetail {
  final String id; // ID unik materi.
  final String judul; // Judul materi.
  final String deskripsi; // Deskripsi lengkap materi.
  final String? youtubeUrl; // URL video YouTube (opsional, bisa null).
  final String? driveVideoUrl; // URL video dari Google Drive (opsional).
  final String? driveFileUrl; // URL file/dokumen dari Google Drive (opsional).
  final String? audioUrl; // URL file audio (opsional).

  MateriDetail({
    required this.id, // Parameter wajib: ID.
    required this.judul, // Parameter wajib: Judul.
    required this.deskripsi, // Parameter wajib: Deskripsi.
    this.youtubeUrl, // Parameter opsional.
    this.driveVideoUrl, // Parameter opsional.
    this.driveFileUrl, // Parameter opsional.
    this.audioUrl, // Parameter opsional.
  });

  factory MateriDetail.fromJson(Map<String, dynamic> json) {
    return MateriDetail(
      id: json['_id'], // Mapping ID dari JSON.
      judul: json['judul'], // Mapping judul dari JSON.
      deskripsi: json['deskripsi'], // Mapping deskripsi dari JSON.
      youtubeUrl: json['youtubeUrl'], // Mapping youtubeUrl dari JSON.
      driveVideoUrl: json['driveVideoUrl'], // Mapping driveVideoUrl dari JSON.
      driveFileUrl: json['driveFileUrl'], // Mapping driveFileUrl dari JSON.
      audioUrl: json['audioUrl'], // Mapping audioUrl dari JSON.
    );
  }
}

class MateriDetailPage extends StatefulWidget {
  final String
  babId; // Properti untuk ID Bab (diperlukan, meskipun tidak digunakan di sini).
  final String babJudul; // Properti untuk Judul Bab (diperlukan).
  final String materiId; // Properti untuk ID Materi yang akan ditampilkan.

  const MateriDetailPage({
    super.key,
    required this.babId, // Menerima ID Bab dari halaman sebelumnya.
    required this.babJudul, // Menerima Judul Bab dari halaman sebelumnya.
    required this.materiId, // Menerima ID Materi yang akan dimuat.
  });

  @override
  State<MateriDetailPage> createState() => _MateriDetailPageState(); // Membuat State untuk widget ini.
}

class _MateriDetailPageState extends State<MateriDetailPage> {
  MateriDetail?
  _materiDetail; // Variabel untuk menyimpan data detail materi yang dimuat.
  bool _isLoading =
      true; // Status loading, default true saat mulai memuat data.
  String? _error; // Pesan error jika gagal memuat data.

  YoutubePlayerController?
  _youtubeController; // Controller untuk pemutar video YouTube.
  VideoPlayerController?
  _driveVideoPlayerController; // Controller dasar untuk video Drive.
  ChewieController?
  _chewieController; // Controller Chewie untuk kontrol UI video Drive.

  final ap.AudioPlayer _audioPlayer =
      ap.AudioPlayer(); // Instance AudioPlayer untuk memutar audio.
  ap.PlayerState? _audioPlayerState; // Status pemutar audio saat ini.
  bool _isAudioPlaying = false; // Status apakah audio sedang diputar.

  @override
  void initState() {
    super.initState();
    _fetchMateriDetailById(); // Panggil fungsi untuk mengambil data saat halaman diinisialisasi.
    _audioPlayer.onPlayerStateChanged.listen((state) {
      // Mendengarkan perubahan status pemutar audio.
      if (mounted) {
        // Pastikan widget masih ada sebelum memanggil setState.
        setState(() {
          _audioPlayerState = state; // Perbarui status pemutar audio.
          _isAudioPlaying =
              state == ap.PlayerState.playing; // Set status sedang diputar.
        });
      }
    });
  }

  Future<void> _fetchMateriDetailById() async {
    if (!mounted) return; // Keluar jika widget sudah tidak ada.
    setState(() {
      _isLoading = true; // Set status loading.
      _error = null; // Hapus pesan error sebelumnya.
    });
    // !!! GANTI IP ANDA !!!
    final url = Uri.parse(
      // Menggunakan string interpolation yang benar
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/materi/${widget.materiId}',
    ); // URL API untuk mengambil detail materi.

    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      ); // Lakukan permintaan GET ke API.
      if (!mounted) return; // Keluar jika widget sudah tidak ada.

      if (response.statusCode == 200) {
        // Cek jika respons berhasil (Status 200 OK).
        final data = jsonDecode(
          response.body,
        ); // Dekode body respons menjadi JSON.
        setState(() {
          _materiDetail = MateriDetail.fromJson(
            data,
          ); // Konversi JSON ke model MateriDetail.
          _isLoading = false; // Hentikan loading.

          // Panggil inisialisasi player secara synchronous di dalam setState
          _initializePlayers();
        });
      } else {
        throw Exception(
          // Lempar Exception jika status tidak 200.
          'Gagal memuat detail materi: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return; // Keluar jika widget sudah tidak ada.
      setState(() {
        _error = 'Error: ${e.toString()}'; // Set pesan error.
        _isLoading = false; // Hentikan loading.
      });
    }
  }

  void _initializePlayers() {
    // 1. YouTube
    _youtubeController?.dispose(); // Pastikan controller lama dibersihkan.
    _youtubeController = null; // Setel ulang controller.
    if (_materiDetail?.youtubeUrl != null &&
        _materiDetail!.youtubeUrl!.isNotEmpty) {
      // Cek jika ada URL YouTube.
      final videoId = YoutubePlayer.convertUrlToId(
        _materiDetail!.youtubeUrl!,
      ); // Ambil ID video dari URL.
      if (videoId != null) {
        // Jika ID video valid.
        _youtubeController = YoutubePlayerController(
          // Buat controller baru.
          initialVideoId: videoId, // Set ID video.
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ), // Set pengaturan player.
        );
      }
    }

    // 2. Drive Video Player (Chewie/VideoPlayer)
    _chewieController
        ?.dispose(); // Pastikan controller Chewie lama dibersihkan.
    _driveVideoPlayerController
        ?.dispose(); // Pastikan controller VideoPlayer lama dibersihkan.
    try {
      // Hanya coba inisialisasi VideoPlayer di platform selain Web.
      if (!kIsWeb) {
        if (_materiDetail?.driveVideoUrl != null &&
            _materiDetail!.driveVideoUrl!.isNotEmpty) {
          // Cek jika ada URL video Drive.
          _driveVideoPlayerController = VideoPlayerController.networkUrl(
            // Buat VideoPlayerController dari URL.
            Uri.parse(_materiDetail!.driveVideoUrl!),
          );
          // Set autoInitialize to true if you don't use the FutureBuilder pattern
          _chewieController = ChewieController(
            // Buat ChewieController dengan controller dasar.
            videoPlayerController: _driveVideoPlayerController!,
            autoInitialize: true, // Otomatis inisialisasi video.
            looping: false, // Tidak mengulang video.
            errorBuilder: (context, errorMessage) => const Center(
              // Builder untuk menampilkan pesan error.
              child: Text(
                'Gagal Memuat Video Drive',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // [PERBAIKAN]: Menghapus print() debugging yang tidak diperlukan
      // print('Inisialisasi VideoPlayer gagal: $e');
    }

    // 3. Audio Player
    _audioPlayer.stop(); // Hentikan pemutaran audio sebelumnya.
    _isAudioPlaying = false; // Set status audio tidak diputar.
    if (_materiDetail?.audioUrl != null &&
        _materiDetail!.audioUrl!.isNotEmpty) {
      // Cek jika ada URL audio.
      _audioPlayer.setSourceUrl(
        _materiDetail!.audioUrl!,
      ); // Set sumber audio (belum otomatis putar).
    }
  }

  void _toggleAudioPlayback() async {
    if (_materiDetail?.audioUrl == null ||
        _materiDetail!
            .audioUrl!
            .isEmpty) // Jangan lakukan apa-apa jika URL kosong.
      return;
    if (_isAudioPlaying) {
      // Jika sedang diputar:
      await _audioPlayer.pause(); // Jeda pemutaran.
    } else {
      // Jika tidak sedang diputar:
      if (_audioPlayerState == null ||
          _audioPlayerState == ap.PlayerState.completed ||
          _audioPlayerState == ap.PlayerState.stopped) {
        // Jika selesai atau berhenti total:
        await _audioPlayer
            .stop(); // Hentikan (opsional, untuk memastikan bersih).
        await _audioPlayer.setSourceUrl(
          _materiDetail!.audioUrl!,
        ); // Set ulang sumber (diperlukan untuk putar ulang).
        await _audioPlayer
            .resume(); // Lanjutkan pemutaran (sebenarnya memulai).
      } else {
        await _audioPlayer.resume(); // Lanjutkan pemutaran dari posisi jeda.
      }
    }
  }

  Widget _buildExternalLinkButton(
    BuildContext context,
    String label,
    String url,
    IconData icon,
  ) {
    if (url.isEmpty)
      return const SizedBox.shrink(); // Sembunyikan tombol jika URL kosong.

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ElevatedButton.icon(
        // Widget tombol dengan ikon.
        icon: Icon(icon), // Ikon tombol.
        label: Text(label), // Teks tombol.
        onPressed: () async {
          // Fungsi yang dipanggil saat tombol ditekan.
          final uri = Uri.parse(url); // Parsing URL string menjadi objek Uri.
          if (await canLaunchUrl(uri)) {
            // Cek apakah URL bisa dibuka.
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            ); // Buka URL di aplikasi eksternal (browser/Drive app).
          } else {
            if (mounted) {
              // Pastikan widget masih ada.
              ScaffoldMessenger.of(context).showSnackBar(
                // Tampilkan SnackBar jika gagal membuka.
                SnackBar(content: Text('Tidak bisa membuka link: $url')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(
            0xFF00B2FF,
          ), // Warna latar belakang tombol (biru).
        ),
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController?.dispose(); // Bersihkan controller YouTube.
    _audioPlayer.dispose(); // Bersihkan AudioPlayer.
    _chewieController?.dispose(); // Bersihkan controller Chewie.
    _driveVideoPlayerController?.dispose(); // Bersihkan controller VideoPlayer.
    super.dispose(); // Panggil dispose dari parent.
  }

  @override
  Widget build(BuildContext context) {
    const mainPinkColor = Color(0xFFF875A1); // Definisi warna utama (pink).

    // Mengembalikan widget sesuai status (Loading/Error/Data)
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ); // Tampilkan loading spinner.
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          ), // Tampilkan pesan error.
        ),
      );
    }
    if (_materiDetail == null) {
      return const Scaffold(
        body: Center(
          child: Text('Data materi tidak ditemukan.'),
        ), // Tampilkan pesan jika data null.
      );
    }

    // Jika data sudah dimuat, tampilkan Scaffold utama
    return Scaffold(
      appBar: AppBar(
        title: Text(_materiDetail!.judul), // Tampilkan judul materi di AppBar.
        backgroundColor: mainPinkColor, // Set warna latar belakang AppBar.
        foregroundColor: Colors.white, // Set warna teks dan ikon AppBar.
        // --- BAGIAN INI YANG DIHAPUS ---
        actions: const [], // Menghapus tombol edit yang dikomentari
        // --- AKHIR BAGIAN YANG DIHAPUS ---
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deskripsi
            Text(
              _materiDetail!.deskripsi, // Tampilkan deskripsi materi.
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(height: 32), // Pembatas.
            // Menggunakan Collection If dengan Spread Operator
            if (_youtubeController != null) ...[
              // Jika controller YouTube ada (URL tersedia dan valid).
              const Text(
                "Video YouTube:", // Label untuk Video YouTube.
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(4.0),
                color: Colors.black, // Bingkai hitam di sekitar player.
                child: YoutubePlayer(
                  // Widget pemutar YouTube.
                  // [PERBAIKAN]: Menambahkan Key untuk stabilitas di Web
                  key: ValueKey(_materiDetail!.youtubeUrl),
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: mainPinkColor,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Menggunakan Collection If dengan nested If/Else
            if (_materiDetail!.driveVideoUrl != null &&
                _materiDetail!.driveVideoUrl!.isNotEmpty) ...[
              // Jika ada URL video Drive.
              if (!kIsWeb) ...[
                // Jika platform adalah Android, iOS, atau Desktop.
                const Text(
                  "Video Google Drive:", // Label untuk Video Google Drive.
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                // Cek apakah controller sudah diinisialisasi sebelum menampilkannya
                if (_chewieController != null && // Jika ChewieController ada.
                    _chewieController!
                        .videoPlayerController
                        .value
                        .isInitialized) // Dan video sudah diinisialisasi.
                  SizedBox(
                    height: 300,
                    child: Chewie(
                      controller: _chewieController!,
                    ), // Tampilkan Chewie player.
                  )
                else // Jika belum diinisialisasi atau masih loading.
                  // Tambahkan FutureBuilder jika Anda ingin menampilkan progress saat inisialisasi
                  const Center(
                    child: CircularProgressIndicator(
                      color: mainPinkColor,
                    ), // Tampilkan progress indicator.
                  ),
              ] else // Jika Web.
                _buildExternalLinkButton(
                  // Tampilkan tombol link eksternal.
                  context,
                  "Video Google Drive (Buka di Browser)",
                  _materiDetail!.driveVideoUrl!,
                  Icons.open_in_new,
                ),

              const SizedBox(height: 16),
            ],

            // 3. FILE DRIVE (LINK EKSTERNAL)
            if (_materiDetail!.driveFileUrl != null &&
                _materiDetail!.driveFileUrl!.isNotEmpty) ...[
              // Jika ada URL file Drive.
              _buildExternalLinkButton(
                // Tampilkan tombol link eksternal.
                context,
                "Buka File Google Drive (Dokumen)",
                _materiDetail!.driveFileUrl!,
                Icons.description,
              ),
              const SizedBox(height: 16),
            ],

            // 4. AUDIO (CONTROL)
            if (_materiDetail!.audioUrl != null &&
                _materiDetail!.audioUrl!.isNotEmpty) ...[
              // Jika ada URL audio.
              // Menggunakan Spread Operator untuk memasukkan beberapa widget
              const Text(
                "Audio:", // Label untuk Audio.
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isAudioPlaying // Cek status, tampilkan ikon jeda atau putar.
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    iconSize: 40,
                    color: mainPinkColor,
                    onPressed:
                        _toggleAudioPlayback, // Panggil fungsi putar/jeda.
                  ),
                  Text(
                    _isAudioPlaying ? 'Sedang Memutar...' : 'Putar Audio',
                  ), // Teks status audio.
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
