import 'package:flutter/material.dart';

class MateriPage extends StatelessWidget {
  const MateriPage({super.key});

  @override
  Widget build(BuildContext context) {
    const mainPinkColor = Color(0xFFF875A1);
    const lightPinkBackground = Color(0xFFFFF0F3);

    return Scaffold(
      backgroundColor: lightPinkBackground,
      appBar: AppBar(
        title: const Text('Materi'),
        backgroundColor: mainPinkColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Desain Publikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF00B2FF),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: List.generate(6, (index) {
                  return ElevatedButton(
                    onPressed: () {
                      print('Tombol Bab ${index + 1} ditekan');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainPinkColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Bab ${index + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}