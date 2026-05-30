import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/scan_result_model.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../widgets/fat_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.userName = 'Ridho'});

  final String userName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HistoryRepository _repo;

  int _consumedFat = 0;
  int _todayScanCount = 0;
  double _avgFatPerScan = 0;
  ScanResultModel? _latestScan;
  List<ScanResultModel> _recentScans = [];

  static const int _maxFat = 50;

  @override
  void initState() {
    super.initState();
    _repo = HistoryRepository();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _consumedFat = _repo.getTodayTotalFat().round();
      _todayScanCount = _repo.getTodayScanCount();
      _avgFatPerScan = _repo.getAverageFatPerScan();
      _latestScan = _repo.getLatestScan();
      _recentScans = _repo.getAllHistory().take(5).toList();
    });
  }

  int get _percent => ((_consumedFat / _maxFat) * 100).round().clamp(0, 100);

  String get _statusLabel {
    if (_consumedFat < 20) return 'On Track';
    if (_consumedFat < 40) return 'Getting Close';
    return 'Over Limit!';
  }

  Color get _statusColor {
    if (_consumedFat < 20) return const Color(0xFF2D7A4F);
    if (_consumedFat < 40) return const Color(0xFFFFC947);
    return const Color(0xFFFF5C6B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(userName: widget.userName),
                const SizedBox(height: 20),
                Text(
                  'Home Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF9AB5A5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _DailyFatCard(
                        consumedFat: _consumedFat,
                        maxFat: _maxFat,
                        percent: _percent,
                        statusLabel: _statusLabel,
                        statusColor: _statusColor,
                        latestScan: _latestScan,
                        onScanTap: () async {
                          await context.push('/scanner');
                          _loadData();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _QuickStatCard(
                            icon: Icons.restaurant_menu,
                            iconColor: Color(0xFF2D7A4F),
                            title: 'Scanned Today',
                            value: '$_todayScanCount items',
                          ),
                          SizedBox(height: 12),
                          _QuickStatCard(
                            icon: Icons.water_drop_outlined,
                            iconColor: Color(0xFFB8D34B),
                            title: 'Avg Fat',
                            value: '${_avgFatPerScan.toStringAsFixed(1)}g /meal',
                          ),
                          SizedBox(height: 12),
                          _QuickStatCard(
                            icon: Icons.local_fire_department_outlined,
                            iconColor: Color(0xFFFFC947),
                            title: 'Total Scan',
                            value: '${_repo.getTotalScanCount()} scan',
                          ),
                        ],
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
                    height: 200,
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
    );
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accentColor.withOpacity(0.85),
                    _accentColor.withOpacity(0.18),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white.withOpacity(0.95),
                  size: 38,
                ),
              ),
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
                  label: 'Fat: ${scan.totalFat.toStringAsFixed(1)}g',
                  background: tagColor,
                  textColor: _accentColor,
                ),
                _TagChip(
                  label: '${scan.totalCalories.toStringAsFixed(0)} kcal',
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

class _DailyFatCard extends StatelessWidget {
  const _DailyFatCard({
    required this.consumedFat,
    required this.maxFat,
    required this.percent,
    required this.statusLabel,
    required this.statusColor,
    required this.latestScan,
    required this.onScanTap,
  });

  final int consumedFat;
  final int maxFat;
  final int percent;
  final String statusLabel;
  final Color statusColor;
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
            'Daily Fat Target',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF1C3028),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep it balanced today.',
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
                        _FatSummaryText(
                          consumedFat: consumedFat,
                          maxFat: maxFat,
                          statusLabel: statusLabel,
                          statusColor: statusColor,
                        ),
                        const SizedBox(height: 16),
                        Center(child: _ProgressRing(percent: percent)),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _FatSummaryText(
                            consumedFat: consumedFat,
                            maxFat: maxFat,
                            statusLabel: statusLabel,
                            statusColor: statusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ProgressRing(percent: percent),
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
                        ? 'Scan terakhir: ${latestScan!.foods.isNotEmpty ? latestScan!.foods.first.name : "—"} • ${latestScan!.status} • Fat: ${latestScan!.totalFat.toStringAsFixed(1)}g'
                        : 'Belum ada scan terakhir',
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
                'Consumed',
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

class _FatSummaryText extends StatelessWidget {
  const _FatSummaryText({
    required this.consumedFat,
    required this.maxFat,
    required this.statusLabel,
    required this.statusColor,
  });

  final int consumedFat;
  final int maxFat;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${consumedFat}g',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF2D7A4F),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '/ $maxFat g max',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFFC8E2D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9AB5A5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1C3028),
              fontWeight: FontWeight.w800,
            ),
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
