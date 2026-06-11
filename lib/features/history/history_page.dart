import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../data/models/scan_result_model.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/mongo_service.dart';
import '../../widgets/fat_bottom_nav.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'Semua';

  Future<void> _handleRefresh() async {
    // Memberikan sedikit waktu loading agar UI terasa smooth
    await Future.delayed(const Duration(milliseconds: 500));
    
    final profile = HiveService().getProfile();
    if (profile == null) return;

    try {
      if (!MongoService().isConnected) {
        throw Exception('Offline');
      }
      // 1. Upload unsynced local scans
      final hive = HiveService();
      final unsyncedIds = hive.unsyncedScans;
      if (unsyncedIds.isNotEmpty) {
        final allScans = hive.scanBox.values.toList();
        for (final id in unsyncedIds) {
          final scan = allScans.cast<ScanResultModel?>().firstWhere(
            (s) => s?.id == id,
            orElse: () => null,
          );
          if (scan != null) {
            try {
              await MongoService().syncScanResult(scan, profile.id);
              await hive.removeUnsyncedScan(id);
            } catch (_) {}
          } else {
            await hive.removeUnsyncedScan(id);
          }
        }
      }

      // 2. Download history from cloud
      final history = await MongoService().getHistoryByUserId(profile.id);
      final remoteIds = history.map((s) => s.id).toSet();
      final localScans = hive.getAllScans();

      int downloadedScans = 0;
      int uploadedScans = 0;

      // 2a. Download from cloud to local
      for (final scan in history) {
        if (!hive.scanBox.containsKey(scan.id)) {
          await hive.saveScan(scan.copyWith(userId: profile.id));
          downloadedScans++;
        }
      }

      // 2b. Upload dari lokal ke cloud (jika data lokal belum ada di cloud)
      for (final localScan in localScans) {
        if (!remoteIds.contains(localScan.id)) {
          try {
            await MongoService().syncScanResult(localScan, profile.id);
            uploadedScans++;
          } catch (_) {}
        }
      }
      
      if (mounted) {
        setState(() {});
        String msg = 'Data riwayat sudah sinkron.';
        if (downloadedScans > 0 || uploadedScans > 0) {
          msg = 'Sinkronisasi berhasil: $downloadedScans didownload, $uploadedScans diupload.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF2D7A4F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sedang offline. Menampilkan riwayat lokal.'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyRepository = HistoryRepository(
      hiveService: context.read<HiveService>(),
    );
    var scans = historyRepository.getAllHistory();
    final now = DateTime.now();
    if (_selectedFilter == 'Hari ini') {
      scans = scans.where((s) => s.tanggal.day == now.day && s.tanggal.month == now.month && s.tanggal.year == now.year).toList();
    } else if (_selectedFilter == 'Bulan ini') {
      scans = scans.where((s) => s.tanggal.month == now.month && s.tanggal.year == now.year).toList();
    }
    final weeklyValues = historyRepository.getWeeklyFatAverage();
    final weeklyAverage = weeklyValues.isEmpty
        ? 0
        : (weeklyValues.fold(0.0, (sum, value) => sum + value) /
                weeklyValues.length)
            .round();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8F2),
        bottomNavigationBar: FatBottomNav(
          currentIndex: 1,
          onScanTap: () => context.push('/scanner'),
          onTap: (index) {
            if (index == 0)
              context.go('/home');
            else if (index == 2)
              context.go('/profile');
          },
        ),
      body: Container(
        color: const Color(0xFFF5F8F2),
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF2D7A4F),
            backgroundColor: Colors.white,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TopNavigation(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Riwayat Lemak',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: const Color(0xFF1C3028),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      initialValue: _selectedFilter,
                      onSelected: (value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Semua', child: Text('Semua')),
                        const PopupMenuItem(value: 'Hari ini', child: Text('Hari ini')),
                        const PopupMenuItem(value: 'Bulan ini', child: Text('Bulan ini')),
                      ],
                      child: _FilterChip(
                        label: _selectedFilter,
                        icon: Icons.keyboard_arrow_down,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SummaryCard(
                  weeklyAverage: weeklyAverage,
                  chartValues: weeklyValues,
                ),
                const SizedBox(height: 20),
                // Real scan history from Hive
                if (scans.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Riwayat Scan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF1C3028),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _PillInfo(text: '${scans.length} scan'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...scans.map(
                    (scan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: Key(scan.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await HiveService().deleteScan(scan.id);
                          MongoService().deleteScan(scan.id);
                          setState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Riwayat berhasil dihapus'),
                                backgroundColor: Color(0xFF1C3028),
                              ),
                            );
                          }
                        },
                        child: _ScanHistoryCard(scan: scan),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 60),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: Colors.black12),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat scan',
                          style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Mulai scan makananmu untuk melihat riwayatnya di sini.',
                          style: TextStyle(color: Colors.black38, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ),
      ),
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2D7A4F).withValues(alpha: 0.12),
          ),
          child: const Icon(Icons.exit_to_app_rounded, color: Color(0xFF2D7A4F), size: 28),
        ),
        title: const Text(
          'Keluar Aplikasi?',
          style: TextStyle(
            color: Color(0xFF1C3028),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Yakin ingin keluar dari FatScan?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF4D7060), fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4D7060),
                    side: const BorderSide(color: Color(0xFFC8E2D0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7A4F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─── Scan History Card (Real Data) ───────────────────────────────────────────

class _ScanHistoryCard extends StatelessWidget {
  const _ScanHistoryCard({required this.scan});

  final ScanResultModel scan;

  Color get _fatColor {
    switch (scan.fatStatus) {
      case FatStatus.low:
        return const Color(0xFF44F0D2);
      case FatStatus.medium:
        return const Color(0xFFFFC94D);
      case FatStatus.high:
        return const Color(0xFFFF5C6B);
    }
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2040),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Detail Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scan.imagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: scan.imagePath.startsWith('http')
                      ? Image.network(scan.imagePath, height: 150, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(File(scan.imagePath), height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => const SizedBox()),
                ),
              if (scan.imagePath.isNotEmpty) const SizedBox(height: 16),
              ...scan.foods.map((food) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${food.name} (${food.grams.toInt()}g)', style: const TextStyle(color: Colors.white)),
                        Text('${food.fat.toStringAsFixed(1)}g fat', style: TextStyle(color: _fatColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Lemak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${scan.totalFat.toStringAsFixed(1)}g', style: TextStyle(color: _fatColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2040),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  color: _fatColor.withOpacity(0.2),
                  child: scan.imagePath.isNotEmpty
                      ? (scan.imagePath.startsWith('http')
                          ? Image.network(scan.imagePath, fit: BoxFit.cover)
                          : Image.file(File(scan.imagePath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.qr_code_scanner_rounded, color: _fatColor, size: 22)))
                      : Icon(Icons.qr_code_scanner_rounded, color: _fatColor, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.foods.isNotEmpty
                          ? scan.foods.map((f) => f.name).join(', ')
                          : 'Scan Result',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(scan.tanggal),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${scan.totalFat.toStringAsFixed(1)}g',
                    style: TextStyle(
                      color: _fatColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    scan.fatStatus.shortLabel,
                    style: TextStyle(
                      color: _fatColor.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 5,
                height: 38,
                decoration: BoxDecoration(
                  color: _fatColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
          if (scan.foods.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: scan.foods.map((food) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252D4A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${food.name} ${food.fat.toStringAsFixed(1)}g fat',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    ));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── TopNavigation ────────────────────────────────────────────────────────────

class _TopNavigation extends StatelessWidget {
  const _TopNavigation();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'History / Fat Log',
          style: TextStyle(
            color: Color(0xFF9AB5A5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF4E8),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E2D0)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4D7060),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 18, color: const Color(0xFF4D7060)),
        ],
      ),
    );
  }
}

class _PillInfo extends StatelessWidget {
  const _PillInfo({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF4E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF4D7060),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.weeklyAverage, required this.chartValues});
  final int weeklyAverage;
  final List<double> chartValues;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFFC8E2D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142D7A4F),
            blurRadius: 24,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RATA-RATA 7 HARI',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF4D7060),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$weeklyAverage',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: const Color(0xFF2D7A4F),
                  fontWeight: FontWeight.w800,
                  height: 0.9,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 6),
                child: Text(
                  'g / hari',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF4D7060),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: 230, child: _FatLineChart(values: chartValues)),
        ],
      ),
    );
  }
}

class _FatLineChart extends StatelessWidget {
  const _FatLineChart({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FatChartPainter(values: values, limitValue: 50),
              ),
            ),
            const Positioned(
              top: 18,
              right: 8,
              child: _LimitBadge(text: 'Batas 50g'),
            ),
            const Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: _WeekLabels(),
            ),
          ],
        );
      },
    );
  }
}

class _LimitBadge extends StatelessWidget {
  const _LimitBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD0EDE0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D7A4F).withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2D7A4F),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WeekLabels extends StatelessWidget {
  const _WeekLabels();

  @override
  Widget build(BuildContext context) {
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final label in labels)
          Text(
            label,
            style: TextStyle(
              color: label == 'Min'
                  ? const Color(0xFF2D7A4F)
                  : const Color(0xFF9AB5A5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _FatChartPainter extends CustomPainter {
  _FatChartPainter({required this.values, required this.limitValue});
  final List<double> values;
  final double limitValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const leftPadding = 10.0;
    const rightPadding = 10.0;
    const topPadding = 18.0;
    const bottomPadding = 42.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    
    double maxValue = 50.0;
    for (final v in values) {
      if (v > maxValue) {
        maxValue = v * 1.2;
      }
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFD5EAD9).withOpacity(0.45)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = topPadding + (chartHeight / 2) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final limitY =
        topPadding + chartHeight - (limitValue / maxValue) * chartHeight;
    final limitPaint = Paint()
      ..color = const Color(0xFF2D7A4F).withOpacity(0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(leftPadding, limitY),
      Offset(size.width - rightPadding, limitY),
      limitPaint,
    );

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = leftPadding + (chartWidth / (values.length - 1)) * index;
      final normalized = values[index] / maxValue;
      final y = topPadding + chartHeight - (normalized * chartHeight);
      points.add(Offset(x, y));
    }

    final areaPath = Path()
      ..moveTo(points.first.dx, size.height - bottomPadding);
    for (final point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath.lineTo(points.last.dx, size.height - bottomPadding);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x442D7A4F), Color(0x002D7A4F)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2D7A4F), Color(0xFF48A970)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      linePath.cubicTo(
        current.dx + (next.dx - current.dx) * 0.45,
        current.dy,
        current.dx + (next.dx - current.dx) * 0.55,
        next.dy,
        next.dx,
        next.dy,
      );
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = const Color(0xFFFFFFFF);
    for (final point in points) {
      canvas.drawCircle(point, 4.5, dotPaint);
      canvas.drawCircle(
        point,
        8,
        Paint()..color = const Color(0xFF2D7A4F).withOpacity(0.15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FatChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.limitValue != limitValue;
}


