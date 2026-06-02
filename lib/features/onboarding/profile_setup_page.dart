import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/user_profile_model.dart';
import '../../data/services/hive_service.dart';

class ProfileSetupPage extends StatefulWidget {
  /// isEdit = true saat dipanggil dari Profile page untuk mengedit
  final bool isEdit;
  const ProfileSetupPage({super.key, this.isEdit = false});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int _step = 0;
  final int _totalSteps = 5;

  // ── Form fields ────────────────────────────────────────────────
  final _namaCtrl = TextEditingController();
  String _jenisKelamin = 'pria';
  int _usia = 22;
  double _beratBadan = 65.0;
  double _tinggiBadan = 165.0;
  ActivityLevel _levelAktivitas = ActivityLevel.sedang;

  // ── Colors ────────────────────────────────────────────────────
  static const _bg = Color(0xFFF5F8F2);
  static const _primary = Color(0xFF2D7A4F);
  static const _primaryLight = Color(0xFF48A970);
  static const _textPrimary = Color(0xFF1C3028);
  static const _textSecondary = Color(0xFF4D7060);
  static const _card = Color(0xFFFFFFFF);
  static const _border = Color(0xFFC8E2D0);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    // Jika mode edit, isi dari profil yang sudah ada
    if (widget.isEdit) {
      final profile = HiveService().getProfile();
      if (profile != null) {
        _namaCtrl.text = profile.nama;
        _jenisKelamin = profile.jenisKelamin;
        _usia = profile.usia;
        _beratBadan = profile.beratBadan;
        _tinggiBadan = profile.tinggiBadan;
        _levelAktivitas = profile.levelAktivitas;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _namaCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveProfile() async {
    final existing = HiveService().getProfile();
    final profile = UserProfile(
      id: existing?.id ?? const Uuid().v4(),
      nama: _namaCtrl.text.trim().isEmpty ? 'Pengguna' : _namaCtrl.text.trim(),
      jenisKelamin: _jenisKelamin,
      usia: _usia,
      beratBadan: _beratBadan,
      tinggiBadan: _tinggiBadan,
      levelAktivitas: _levelAktivitas,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await HiveService().saveProfile(profile);
    if (mounted) context.go('/home');
  }

  bool get _canProceed {
    if (_step == 0) return _namaCtrl.text.trim().isNotEmpty;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            _Header(
              step: _step,
              totalSteps: _totalSteps,
              isEdit: widget.isEdit,
              onBack: _step > 0 ? _prevStep : null,
            ),

            // ── Steps ──────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _StepNama(controller: _namaCtrl, onChanged: () => setState(() {})),
                  _StepGender(
                    selected: _jenisKelamin,
                    onChanged: (v) => setState(() => _jenisKelamin = v),
                  ),
                  _StepUsia(
                    value: _usia,
                    onChanged: (v) => setState(() => _usia = v),
                  ),
                  _StepFisik(
                    beratBadan: _beratBadan,
                    tinggiBadan: _tinggiBadan,
                    onBeratChanged: (v) => setState(() => _beratBadan = v),
                    onTinggiChanged: (v) => setState(() => _tinggiBadan = v),
                  ),
                  _StepAktivitas(
                    selected: _levelAktivitas,
                    onChanged: (v) => setState(() => _levelAktivitas = v),
                  ),
                ],
              ),
            ),

            // ── Preview target lemak ────────────────────────────
            if (_step == _totalSteps - 1)
              _FatTargetPreview(
                jenisKelamin: _jenisKelamin,
                usia: _usia,
                beratBadan: _beratBadan,
                tinggiBadan: _tinggiBadan,
                level: _levelAktivitas,
              ),

            // ── Bottom CTA ─────────────────────────────────────
            _BottomCta(
              step: _step,
              totalSteps: _totalSteps,
              canProceed: _canProceed,
              isEdit: widget.isEdit,
              onNext: _nextStep,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header dengan progress bar ────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.totalSteps,
    required this.isEdit,
    this.onBack,
  });

  final int step;
  final int totalSteps;
  final bool isEdit;
  final VoidCallback? onBack;

  static const _primary = Color(0xFF2D7A4F);
  static const _textPrimary = Color(0xFF1C3028);
  static const _textSecondary = Color(0xFF4D7060);

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / totalSteps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E2D0)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: _primary,
                    ),
                  ),
                )
              else
                const SizedBox(width: 38),
              const Spacer(),
              Text(
                'Langkah ${step + 1} dari $totalSteps',
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFD0EDE0),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Nama ──────────────────────────────────────────────────────────────

class _StepNama extends StatelessWidget {
  const _StepNama({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  static const _primary = Color(0xFF2D7A4F);
  static const _textPrimary = Color(0xFF1C3028);
  static const _textSecondary = Color(0xFF4D7060);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2D7A4F), Color(0xFF48C78A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.waving_hand_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 28),
          const Text(
            'Halo! Siapa namamu?',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Kami akan menyesuaikan target kesehatanmu secara personal.',
            style: TextStyle(color: _textSecondary, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Nama kamu',
              hintStyle: const TextStyle(
                color: Color(0xFF9AB5A5),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon:
                  const Icon(Icons.person_outline_rounded, color: _primary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFC8E2D0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFC8E2D0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Jenis Kelamin ─────────────────────────────────────────────────────

class _StepGender extends StatelessWidget {
  const _StepGender({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jenis Kelamin',
            style: TextStyle(
              color: Color(0xFF1C3028),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ini mempengaruhi perhitungan BMR yang akurat.',
            style: TextStyle(
                color: Color(0xFF4D7060), fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              _GenderCard(
                label: 'Pria',
                icon: Icons.male_rounded,
                value: 'pria',
                selected: selected,
                onTap: () => onChanged('pria'),
              ),
              const SizedBox(width: 16),
              _GenderCard(
                label: 'Wanita',
                icon: Icons.female_rounded,
                value: 'wanita',
                selected: selected,
                onTap: () => onChanged('wanita'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2D7A4F);

  @override
  Widget build(BuildContext context) {
    final isActive = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 160,
          decoration: BoxDecoration(
            color: isActive ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive ? _primary : const Color(0xFFC8E2D0),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 56,
                color: isActive ? Colors.white : const Color(0xFF9AB5A5),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF1C3028),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 3: Usia ──────────────────────────────────────────────────────────────

class _StepUsia extends StatelessWidget {
  const _StepUsia({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  static const _primary = Color(0xFF2D7A4F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Berapa umurmu?',
            style: TextStyle(
              color: Color(0xFF1C3028),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Usia menentukan kebutuhan metabolisme basal.',
            style: TextStyle(color: Color(0xFF4D7060), fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 60),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CircleButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (value > 10) onChanged(value - 1);
                  },
                ),
                const SizedBox(width: 28),
                Column(
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'tahun',
                      style: TextStyle(
                        color: Color(0xFF4D7060),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 28),
                _CircleButton(
                  icon: Icons.add,
                  onTap: () {
                    if (value < 100) onChanged(value + 1);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Slider(
            value: value.toDouble(),
            min: 10,
            max: 100,
            divisions: 90,
            activeColor: _primary,
            inactiveColor: const Color(0xFFD0EDE0),
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2D7A4F);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEBF4E8),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC8E2D0)),
        ),
        child: Icon(icon, color: _primary, size: 24),
      ),
    );
  }
}

// ── Step 4: Berat & Tinggi ────────────────────────────────────────────────────

class _StepFisik extends StatelessWidget {
  const _StepFisik({
    required this.beratBadan,
    required this.tinggiBadan,
    required this.onBeratChanged,
    required this.onTinggiChanged,
  });

  final double beratBadan;
  final double tinggiBadan;
  final ValueChanged<double> onBeratChanged;
  final ValueChanged<double> onTinggiChanged;

  static const _primary = Color(0xFF2D7A4F);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Tubuhmu',
            style: TextStyle(
              color: Color(0xFF1C3028),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Berat dan tinggi badan digunakan untuk kalkulasi BMR.',
            style: TextStyle(color: Color(0xFF4D7060), fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Berat Badan
          _SliderSection(
            label: 'Berat Badan',
            unit: 'kg',
            value: beratBadan,
            min: 30,
            max: 200,
            onChanged: onBeratChanged,
          ),
          const SizedBox(height: 28),

          // Tinggi Badan
          _SliderSection(
            label: 'Tinggi Badan',
            unit: 'cm',
            value: tinggiBadan,
            min: 100,
            max: 250,
            onChanged: onTinggiChanged,
          ),
        ],
      ),
    );
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  static const _primary = Color(0xFF2D7A4F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E2D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x102D7A4F),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4D7060),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        color: Color(0xFF4D7060),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).round(),
            activeColor: _primary,
            inactiveColor: const Color(0xFFD0EDE0),
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${min.toInt()} $unit',
                style: const TextStyle(
                    color: Color(0xFF9AB5A5), fontSize: 12),
              ),
              Text(
                '${max.toInt()} $unit',
                style: const TextStyle(
                    color: Color(0xFF9AB5A5), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 5: Level Aktivitas ───────────────────────────────────────────────────

class _StepAktivitas extends StatelessWidget {
  const _StepAktivitas({required this.selected, required this.onChanged});
  final ActivityLevel selected;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Level Aktivitasmu',
            style: TextStyle(
              color: Color(0xFF1C3028),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Seberapa aktif kamu secara fisik setiap minggu?',
            style: TextStyle(color: Color(0xFF4D7060), fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
          ...ActivityLevel.values.map((level) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ActivityCard(
              level: level,
              selected: selected,
              onTap: () => onChanged(level),
            ),
          )),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });
  final ActivityLevel level;
  final ActivityLevel selected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2D7A4F);

  IconData get _icon {
    switch (level) {
      case ActivityLevel.sangatRingan:
        return Icons.airline_seat_recline_extra_rounded;
      case ActivityLevel.ringan:
        return Icons.directions_walk_rounded;
      case ActivityLevel.sedang:
        return Icons.directions_bike_rounded;
      case ActivityLevel.aktif:
        return Icons.fitness_center_rounded;
      case ActivityLevel.sangatAktif:
        return Icons.sports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = selected == level;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? _primary : const Color(0xFFC8E2D0),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFEBF4E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon,
                color: isActive ? Colors.white : _primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF1C3028),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.description,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white.withOpacity(0.8)
                          : const Color(0xFF9AB5A5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Preview Target Lemak (step terakhir) ──────────────────────────────────────

class _FatTargetPreview extends StatelessWidget {
  const _FatTargetPreview({
    required this.jenisKelamin,
    required this.usia,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.level,
  });

  final String jenisKelamin;
  final int usia;
  final double beratBadan;
  final double tinggiBadan;
  final ActivityLevel level;

  double get bmr {
    final base = (10 * beratBadan) + (6.25 * tinggiBadan) - (5 * usia);
    return jenisKelamin == 'pria' ? base + 5 : base - 161;
  }

  double get tdee => bmr * level.factor;
  double get targetLemak => (tdee * 0.25) / 9;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D7A4F), Color(0xFF48A970)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D7A4F).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Target Lemak Harianmu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${targetLemak.toStringAsFixed(1)} g / hari',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tdee.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'TDEE',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom CTA ────────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.step,
    required this.totalSteps,
    required this.canProceed,
    required this.isEdit,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final bool canProceed;
  final bool isEdit;
  final VoidCallback onNext;

  static const _primary = Color(0xFF2D7A4F);
  static const _primaryLight = Color(0xFF48A970);

  String get _buttonLabel {
    if (step == totalSteps - 1) {
      return isEdit ? 'Simpan Perubahan' : 'Mulai Perjalananku! 🚀';
    }
    return 'Lanjut';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: canProceed
                ? const LinearGradient(
                    colors: [_primary, _primaryLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFC8E2D0), Color(0xFFC8E2D0)],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canProceed
                ? [
                    BoxShadow(
                      color: _primary.withOpacity(0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: canProceed ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFF9AB5A5),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(_buttonLabel),
          ),
        ),
      ),
    );
  }
}
