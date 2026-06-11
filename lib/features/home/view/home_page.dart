import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/scan_result_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../data/services/hive_service.dart';
import '../../../data/services/mongo_service.dart';
import '../../../widgets/fat_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HistoryRepository _repo;
  late final HiveService _hive;

  double _consumedFat = 0.0;
  double _consumedCalories = 0.0;
  int _todayScanCount = 0;
  double _avgFatPerScan = 0.0;
  ScanResultModel? _latestScan;
  List<ScanResultModel> _recentScans = [];

  String _userName = 'Pengguna';
  double _maxFat = 65.0;
  double _maxCalories = 2000.0;

  @override
  void initState() {
    super.initState();
    _repo = HistoryRepository();
    _hive = HiveService();
    _loadData();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final profile = _hive.getProfile();
    if (profile == null) return;

    try {
      if (!MongoService().isConnected) {
        throw Exception('Offline');
      }
      final unsyncedIds = _hive.unsyncedScans;
      if (unsyncedIds.isNotEmpty) {
        final allScans = _hive.scanBox.values.toList();
        for (final id in unsyncedIds) {
          final scan = allScans.cast<ScanResultModel?>().firstWhere(
            (s) => s?.id == id,
            orElse: () => null,
          );
          if (scan != null) {
            try {
              await MongoService().syncScanResult(scan, profile.id);
              await _hive.removeUnsyncedScan(id);
            } catch (_) {}
          } else {
            await _hive.removeUnsyncedScan(id);
          }
        }
      }

      final history = await MongoService().getHistoryByUserId(profile.id);
      final remoteIds = history.map((s) => s.id).toSet();
      final localScans = _hive.getAllScans();

      int downloadedScans = 0;
      int uploadedScans = 0;

      // 1. Download dari cloud ke lokal
      for (final scan in history) {
        if (!_hive.scanBox.containsKey(scan.id)) {
          await _hive.saveScan(scan.copyWith(userId: profile.id));
          downloadedScans++;
        }
      }

      // 2. Upload dari lokal ke cloud (jika data lokal belum ada di cloud)
      for (final localScan in localScans) {
        if (!remoteIds.contains(localScan.id)) {
          try {
            await MongoService().syncScanResult(localScan, profile.id);
            uploadedScans++;
          } catch (_) {}
        }
      }
      
      if (mounted) {
        _loadData(); // reload dashboard stats
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

  void _loadData() {
    setState(() {
      final profile = _hive.getProfile();
      _userName = profile?.nama ?? 'Pengguna';
      _maxFat = profile?.targetLemakHarian ?? 65.0;
      _maxCalories = profile?.targetKaloriHarian ?? 2000.0;

      _consumedFat = _repo.getTodayTotalFat();
      _consumedCalories = _repo.getTodayTotalCalories();
      _todayScanCount = _repo.getTodayScanCount();
      _avgFatPerScan = _repo.getAverageFatPerScan();
      _latestScan = _repo.getLatestScan();
      _recentScans = _repo.getAllHistory().take(5).toList();
    });
  }

  int get _calPercent => _maxCalories > 0 ? ((_consumedCalories / _maxCalories) * 100).round().clamp(0, 100) : 0;
  int get _fatPercent => _maxFat > 0 ? ((_consumedFat / _maxFat) * 100).round().clamp(0, 100) : 0;

  String get _calStatusLabel {
    final ratio = _maxCalories > 0 ? (_consumedCalories / _maxCalories) : 0;
    if (ratio < 0.5) return 'Sesuai Target';
    if (ratio < 0.9) return 'Hampir Penuh';
    return 'Melebihi Batas!';
  }

  Color get _calStatusColor {
    final ratio = _maxCalories > 0 ? (_consumedCalories / _maxCalories) : 0;
    if (ratio < 0.5) return const Color(0xFF2D7A4F);
    if (ratio < 0.9) return const Color(0xFFFFC947);
    return const Color(0xFFFF5C6B);
  }

  @override
  Widget build(BuildContext context) {
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
          currentIndex: 0,
          onScanTap: () async {
            await context.push('/scanner');
            _loadData();
          },
          onTap: (index) {
            if (index == 1)
              context.go('/history');
            else if (index == 2)
              context.go('/profile');
          },
        ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFF5F8F2)),
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF2D7A4F),
            backgroundColor: Colors.white,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(userName: _userName),
                const SizedBox(height: 20),
                Text(
                  'Home Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF9AB5A5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                _DailyGoalsCard(
                  consumedCalories: _consumedCalories,
                  maxCalories: _maxCalories,
                  consumedFat: _consumedFat,
                  maxFat: _maxFat,
                  calPercent: _calPercent,
                  calStatusLabel: _calStatusLabel,
                  calStatusColor: _calStatusColor,
                  latestScan: _latestScan,
                  onScanTap: () async {
                    await context.push('/scanner');
                    _loadData();
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickStatCard(
                        icon: Icons.restaurant_menu,
                        iconColor: const Color(0xFF2D7A4F),
                        title: 'Total Scan',
                        value: '$_todayScanCount',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickStatCard(
                        icon: Icons.water_drop_outlined,
                        iconColor: const Color(0xFFB8D34B),
                        title: 'Rata Lemak',
                        value: '${_avgFatPerScan.toStringAsFixed(1)}g',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickStatCard(
                        icon: Icons.track_changes_rounded,
                        iconColor: const Color(0xFFFFC947),
                        title: 'Max Lemak',
                        value: '${_maxFat.toStringAsFixed(0)}g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Scan Terakhir',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1C3028),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/history'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2D7A4F),
                      ),
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_recentScans.isEmpty)
                  _EmptyRecentScan(
                    onScanTap: () async {
                      await context.push('/scanner');
                      _loadData();
                    },
                  )
                else
                  SizedBox(
                    height: 245,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentScans.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _RealScanCard(scan: _recentScans[index]);
                      },
                    ),
                  ),
                const SizedBox(height: 18),
                const _TipsCard(),
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyRecentScan extends StatelessWidget {
  const _EmptyRecentScan({required this.onScanTap});

  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E2D0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            size: 40,
            color: Color(0xFFC8E2D0),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada scan hari ini',
            style: TextStyle(
              color: Color(0xFF9AB5A5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onScanTap,
            child: const Text('Scan Sekarang'),
          ),
        ],
      ),
    );
  }
}

// ─── Real Scan Card (dari Hive) ───────────────────────────────────────────────

class _RealScanCard extends StatelessWidget {
  const _RealScanCard({required this.scan});

  final ScanResultModel scan;

  Color get _accentColor {
    switch (scan.fatStatus) {
      case FatStatus.low:
        return const Color(0xFF24E2A8);
      case FatStatus.medium:
        return const Color(0xFFFFC94D);
      case FatStatus.high:
        return const Color(0xFFFF5C6B);
    }
  }

  String get _timeLabel {
    final diff = DateTime.now().difference(scan.tanggal);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return 'Kemarin';
  }

  @override
  Widget build(BuildContext context) {
    final foodName = scan.foods.isNotEmpty
        ? scan.foods.map((f) => f.name).join(', ')
        : 'Scan Result';

    final tagColor = scan.fatStatus == FatStatus.high
        ? const Color(0xFFFFEBEE)
        : scan.fatStatus == FatStatus.medium
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFE8F5E9);

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E2D0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _accentColor.withOpacity(0.2),
                image: scan.imagePath.isNotEmpty && File(scan.imagePath).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(scan.imagePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: scan.imagePath.isEmpty || !File(scan.imagePath).existsSync()
                  ? Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: _accentColor.withOpacity(0.8),
                        size: 38,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              foodName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1C3028),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 12, color: Color(0xFF9AB5A5)),
                const SizedBox(width: 4),
                Text(
                  _timeLabel,
                  style: const TextStyle(
                    color: Color(0xFF4D7060),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TagChip(
                  label: 'Lemak: ${scan.totalFat.toStringAsFixed(1)}g',
                  background: tagColor,
                  textColor: _accentColor,
                ),
                _TagChip(
                  label: '${scan.totalCalories.toStringAsFixed(0)} kkal',
                  background: const Color(0xFFEBF4E8),
                  textColor: const Color(0xFF4D7060),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFD0EDE0),
          child: ClipOval(
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2D7A4F), Color(0xFF48C78A)],
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Halo, $userName!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF1C3028),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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

class _DailyGoalsCard extends StatelessWidget {
  const _DailyGoalsCard({
    required this.consumedCalories,
    required this.maxCalories,
    required this.consumedFat,
    required this.maxFat,
    required this.calPercent,
    required this.calStatusLabel,
    required this.calStatusColor,
    required this.latestScan,
    required this.onScanTap,
  });

  final double consumedCalories;
  final double maxCalories;
  final double consumedFat;
  final double maxFat;
  final int calPercent;
  final String calStatusLabel;
  final Color calStatusColor;
  final ScanResultModel? latestScan;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFFC8E2D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142D7A4F),
            blurRadius: 28,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Harian',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF1C3028),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jaga pola makan seimbang hari ini.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4D7060)),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 300;
              final content = isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GoalsSummaryText(
                          consumedCalories: consumedCalories,
                          maxCalories: maxCalories,
                          consumedFat: consumedFat,
                          maxFat: maxFat,
                          statusLabel: calStatusLabel,
                          statusColor: calStatusColor,
                        ),
                        const SizedBox(height: 16),
                        Center(child: _ProgressRing(percent: calPercent)),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _GoalsSummaryText(
                            consumedCalories: consumedCalories,
                            maxCalories: maxCalories,
                            consumedFat: consumedFat,
                            maxFat: maxFat,
                            statusLabel: calStatusLabel,
                            statusColor: calStatusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ProgressRing(percent: calPercent),
                      ],
                    );

              return content;
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF4E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC8E2D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF2D7A4F),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    latestScan != null
                        ? 'Scan terakhir: ${latestScan!.foods.isNotEmpty ? latestScan!.foods.first.name : "—"} • Lemak: ${latestScan!.totalFat.toStringAsFixed(1)}g'
                        : 'Belum ada scan hari ini',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4D7060),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onScanTap,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan Sekarang'),
              style: FilledButton.styleFrom(
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

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 10,
              backgroundColor: const Color(0xFFD0EDE0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2D7A4F),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1C3028),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Terpakai',
                style: TextStyle(
                  color: Color(0xFF4D7060),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalsSummaryText extends StatelessWidget {
  const _GoalsSummaryText({
    required this.consumedCalories,
    required this.maxCalories,
    required this.consumedFat,
    required this.maxFat,
    required this.statusLabel,
    required this.statusColor,
  });

  final double consumedCalories;
  final double maxCalories;
  final double consumedFat;
  final double maxFat;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${consumedCalories.toStringAsFixed(0)} kkal',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF2D7A4F),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '/ ${maxCalories.toStringAsFixed(0)} kkal (Target)',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF4D7060),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: statusColor),
            const SizedBox(width: 8),
            Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5F1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Lemak: ${consumedFat.toStringAsFixed(1)}g / Target: ${maxFat.toStringAsFixed(0)}g',
            style: const TextStyle(
              color: Color(0xFF4D7060),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFFC8E2D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9AB5A5),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1C3028),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RecentScanItem {
  const _RecentScanItem({
    required this.name,
    required this.time,
    required this.fatTag,
    required this.calories,
    required this.accentColor,
    required this.icon,
  });

  final String name;
  final String time;
  final String fatTag;
  final String calories;
  final Color accentColor;
  final IconData icon;
}

class _RecentScanCard extends StatelessWidget {
  const _RecentScanCard({required this.item});

  final _RecentScanItem item;

  @override
  Widget build(BuildContext context) {
    final tagColor = item.accentColor == const Color(0xFFFF5C6B)
        ? const Color(0xFFFFEBEE)
        : item.accentColor == const Color(0xFFFFC94D)
        ? const Color(0xFFFFF8E1)
        : const Color(0xFFE8F5E9);

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E2D0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.accentColor.withOpacity(0.85),
                    item.accentColor.withOpacity(0.18),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 12),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      item.icon,
                      color: Colors.white.withOpacity(0.95),
                      size: 38,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.accentColor.withOpacity(0.45),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1C3028),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 12,
                  color: Color(0xFF9AB5A5),
                ),
                const SizedBox(width: 4),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: Color(0xFF4D7060),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TagChip(
                  label: item.fatTag,
                  background: tagColor,
                  textColor: item.accentColor,
                ),
                _TagChip(
                  label: item.calories,
                  background: const Color(0xFFEBF4E8),
                  textColor: const Color(0xFF4D7060),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFFC8E2D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD0EDE0),
              border: Border.all(
                color: const Color(0xFF2D7A4F).withOpacity(0.25),
              ),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: Color(0xFF2D7A4F),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Hari Ini',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF1C3028),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mengurangi makanan yang digoreng dan menggantinya dengan rebusan dapat memotong asupan lemak harian hingga 40%. Coba menu rebus untuk makan malam!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4D7060),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
