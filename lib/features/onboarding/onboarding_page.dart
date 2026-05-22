import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── Tema putih susu + hijau ───────────────────────────────
  static const Color _background = Color(0xFFF5F8F2);
  static const Color _primary = Color(0xFF2D7A4F);
  static const Color _primaryLight = Color(0xFF48A970);
  static const Color _container = Color(0xFFD0EDE0);
  static const Color _textPrimary = Color(0xFF1C3028);
  static const Color _textSecondary = Color(0xFF4D7060);
  static const Color _dotInactive = Color(0xFFC8E2D0);

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      icon: Icons.camera_alt_rounded,
      title: 'Scan Makananmu',
      description:
          'Arahkan kamera ke makanan untuk memulai scan dan mendapatkan hasil dengan cepat.',
    ),
    _OnboardingItem(
      icon: Icons.bar_chart_rounded,
      title: 'Lihat Analisis Lemak',
      description:
          'FatScan menampilkan analisis kandungan lemak agar kamu lebih mudah memahami makananmu.',
    ),
    _OnboardingItem(
      icon: Icons.history_rounded,
      title: 'Pantau Riwayatmu',
      description:
          'Semua hasil scan tersimpan rapi sehingga kamu bisa mengecek riwayat kapan saja.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tombol Lewati ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextButton(
                onPressed: _goHome,
                style: TextButton.styleFrom(foregroundColor: _primary),
                child: const Text(
                  'Lewati',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // ── PageView konten ───────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ikon lingkaran
                        Container(
                          width: 168,
                          height: 168,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _container,
                            border: Border.all(
                              color: _primary.withOpacity(0.20),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withOpacity(0.15),
                                blurRadius: 32,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(item.icon, size: 72, color: _primary),
                        ),
                        const SizedBox(height: 40),

                        // Judul
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Deskripsi
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Indikator + Tombol ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dot indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => _AnimatedDot(
                        isActive: index == _currentPage,
                        activeColor: _primary,
                        inactiveColor: _dotInactive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tombol aksi
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, _primaryLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.30),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _items.length - 1) {
                            _goHome();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                          _currentPage == _items.length - 1
                              ? 'Mulai Sekarang'
                              : 'Lanjut',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Dot ──────────────────────────────────────────────────────────────

class _AnimatedDot extends StatelessWidget {
  const _AnimatedDot({
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

// ── Onboarding Item Model ─────────────────────────────────────────────────────

class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
