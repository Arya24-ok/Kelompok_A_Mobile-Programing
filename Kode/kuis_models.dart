// lib/kuis_models.dart

class KuisItem {
  final String id;
  final String judul;
  final String deskripsi;
  final bool nilaiTampil;
  final int maxAttempts; // [BARU] Properti untuk batas pengerjaan

  KuisItem({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.nilaiTampil,
    this.maxAttempts = 0, // Default 0 artinya Unlimited
  });

  factory KuisItem.fromJson(Map<String, dynamic> json) {
    return KuisItem(
      id: json['_id'] ?? '',
      judul: json['judul'] ?? 'Tanpa Judul',
      deskripsi: json['deskripsi'] ?? '',
      nilaiTampil: json['nilaiTampil'] ?? true,
      // [PENTING] Membaca data maxAttempts dari server
      maxAttempts: json['maxAttempts'] ?? 0, 
    );
  }

  // Fungsi untuk update tampilan sementara tanpa reload
  KuisItem copyWith({
    String? id,
    String? judul,
    String? deskripsi,
    bool? nilaiTampil,
    int? maxAttempts,
  }) {
    return KuisItem(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      nilaiTampil: nilaiTampil ?? this.nilaiTampil,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
  }
}

// --- Model Lain Tetap Sama ---

class Pertanyaan {
  final String id;
  final String teks;
  final String tipe;
  final List<String> opsi;
  final String jawabanBenar;

  Pertanyaan({
    required this.id,
    required this.teks,
    required this.tipe,
    required this.opsi,
    required this.jawabanBenar,
  });

  factory Pertanyaan.fromJson(Map<String, dynamic> json) {
    return Pertanyaan(
      id: json['_id'],
      teks: json['teks'],
      tipe: json['tipe'],
      opsi: List<String>.from(json['opsi'] ?? []),
      jawabanBenar: json['jawabanBenar'] ?? '',
    );
  }
}

class JawabanSiswa {
  final String pertanyaanId;
  final String jawabanTeks;

  JawabanSiswa({required this.pertanyaanId, required this.jawabanTeks});

  Map<String, dynamic> toJson() {
    return {
      'pertanyaanId': pertanyaanId,
      'jawaban': jawabanTeks,
    };
  }
}

class HasilKuis {
  final int skor;
  final int totalSoal;
  final int totalBenar;

  HasilKuis({
    required this.skor,
    required this.totalSoal,
    required this.totalBenar,
  });

  factory HasilKuis.fromJson(Map<String, dynamic> json) {
    return HasilKuis(
      skor: json['skor'] ?? 0,
      totalSoal: json['totalSoal'] ?? 0,
      totalBenar: json['totalBenar'] ?? 0,
    );
  }
}

class HasilSiswa {
  final String id;
  final String username;
  final int skor;
  final DateTime tanggal;

  HasilSiswa({
    required this.id,
    required this.username,
    required this.skor,
    required this.tanggal,
  });

  factory HasilSiswa.fromJson(Map<String, dynamic> json) {
    return HasilSiswa(
      id: json['_id'],
      username: json['user']['username'] ?? 'Anonim',
      skor: json['skor'],
      tanggal: DateTime.parse(json['tanggalSelesai']),
    );
  }
}