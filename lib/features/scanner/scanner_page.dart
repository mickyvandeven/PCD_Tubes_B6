import 'package:flutter/material.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8F2),
        foregroundColor: const Color(0xFF1C3028),
        title: const Text('Scanner'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 42),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC8E2D0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x142D7A4F),
                      blurRadius: 26,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D7A4F), Color(0xFF48C78A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D7A4F).withOpacity(0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Siap scan makanan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1C3028),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Halaman scanner siap disambungkan ke kamera atau input gambar nantinya.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4D7060),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 72),
                  ],
                ),
              ),
              Positioned(
                bottom: -2,
                left: 28,
                right: 28,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Mulai Scan'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
