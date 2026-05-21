import 'package:flutter/material.dart';

import '../../data/models/scan_result_model.dart';
import '../../widgets/fat_bottom_nav.dart';
import '../history/history_page.dart';
import '../scanner/scanner_page.dart';
import '../profile/profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.userName = 'Ridho'});

  final String userName;

  double _fatPercentage(int consumed, int max) => (consumed / max) * 100;

  @override
  Widget build(BuildContext context) {
    final latestScan = ScanResultModel(
      id: 'scan-001',
      tanggal: DateTime(2026, 5, 21),
      imagePath: 'assets/images/salad.jpg',
      fatPercentage: 3,
      status: 'Low fat',
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

    final consumedFat = 24;
    const maxFat = 50;
    final percent = _fatPercentage(consumedFat, maxFat).round();

    return Scaffold(
      backgroundColor: const Color(0xFF11162A),
      bottomNavigationBar: FatBottomNav(
        currentIndex: 0,
        onScanTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ScannerPage()));
        },
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF151A30), Color(0xFF0F1322), Color(0xFF0D1020)],
          ),
        ),
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
                    color: Colors.white54,
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
                        children: const [
                          _QuickStatCard(
                            icon: Icons.restaurant_menu,
                            iconColor: Color(0xFF35EFC4),
                            title: 'Scanned Today',
                            value: '4 items',
                          ),
                          SizedBox(height: 12),
                          _QuickStatCard(
                            icon: Icons.water_drop_outlined,
                            iconColor: Color(0xFFB8D34B),
                            title: 'Avg Fat',
                            value: '8g /meal',
                          ),
                          SizedBox(height: 12),
                          _QuickStatCard(
                            icon: Icons.local_fire_department_outlined,
                            iconColor: Color(0xFFFFC947),
                            title: 'Streak',
                            value: '5 hari',
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
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4FE9C9),
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
          backgroundColor: const Color(0xFF26314F),
          child: ClipOval(
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF54F2D1), Color(0xFF2D79FF)],
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
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF1F2640),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white70,
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

  final int consumedFat;
  final int maxFat;
  final int percent;
  final ScanResultModel latestScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2038), Color(0xFF202B41), Color(0xFF11162A)],
        ),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
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
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep it balanced today.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
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
                          statusColor: const Color(0xFF35EFC4),
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
                            statusColor: const Color(0xFF35EFC4),
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
              color: const Color(0xFF141A2D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF57F2CE),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scan terakhir: ${latestScan.imagePath.split('/').last} • ${latestScan.status}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
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
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ScannerPage()));
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan Sekarang'),
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
              backgroundColor: const Color(0xFF2A324F),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF43F2D1),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Consumed',
                style: TextStyle(
                  color: Colors.white54,
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

  final int consumedFat;
  final int maxFat;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${consumedFat}g',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF44F0D2),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '/ $maxFat g max',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white54,
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
        color: const Color(0xFF1B2139),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
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
        ? const Color(0xFF2D1B27)
        : item.accentColor == const Color(0xFFFFC94D)
        ? const Color(0xFF2C2816)
        : const Color(0xFF152A25);

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F37),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
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
                    item.accentColor.withOpacity(0.95),
                    const Color(0xFF10162A),
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
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  item.time,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                  background: const Color(0xFF26304B),
                  textColor: Colors.white70,
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
        color: const Color(0xFF1A2038),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF24314D),
              border: Border.all(
                color: const Color(0xFF4FE9C9).withOpacity(0.25),
              ),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: Color(0xFF58EAC8),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mengurangi makanan yang digoreng dan menggantinya dengan rebusan dapat memotong asupan lemak harian hingga 40%. Coba menu rebus untuk makan malam!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
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
