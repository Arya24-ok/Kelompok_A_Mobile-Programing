// lib/admin_materi_detail_page.dart // Lokasi file: Halaman Detail Materi untuk Admin (termasuk fitur Edit).

import 'package:flutter/material.dart'; // Mengimpor pustaka Flutter Material.
import 'dart:convert'; // Mengimpor pustaka untuk encoding/decoding JSON.
import 'package:http/http.dart'
    as http; // Mengimpor pustaka HTTP untuk permintaan jaringan.
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Pustaka untuk memutar video YouTube.
import 'package:url_launcher/url_launcher.dart'; // Pustaka untuk membuka URL eksternal (link).
import 'package:audioplayers/audioplayers.dart'
    as ap; // Pustaka untuk memutar audio (diberi alias 'ap').
import 'dart:io'
    show
        Platform; // Mengimpor Platform untuk cek OS (hanya di native, bukan web).
import 'package:video_player/video_player.dart'; // Pustaka dasar untuk memutar video.
import 'package:chewie/chewie.dart'; // Pustaka untuk kontrol UI player video yang lebih baik.
import 'package:flutter/foundation.dart'; // Digunakan untuk kIsWeb (cek apakah aplikasi berjalan di web).

// Import Halaman Edit dan Model MateriDetail
import 'package:visualink_app/admin_edit_materi_page.dart'; // Import halaman untuk mengedit materi.
import 'package:visualink_app/materi_detail_page.dart'
    show MateriDetail; // Import model MateriDetail.

class AdminMateriDetailPage extends StatefulWidget {
  // Mendefinisikan widget Stateful.
  final String materiId; // ID unik materi yang akan ditampilkan.
  final String babJudul; // Judul Bab tempat materi ini berada.

  const AdminMateriDetailPage({
    // Konstruktor.
    super.key,
    required this.materiId, // Wajib menerima ID materi.
    required this.babJudul, // Wajib menerima Judul bab.
  });

  @override // Menandai metode override.
  State<AdminMateriDetailPage> createState() => _AdminMateriDetailPageState(); // Membuat dan mengembalikan state.
}

class _AdminMateriDetailPageState extends State<AdminMateriDetailPage> {
  // Kelas state.
  MateriDetail?
  _materiDetail; // Objek untuk menyimpan detail materi yang di-fetch.
  bool _isLoading = true; // State boolean untuk melacak status loading data.
  String? _error; // Variabel untuk menyimpan pesan error.

  // Controller Media
  YoutubePlayerController?
  _youtubeController; // Controller untuk player YouTube.
  VideoPlayerController?
  _driveVideoPlayerController; // Controller dasar untuk video Drive.
  ChewieController? _chewieController; // Controller UI untuk video player.

  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer(); // Instance AudioPlayer.
  ap.PlayerState? _audioPlayerState; // State saat ini dari AudioPlayer.
  bool _isAudioPlaying = false; // Status boolean apakah audio sedang diputar.

  @override // Menandai metode override.
  void initState() {
    // Dipanggil sekali saat objek State dibuat.
    super.initState();
    _fetchMateriDetailById(); // Memulai pengambilan data materi.

    // Mendengarkan perubahan state pada AudioPlayer
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        // Cek apakah widget masih ada.
        setState(() {
          // Perbarui state lokal.
          _audioPlayerState = state;
          _isAudioPlaying =
              state == ap.PlayerState.playing; // Set status sedang bermain.
        });
      }
    });
  }

  // Fungsi fetch detail SATU materi berdasarkan ID
  Future<void> _fetchMateriDetailById() async {
    if (!mounted) return; // Batalkan jika widget sudah unmounted.
    setState(() {
      // Atur state loading.
      _isLoading = true;
      _error = null;
    });
    // URL API untuk mengambil detail materi.
    final url = Uri.parse('http://192.168.1.17:3000/materi/${widget.materiId}');

    try {
      final response = await http.get(url); // Lakukan permintaan GET.
      if (!mounted) return; // Batalkan jika widget unmounted.

      if (response.statusCode == 200) {
        // Jika sukses (200 OK).
        final data = jsonDecode(response.body); // Decode JSON.
        setState(() {
          _materiDetail = MateriDetail.fromJson(data); // Konversi ke model.
          _isLoading = false;
          // Inisialisasi player media setelah state diperbarui.
          Future.microtask(() => _initializePlayers());
        });
      } else if (response.statusCode == 404) {
        // Jika materi tidak ditemukan.
        setState(() {
          _isLoading = false;
          _materiDetail = null;
          _error = 'Materi tidak ditemukan.';
        });
      } else {
        // Penanganan error status kode lainnya.
        throw Exception(
          'Gagal memuat detail materi: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      // Menangkap error koneksi/lainnya.
      if (!mounted) return;
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Inisialisasi semua player
  void _initializePlayers() {
    // 1. YouTube Player
    _youtubeController?.dispose(); // Pastikan controller lama di-dispose.
    _youtubeController = null;
    if (_materiDetail?.youtubeUrl != null &&
        _materiDetail!.youtubeUrl!.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(
        _materiDetail!.youtubeUrl!,
      ); // Ekstrak ID video.
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          // Buat controller YouTube baru.
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        );
      }
    }

    // 2. Drive Video Player (Chewie/VideoPlayer - HANYA DI NATIVE)
    _chewieController?.dispose(); // Dispose controller video lama.
    _driveVideoPlayerController?.dispose();

    // Menggunakan !kIsWeb untuk memastikan kode hanya dijalankan di platform native
    if (!kIsWeb) {
      if (_materiDetail?.driveVideoUrl != null &&
          _materiDetail!.driveVideoUrl!.isNotEmpty) {
        // Cek Platform (sebenarnya !kIsWeb sudah cukup, tapi ini untuk kejelasan)
        if (Platform.isAndroid || Platform.isIOS) {
          // Inisialisasi VideoPlayerController dengan URL network.
          _driveVideoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(_materiDetail!.driveVideoUrl!),
          );
          // Inisialisasi ChewieController untuk UI.
          _chewieController = ChewieController(
            videoPlayerController: _driveVideoPlayerController!,
            autoInitialize: true, // Inisialisasi otomatis.
            looping: false,
            errorBuilder: (context, errorMessage) => const Center(
              // Widget untuk menampilkan error.
              child: Text(
                'Gagal Memuat Video Drive',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      }
    }
    // 3. Drive File (WebView - Dibiarkan nonaktif, diakses via link)

    // 4. Audio Player
    _audioPlayer.stop(); // Hentikan audio yang mungkin sedang berjalan.
    _isAudioPlaying = false;
    if (_materiDetail?.audioUrl != null &&
        _materiDetail!.audioUrl!.isNotEmpty) {
      // Set sumber URL audio (belum diputar).
      _audioPlayer.setSourceUrl(_materiDetail!.audioUrl!);
    }
  }

  // Fungsi Play/Pause Audio
  void _toggleAudioPlayback() async {
    if (_materiDetail?.audioUrl == null || _materiDetail!.audioUrl!.isEmpty)
      return; // Batalkan jika tidak ada URL.

    if (_isAudioPlaying) {
      // Jika sedang bermain.
      await _audioPlayer.pause(); // Pause.
    } else {
      // Jika sedang berhenti/pause.
      if (_audioPlayerState ==
              ap.PlayerState.completed || // Jika sudah selesai atau stop.
          _audioPlayerState == ap.PlayerState.stopped) {
        await _audioPlayer.stop(); // Hentikan.
        // Set ulang sumber (untuk memastikan bisa diputar lagi dari awal).
        await _audioPlayer.setSourceUrl(_materiDetail!.audioUrl!);
        await _audioPlayer.resume(); // Putar/Lanjutkan.
      } else {
        await _audioPlayer.resume(); // Lanjutkan dari posisi terakhir.
      }
    }
  }

  // Fungsi Helper untuk Tombol Link Eksternal
  Widget _buildExternalLinkButton(String label, String url, IconData icon) {
    // Menggunakan Colors.indigo untuk warna Admin yang seragam
    const mainAdminColor = Colors.indigo;

    if (url.isEmpty)
      return const SizedBox.shrink(); // Jangan tampilkan jika URL kosong.

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ElevatedButton.icon(
        // Tombol dengan ikon.
        icon: Icon(icon),
        label: Text(label),
        onPressed: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            // Cek apakah URL bisa dibuka.
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            ); // Buka di aplikasi eksternal (browser/Google Drive).
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                // Tampilkan SnackBar jika gagal.
                SnackBar(content: Text('Tidak bisa membuka link: $url')),
              );
            }
          }
        },
        // Menggunakan warna Admin
        style: ElevatedButton.styleFrom(
          backgroundColor: mainAdminColor,
          foregroundColor: Colors.white,
        ), // Styling tombol Admin.
      ),
    );
  }

  @override // Menandai metode override.
  void dispose() {
    // Dipanggil saat widget dihapus dari tree.
    // Pastikan semua controller media di-dispose untuk mencegah kebocoran memori.
    _youtubeController?.dispose();
    _audioPlayer.dispose();
    _chewieController?.dispose();
    _driveVideoPlayerController?.dispose();
    super.dispose();
  }

  @override // Menandai metode override.
  Widget build(BuildContext context) {
    // Metode untuk membangun UI.
    // Menggunakan Colors.indigo untuk warna Admin yang seragam
    const mainAdminColor = Colors.indigo;

    return Scaffold(
      // Mengembalikan Scaffold.
      appBar: AppBar(
        // Bilah aplikasi.
        title: Text(
          // Judul AppBar (menampilkan judul materi jika sudah dimuat).
          _isLoading
              ? widget.babJudul
              : _materiDetail?.judul ?? 'Detail Materi',
        ),
        // Menggunakan warna Admin
        backgroundColor: mainAdminColor, // Warna latar belakang AppBar.
        foregroundColor: Colors.white, // Warna teks/ikon AppBar.
        actions: [
          // Aksi (tombol) di sisi kanan AppBar.
          // Tombol Edit
          if (_materiDetail !=
              null) // Hanya tampilkan jika data materi sudah dimuat.
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Materi',
              onPressed: () {
                Navigator.push(
                  // Navigasi ke halaman edit.
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminEditMateriPage(
                      materi: _materiDetail!,
                    ), // Melewatkan objek MateriDetail.
                  ),
                ).then((updated) {
                  // Setelah kembali dari halaman edit.
                  if (updated == true)
                    _fetchMateriDetailById(); // Jika ada perubahan (updated == true), refresh data.
                });
              },
            ),
        ],
      ),
      body:
          _isLoading // Cek status loading.
          // Jika loading, tampilkan indikator.
          ? Center(child: CircularProgressIndicator(color: mainAdminColor))
          // Jika error, tampilkan pesan error.
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          // Jika data null (meski tidak error), tampilkan pesan.
          : _materiDetail == null
          ? const Center(child: Text('Data materi tidak ditemukan.'))
          // Jika data ada, tampilkan konten dalam SingleChildScrollView.
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Materi
                  Text(
                    _materiDetail!.judul,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Judul Bab terkait.
                  Text(
                    'Bab: ${widget.babJudul}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const Divider(height: 32),
                  // Deskripsi Materi
                  Text(
                    _materiDetail!.deskripsi,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),

                  // 1. YouTube Player
                  if (_youtubeController != null) ...[
                    // Tampilkan jika controller YouTube ada.
                    const Text(
                      "Video YouTube:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.all(4.0),
                      color: Colors.black, // Latar belakang hitam untuk video.
                      child: YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                        // Menggunakan warna Admin
                        progressIndicatorColor: mainAdminColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 2. VIDEO DRIVE (HYBRID SOLUTION)
                  if (_materiDetail?.driveVideoUrl != null &&
                      _materiDetail!.driveVideoUrl!.isNotEmpty) ...[
                    // Cek apakah BUKAN Web (Native)
                    if (!kIsWeb) ...[
                      // Jika berjalan di Android/iOS.
                      // Spread operator untuk Native Widgets
                      const Text(
                        "Video Google Drive:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_chewieController !=
                          null) // Jika controller Chewie sudah diinisialisasi.
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SizedBox(
                            height: 300,
                            child: Chewie(
                              controller: _chewieController!,
                            ), // Tampilkan Chewie Player.
                          ),
                        )
                      else
                        // Tampilkan loading saat player sedang inisialisasi.
                        Center(
                          child: CircularProgressIndicator(
                            color: mainAdminColor,
                          ),
                        ),
                    ] else // Jika Web, tampilkan tombol eksternal karena VideoPlayer tidak kompatibel di Web.
                      _buildExternalLinkButton(
                        'Video Google Drive (Buka di Browser)',
                        _materiDetail!.driveVideoUrl!,
                        Icons.open_in_new,
                      ),

                    const SizedBox(height: 16),
                  ],

                  // 3. FILE DRIVE (Link Eksternal)
                  if (_materiDetail?.driveFileUrl != null &&
                      _materiDetail!.driveFileUrl!.isNotEmpty)
                    _buildExternalLinkButton(
                      // Tampilkan tombol untuk membuka dokumen.
                      'File Google Drive (Dokumen)',
                      _materiDetail!.driveFileUrl!,
                      Icons.description,
                    ),

                  // 4. Audio Controls
                  if (_materiDetail?.audioUrl != null &&
                      _materiDetail!.audioUrl!.isNotEmpty) ...[
                    // Tampilkan kontrol audio jika URL ada.
                    const Text(
                      "Audio:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            // Ikon Play/Pause yang berubah.
                            _isAudioPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                          ),
                          iconSize: 40,
                          // Menggunakan warna Admin
                          color: mainAdminColor,
                          onPressed: _toggleAudioPlayback, // Fungsi toggle.
                        ),
                        Text(
                          // Teks status.
                          _isAudioPlaying ? 'Sedang Memutar...' : 'Putar Audio',
                        ),
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
