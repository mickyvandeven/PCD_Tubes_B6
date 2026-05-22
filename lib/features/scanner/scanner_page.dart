import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/scan_result_model.dart';
import 'scanner_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ScannerPage – halaman utama scanner
// ═══════════════════════════════════════════════════════════════════════════

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScannerProvider(),
      child: const _ScannerView(),
    );
  }
}

class _ScannerView extends StatelessWidget {
  const _ScannerView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScannerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1020),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            provider.reset();
            Navigator.of(context).pop();
          },
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          'FAT SCAN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, ScannerProvider provider) {
    switch (provider.state) {
      case ScanState.idle:
        return _IdleView();
      case ScanState.picking:
        return _LoadingView(message: 'Memilih gambar...');
      case ScanState.analyzing:
        return _LoadingView(message: 'AI sedang menganalisis makanan...');
      case ScanState.done:
        if (provider.result != null) {
          return _ResultView(
            result: provider.result!,
            imageFile: provider.imageFile,
          );
        }
        return _IdleView();
      case ScanState.error:
        return _ErrorView(message: provider.errorMessage);
    }
  }
}

// ─── Idle View ───────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScannerProvider>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11162A), Color(0xFF0D1020), Color(0xFF111830)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              const Spacer(),
              // ── Ilustrasi scanner ──
              _ScanIllustration(),
              const SizedBox(height: 32),
              Text(
                'Scan Makananmu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Arahkan kamera ke makananmu.\nAI akan mendeteksi kadar lemak secara otomatis.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              // Tips kadar lemak
              _FatTipsRow(),
              const Spacer(),
              // ── Tombol aksi ──
              _ActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Buka Kamera',
                gradient: const LinearGradient(
                  colors: [Color(0xFF44F0D2), Color(0xFF2D79FF)],
                ),
                onTap: () => provider.scanFromCamera(),
              ),
              const SizedBox(height: 14),
              _ActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Pilih dari Galeri',
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D79FF), Color(0xFF7B5EA7)],
                ),
                onTap: () => provider.scanFromGallery(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF44F0D2).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF44F0D2).withOpacity(0.25),
                width: 2,
              ),
            ),
          ),
          // Middle ring
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF44F0D2).withOpacity(0.4),
                width: 2,
              ),
              color: const Color(0xFF44F0D2).withOpacity(0.05),
            ),
          ),
          // Center icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF44F0D2), Color(0xFF2D79FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF44F0D2).withOpacity(0.35),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          // Scanning corner decorations
          ..._buildCorners(),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    return [
      Positioned(top: 22, left: 22, child: _CornerDeco(topLeft: true)),
      Positioned(top: 22, right: 22, child: _CornerDeco(topRight: true)),
      Positioned(bottom: 22, left: 22, child: _CornerDeco(bottomLeft: true)),
      Positioned(bottom: 22, right: 22, child: _CornerDeco(bottomRight: true)),
    ];
  }
}

class _CornerDeco extends StatelessWidget {
  const _CornerDeco({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  final bool topLeft, topRight, bottomLeft, bottomRight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: _CornerPainter(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });
  final bool topLeft, topRight, bottomLeft, bottomRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF44F0D2)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = 4.0;

    if (topLeft) {
      canvas.drawLine(Offset(r, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(0, r), Offset(0, h), paint);
      canvas.drawArc(
        Rect.fromLTWH(0, 0, r * 2, r * 2),
        3.14,
        -1.57,
        false,
        paint,
      );
    } else if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(w - r, 0), paint);
      canvas.drawLine(Offset(w, r), Offset(w, h), paint);
      canvas.drawArc(
        Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2),
        4.71,
        -1.57,
        false,
        paint,
      );
    } else if (bottomLeft) {
      canvas.drawLine(Offset(r, h), Offset(w, h), paint);
      canvas.drawLine(Offset(0, 0), Offset(0, h - r), paint);
      canvas.drawArc(
        Rect.fromLTWH(0, h - r * 2, r * 2, r * 2),
        1.57,
        -1.57,
        false,
        paint,
      );
    } else if (bottomRight) {
      canvas.drawLine(Offset(0, h), Offset(w - r, h), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h - r), paint);
      canvas.drawArc(
        Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2),
        0,
        -1.57,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FatTipsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FatLevelDot(color: const Color(0xFF44F0D2), label: 'Low < 10g'),
        const SizedBox(width: 16),
        _FatLevelDot(color: const Color(0xFFFFC94D), label: 'Med 10-25g'),
        const SizedBox(width: 16),
        _FatLevelDot(color: const Color(0xFFFF5C6B), label: 'High > 25g'),
      ],
    );
  }
}

class _FatLevelDot extends StatelessWidget {
  const _FatLevelDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF11162A), Color(0xFF0D1020)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF44F0D2), Color(0xFF2D79FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF44F0D2).withOpacity(0.3),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mohon tunggu sebentar...',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScannerProvider>();
    return Container(
      color: const Color(0xFF0D1020),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF5C6B),
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Oops!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => provider.reset(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF44F0D2),
                    foregroundColor: const Color(0xFF0D1020),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Result View – Halaman hasil scan
// ═══════════════════════════════════════════════════════════════════════════

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, this.imageFile});

  final ScanResultModel result;
  final File? imageFile;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScannerProvider>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF11162A), Color(0xFF0D1020)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Preview gambar ──
                    if (imageFile != null) _ImagePreview(file: imageFile!),
                    const SizedBox(height: 20),
                    // ── Fat Status Banner ──
                    _FatStatusBanner(result: result),
                    const SizedBox(height: 16),
                    // ── Daftar makanan terdeteksi ──
                    Text(
                      'Makanan Terdeteksi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(result.foods.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FoodItemCard(
                          foodIndex: i,
                          food: result.foods[i],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // ── Total Summary ──
                    _TotalSummaryCard(result: result),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // ── Action buttons ──
            _ResultActionBar(
              onSave: () async {
                await provider.saveScan();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Scan disimpan ke riwayat!'),
                      backgroundColor: Color(0xFF1B2040),
                    ),
                  );
                  provider.reset();
                  Navigator.of(context).pop();
                }
              },
              onRescan: () => provider.reset(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Image Preview ────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.file});
  final File file;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF44F0D2).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                ),
              ),
            ),
            // AI label
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF44F0D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF0D1020),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI Analyzed',
                      style: TextStyle(
                        color: Color(0xFF0D1020),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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

// ─── Fat Status Banner ────────────────────────────────────────────────────────

class _FatStatusBanner extends StatelessWidget {
  const _FatStatusBanner({required this.result});
  final ScanResultModel result;

  @override
  Widget build(BuildContext context) {
    final fatStatus = result.fatStatus;
    final Color primaryColor;
    final Color bgColor;
    final IconData statusIcon;

    switch (fatStatus) {
      case FatStatus.low:
        primaryColor = const Color(0xFF44F0D2);
        bgColor = const Color(0xFF0D2E29);
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case FatStatus.medium:
        primaryColor = const Color(0xFFFFC94D);
        bgColor = const Color(0xFF2C2210);
        statusIcon = Icons.warning_amber_rounded;
        break;
      case FatStatus.high:
        primaryColor = const Color(0xFFFF5C6B);
        bgColor = const Color(0xFF2D1217);
        statusIcon = Icons.dangerous_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'TOTAL FAT',
                style: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.4)),
                ),
                child: Text(
                  fatStatus.label,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.totalFat.toStringAsFixed(1)}g',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${result.totalCalories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${result.foods.length} makanan',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (fatStatus == FatStatus.high) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5C6B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFFF5C6B), size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Makanan ini mengandung lemak tinggi. Perhatikan asupan harianmu!',
                      style: TextStyle(
                        color: Color(0xFFFF5C6B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Food Item Card ───────────────────────────────────────────────────────────

class _FoodItemCard extends StatefulWidget {
  const _FoodItemCard({required this.foodIndex, required this.food});

  final int foodIndex;
  final FoodItem food;

  @override
  State<_FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<_FoodItemCard> {
  late TextEditingController _gramController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _gramController = TextEditingController(
      text: widget.food.grams.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant _FoodItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      _gramController.text = widget.food.grams.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _gramController.dispose();
    super.dispose();
  }

  void _onGramSubmit(BuildContext context) {
    final val = double.tryParse(_gramController.text);
    if (val != null && val > 0) {
      context.read<ScannerProvider>().updateGram(widget.foodIndex, val);
    }
    setState(() => _isEditing = false);
    FocusScope.of(context).unfocus();
  }

  Color get _fatColor {
    final f = widget.food.fat;
    if (f > 20) return const Color(0xFFFF5C6B);
    if (f >= 8) return const Color(0xFFFFC94D);
    return const Color(0xFF44F0D2);
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F37),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _fatColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: _fatColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Confidence: ${(food.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Fat badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _fatColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _fatColor.withOpacity(0.4)),
                ),
                child: Text(
                  '${food.fat.toStringAsFixed(1)}g fat',
                  style: TextStyle(
                    color: _fatColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Gram editor ──
          Row(
            children: [
              const Text(
                'Gram:',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(width: 10),
              // Minus button
              _GramButton(
                icon: Icons.remove,
                onTap: () {
                  final current =
                      double.tryParse(_gramController.text) ?? food.grams;
                  final newVal = (current - 10).clamp(10.0, 9999.0);
                  _gramController.text = newVal.toStringAsFixed(0);
                  context.read<ScannerProvider>().updateGram(
                    widget.foodIndex,
                    newVal,
                  );
                },
              ),
              const SizedBox(width: 8),
              // Input field
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _gramController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF111830),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.white24,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.white24,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _fatColor.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    suffix: const Text(
                      'g',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                  onTap: () => setState(() => _isEditing = true),
                  onSubmitted: (_) => _onGramSubmit(context),
                  onEditingComplete: () => _onGramSubmit(context),
                ),
              ),
              const SizedBox(width: 8),
              // Plus button
              _GramButton(
                icon: Icons.add,
                onTap: () {
                  final current =
                      double.tryParse(_gramController.text) ?? food.grams;
                  final newVal = (current + 10).clamp(10.0, 9999.0);
                  _gramController.text = newVal.toStringAsFixed(0);
                  context.read<ScannerProvider>().updateGram(
                    widget.foodIndex,
                    newVal,
                  );
                },
              ),
              const Spacer(),
              // Calories
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${food.calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Kalori',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GramButton extends StatelessWidget {
  const _GramButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF252D4A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
    );
  }
}

// ─── Total Summary Card ───────────────────────────────────────────────────────

class _TotalSummaryCard extends StatelessWidget {
  const _TotalSummaryCard({required this.result});
  final ScanResultModel result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2038), Color(0xFF141A2E)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF44F0D2),
            label: 'Total Lemak',
            value: '${result.totalFat.toStringAsFixed(1)} g',
            valueColor: const Color(0xFF44F0D2),
          ),
          const Divider(color: Colors.white10, height: 20),
          _SummaryRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFFC94D),
            label: 'Total Kalori',
            value: '${result.totalCalories.toStringAsFixed(0)} kcal',
            valueColor: const Color(0xFFFFC94D),
          ),
          const Divider(color: Colors.white10, height: 20),
          _SummaryRow(
            icon: Icons.fastfood_rounded,
            iconColor: Colors.white54,
            label: 'Jumlah Makanan',
            value: '${result.foods.length} item',
            valueColor: Colors.white70,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Result Action Bar ────────────────────────────────────────────────────────

class _ResultActionBar extends StatelessWidget {
  const _ResultActionBar({required this.onSave, required this.onRescan});

  final VoidCallback onSave;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1020),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          // Scan ulang
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRescan,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Scan Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Simpan
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Simpan Hasil'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF44F0D2),
                foregroundColor: const Color(0xFF0D1020),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
