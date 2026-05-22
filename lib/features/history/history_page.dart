import 'package:flutter/material.dart';

import '../../core/router/no_transition_route.dart';

import '../../widgets/fat_bottom_nav.dart';
import '../home/view/home_page.dart';
import '../scanner/scanner_page.dart';
import '../profile/profile_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final weeklyValues = <double>[12, 14, 13, 20, 8, 35, 22];
    final foodLogs = <_FoodLogItem>[
      const _FoodLogItem(
        name: 'Oatmeal',
        time: '08:00 WIB',
        fatGram: 3,
        accentColor: Color(0xFF29F2C8),
        icon: Icons.breakfast_dining,
      ),
      const _FoodLogItem(
        name: 'Nasi Padang',
        time: '13:30 WIB',
        fatGram: 15,
        accentColor: Color(0xFFFF5D6C),
        icon: Icons.ramen_dining,
      ),
      const _FoodLogItem(
        name: 'Ayam Goreng',
        time: '19:00 WIB',
        fatGram: 6,
        accentColor: Color(0xFFFFC34D),
        icon: Icons.restaurant,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F2),
      bottomNavigationBar: FatBottomNav(
        currentIndex: 1,
        onScanTap: () {
          Navigator.of(
            context,
          ).push(NoTransitionRoute(builder: (_) => const ScannerPage()));
        },
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              NoTransitionRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              NoTransitionRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
      ),
      body: Container(
        color: const Color(0xFFF5F8F2),
        child: SafeArea(
          child: SingleChildScrollView(
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
                    _FilterChip(
                      label: 'Hari ini',
                      icon: Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SummaryCard(weeklyAverage: 32, chartValues: weeklyValues),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Hari Ini',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1C3028),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _PillInfo(text: '24g total'),
                  ],
                ),
                const SizedBox(height: 12),
                ...foodLogs.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FoodLogCard(item: item),
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
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF4D7060),
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
    const maxValue = 50.0;

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

class _FoodLogItem {
  const _FoodLogItem({
    required this.name,
    required this.time,
    required this.fatGram,
    required this.accentColor,
    required this.icon,
  });
  final String name;
  final String time;
  final int fatGram;
  final Color accentColor;
  final IconData icon;
}

class _FoodLogCard extends StatelessWidget {
  const _FoodLogCard({required this.item});
  final _FoodLogItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E2D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142D7A4F),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  item.accentColor.withOpacity(0.95),
                  item.accentColor.withOpacity(0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(item.icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF1C3028),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: Color(0xFF4D7060),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.fatGram}g',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1C3028),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Lemak',
                style: TextStyle(
                  color: Color(0xFF4D7060),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            width: 6,
            height: 34,
            decoration: BoxDecoration(
              color: item.accentColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}
