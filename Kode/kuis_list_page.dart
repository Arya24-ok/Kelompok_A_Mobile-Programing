import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:visualink_app/kuis_models.dart';
import 'package:visualink_app/kuis_player_page.dart';

class KuisListPage extends StatefulWidget {
  final String babId;
  final String babJudul;
  const KuisListPage({super.key, required this.babId, required this.babJudul});

  @override
  State<KuisListPage> createState() => _KuisListPageState();
}

class _KuisListPageState extends State<KuisListPage> {
  List<KuisItem> _daftarKuis = [];
  bool _isLoading = true;
  String? _error;

  static const mainPinkColor = Color(0xFFF875A1);
  static const lightPinkColor = Color.fromARGB(0x1A, 0xF8, 0x75, 0xA1);

  @override
  void initState() {
    super.initState();
    _fetchDaftarKuis();
  }

  Future<void> _fetchDaftarKuis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // !!! GANTI IP ANDA !!!
    final url = Uri.parse(
      'https://khedivial-semiplastic-valentine.ngrok-free.dev/bab/${widget.babId}/kuis',
    );
    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _daftarKuis = data.map((json) => KuisItem.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        if (response.statusCode == 404) {
          setState(() {
            _daftarKuis = [];
            _isLoading = false;
          });
        } else {
          throw Exception('Gagal memuat Kuis: Status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Error: ${e.toString()}. Pastikan server backend berjalan dan alamat IP benar.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kuis: ${widget.babJudul}',
        ),
        backgroundColor: mainPinkColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchDaftarKuis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: mainPinkColor),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchDaftarKuis,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainPinkColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _daftarKuis.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada kuis yang tersedia untuk Bab ini.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _daftarKuis.length,
                      itemBuilder: (context, index) {
                        final kuis = _daftarKuis[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, 
                              vertical: 8
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: lightPinkColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.quiz, color: mainPinkColor),
                            ),
                            title: Text(
                              kuis.judul,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: const Text('Ketuk untuk mulai mengerjakan'),
                            // Menu Edit/Delete/Play dihapus dari sini (trailing)
                            onTap: () {
                              // Langsung masuk ke player saat diklik
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => KuisPlayerPage(
                                    kuisId: kuis.id,
                                    kuisJudul: kuis.judul,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}