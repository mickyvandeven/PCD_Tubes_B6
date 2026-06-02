import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/scan_result_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/services/hive_service.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../widgets/fat_bottom_nav.dart';
import '../../history/history_page.dart';
import '../../profile/profile_page.dart';
import '../../scanner/scanner_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  double _fatPercentage(double consumed, double max) =>
      max > 0 ? (consumed / max) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final hive = HiveService();
    final UserProfile? profile = hive.getProfile();
    final String userName = profile?.nama ?? 'Pengguna';
    final double maxFat = profile?.targetLemakHarian ?? 65.0;
    final double consumedFat = hive.getTodayTotalFat();
    final int todayScanCount = hive.getTodayScanCount();
    final double avgFat = hive.getAverageFat();
    final int percent = _fatPercentage(consumedFat, maxFat).round().clamp(0, 100);

    // Gunakan scan hari ini jika ada, fallback ke dummy
    final todayScans = hive.getTodayScans();
    final nutritionSvc = NutritionService();
    final latestScan = todayScans.isNotEmpty
        ? todayScans.first
        : ScanResultModel(
            id: 'scan-demo',
            tanggal: DateTime.now(),
            imagePath: 'assets/images/salad.jpg',
            foods: [nutritionSvc.createFoodItem('Salad', confidence: 0.95)],
            status: 'Low Fat',
          );

    final recentScans = <_RecentScanItem>[
      const _RecentScanItem(
        name: 'Salad Sayur',
        time: '10 min ago',
        fatTag: 'Fat: 3g',
        calories: '120 kcal',
        accentColor: Color(0xFF24E2A8),
        icon: Icons.eco,
      ),
      const _RecentScanItem(
        name: 'Nasi Goreng',
        time: '2 hrs ago',
        fatTag: 'Fat: 12g',
        calories: '450 kcal',
        accentColor: Color(0xFFFFC94D),
        icon: Icons.rice_bowl,
      ),
      const _RecentScanItem(
        name: 'Beef Burger',
        time: 'Yesterday',
        fatTag: 'Fat: 32g',
        calories: '850 kcal',
        accentColor: Color(0xFFFF5C6B),
        icon: Icons.lunch_dining,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F2),
      bottomNavigationBar: FatBottomNav(
        currentIndex: 0,
        onScanTap: () => context.push('/scanner'),
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
                _TopBar(userName: userName),
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
                        consumedFat: consumedFat,
                        maxFat: maxFat,
                        percent: percent,
                        latestScan: latestScan,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _QuickStatCard(
                            icon: Icons.restaurant_menu,
                            iconColor: const Color(0xFF2D7A4F),
                            title: 'Scanned Today',
                            value: '$todayScanCount items',
                          ),
                          const SizedBox(height: 12),
                          _QuickStatCard(
                            icon: Icons.water_drop_outlined,
                            iconColor: const Color(0xFFB8D34B),
                            title: 'Avg Fat',
                            value: '${avgFat.toStringAsFixed(1)}g',
                          ),
                          const SizedBox(height: 12),
                          _QuickStatCard(
                            icon: Icons.track_changes_rounded,
                            iconColor: const Color(0xFFFFC947),
                            title: 'Target',
                            value: '${maxFat.toStringAsFixed(0)}g',
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
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2D7A4F),
                      ),
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentScans.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _RecentScanCard(item: recentScans[index]);
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
    required this.latestScan,
  });

  final double consumedFat;
  final double maxFat;
  final int percent;
  final ScanResultModel latestScan;

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
                          statusColor: const Color(0xFF2D7A4F),
                        ),
                        const SizedBox(height: 16),
                        const Center(child: _ProgressRing(percent: 48)),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _FatSummaryText(
                            consumedFat: consumedFat,
                            maxFat: maxFat,
                            statusColor: const Color(0xFF2D7A4F),
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
                    'Scan terakhir: ${latestScan.imagePath.split('/').last} • ${latestScan.status} • Fat: ${latestScan.totalFat.toStringAsFixed(1)}g',
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
              onPressed: () => context.push('/scanner'),
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
    required this.statusColor,
  });

  final double consumedFat;
  final double maxFat;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${consumedFat.toStringAsFixed(1)}g',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF2D7A4F),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '/ ${maxFat.toStringAsFixed(0)} g target',
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
              'On Track',
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
