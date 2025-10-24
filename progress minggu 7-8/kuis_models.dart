// lib/kuis_models.dart // Lokasi file: Berisi semua model data (data structures) untuk fungsionalitas Kuis.


// Model untuk Kuis (digunakan di halaman list)
class KuisItem {
  final String id; // ID unik kuis (final, tidak dapat diubah).
  final String judul; // Judul kuis (final).
  // Catatan: Properti ini dibuat non-final agar dapat diubah langsung jika diperlukan, 
  // namun di 'admin_kuis_management_page.dart' diubah menggunakan copyWith()
  bool nilaiTampil; // Status apakah nilai kuis boleh ditampilkan kepada siswa. 

  // Konstruktor utama.
  KuisItem({required this.id, required this.judul, required this.nilaiTampil});

  // Factory constructor untuk membuat objek dari data JSON.
  factory KuisItem.fromJson(Map<String, dynamic> json) {
    return KuisItem(
      id: json['_id'], // Mengambil ID dari field '_id'.
      judul: json['judul'], // Mengambil judul.
      nilaiTampil: json['nilaiTampil'] ?? true, // Mengambil status nilaiTampil, default true.
    );
  }

  // Menambahkan metode copyWith untuk memudahkan update objek secara immutable.
  // Ini diperlukan agar kode di 'admin_kuis_management_page.dart' dapat berjalan tanpa error.
  KuisItem copyWith({
    String? id,
    String? judul,
    bool? nilaiTampil, // Properti yang akan diupdate.
  }) {
    return KuisItem(
      id: id ?? this.id, // Jika id baru null, gunakan id lama.
      judul: judul ?? this.judul, // Jika judul baru null, gunakan judul lama.
      nilaiTampil: nilaiTampil ?? this.nilaiTampil, // Mengganti nilaiTampil jika disediakan.
    );
  }
}

// Model untuk satu Pertanyaan
class Pertanyaan {
  final String id; // ID unik pertanyaan.
  final String teks; // Isi atau teks pertanyaan.
  final String tipe; // Tipe pertanyaan (pilgan atau esai).
  final List<String> opsi; // Opsi jawaban (hanya relevan untuk tipe 'pilgan').
  final String jawabanBenar; // Jawaban yang benar (indeks untuk pilgan, teks untuk esai).

  // Konstruktor utama.
  Pertanyaan({
    required this.id,
    required this.teks,
    required this.tipe,
    required this.opsi,
    required this.jawabanBenar,
  });

  // Factory constructor untuk membuat objek Pertanyaan dari data JSON.
  factory Pertanyaan.fromJson(Map<String, dynamic> json) {
    return Pertanyaan(
      id: json['_id'],
      teks: json['teks'] ?? '', // Default string kosong.
      tipe: json['tipe'] ?? 'esai', // Default tipe 'esai'.
      opsi: List<String>.from(json['opsi'] ?? []), // Mengambil list opsi.
      jawabanBenar: json['jawabanBenar'] ?? '', // Default string kosong.
    );
  }
}

// Model untuk mengirim jawaban siswa
class JawabanSiswa {
  final String pertanyaanId; // ID pertanyaan yang dijawab.
  final String jawabanTeks; // Jawaban yang diberikan siswa (indeks pilgan atau teks esai).

  // Konstruktor utama.
  JawabanSiswa({required this.pertanyaanId, required this.jawabanTeks});

  // Metode untuk mengkonversi objek menjadi Map (JSON) untuk dikirim ke API POST.
  Map<String, dynamic> toJson() => {
    'pertanyaanId': pertanyaanId,
    'jawaban': jawabanTeks,
  };
}

// Model untuk hasil kuis (diterima setelah submit)
class HasilKuis {
  final int skor; // Total skor yang didapatkan.
  final int totalBenar; // Jumlah soal yang dijawab benar otomatis.
  final int totalSoal; // Jumlah total soal.

  // Konstruktor utama.
  HasilKuis({required this.skor, required this.totalBenar, required this.totalSoal});

  // Factory constructor dari JSON.
  factory HasilKuis.fromJson(Map<String, dynamic> json) {
    return HasilKuis(
      skor: json['skor'] ?? 0, // Default 0.
      totalBenar: json['totalBenar'] ?? 0, // Default 0.
      totalSoal: json['totalSoal'] ?? 0, // Default 0.
    );
  }
}

// Model untuk hasil siswa (dilihat admin)
class HasilSiswa {
  final String id; // ID unik hasil kuis.
  final String username; // Username siswa yang mengikuti kuis.
  final int skor; // Skor yang diperoleh siswa.
  final DateTime tanggal; // Tanggal kuis diselesaikan.

  // Konstruktor utama.
  HasilSiswa({required this.id, required this.username, required this.skor, required this.tanggal});

  // Factory constructor dari JSON.
    factory HasilSiswa.fromJson(Map<String, dynamic> json) {
    return HasilSiswa(
      id: json['_id'],
      // Asumsi backend melakukan populate user dan mengirim username
      username: json['user']?['username'] ?? 'Siswa (ID: ${json['user']})', // Mengambil username dari objek user, jika ada.
      skor: json['skor'] ?? 0, // Default 0.
      tanggal: DateTime.tryParse(json['tanggalSelesai']) ?? DateTime.now(), // Mengambil tanggal selesai, default waktu sekarang jika gagal parse.
    );
  }
}