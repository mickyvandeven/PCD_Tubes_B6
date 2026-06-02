import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_profile_model.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/mongo_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  String _selectedGender = 'pria';
  ActivityLevel _selectedActivity = ActivityLevel.sedang;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = HiveService().getProfile();

    _nameController = TextEditingController(text: profile?.nama ?? '');
    _ageController = TextEditingController(text: profile?.usia.toString() ?? '');
    _weightController = TextEditingController(text: profile?.beratBadan.toString() ?? '');
    _heightController = TextEditingController(text: profile?.tinggiBadan.toString() ?? '');

    _selectedGender = profile?.jenisKelamin ?? 'pria';
    _selectedActivity = profile?.levelAktivitas ?? ActivityLevel.sedang;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final hive = HiveService();
      final currentProfile = hive.getProfile();
      if (currentProfile == null) throw Exception("Profil tidak ditemukan");

      // Parse data
      final usia = int.parse(_ageController.text.trim());
      final berat = double.parse(_weightController.text.trim());
      final tinggi = double.parse(_heightController.text.trim());

      // Update nilai
      currentProfile.nama = _nameController.text.trim();
      currentProfile.usia = usia;
      currentProfile.beratBadan = berat;
      currentProfile.tinggiBadan = tinggi;
      currentProfile.jenisKelamin = _selectedGender;
      currentProfile.levelAktivitas = _selectedActivity;
      currentProfile.updatedAt = DateTime.now();

      // Simpan lokal
      await currentProfile.save();

      // Simpan ke cloud
      await MongoService().syncUserProfile(currentProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Color(0xFF2D7A4F)),
        );
        context.pop(); // Kembali ke halaman profil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF4D7060)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD5EAD9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD5EAD9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2D7A4F), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return '$label tidak boleh kosong';
          if (isNumber && double.tryParse(value) == null) return '$label harus berupa angka valid';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F2),
      appBar: AppBar(
        title: const Text('Edit Profil', style: TextStyle(color: Color(0xFF1C3028), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1C3028)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Nama Panggilan', _nameController),
                _buildTextField('Usia (Tahun)', _ageController, isNumber: true),
                
                // Jenis Kelamin
                const Text('Jenis Kelamin', style: TextStyle(color: Color(0xFF4D7060), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _GenderSelector(
                        label: 'Pria',
                        icon: Icons.male_rounded,
                        isSelected: _selectedGender == 'pria',
                        onTap: () => setState(() => _selectedGender = 'pria'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderSelector(
                        label: 'Wanita',
                        icon: Icons.female_rounded,
                        isSelected: _selectedGender == 'wanita',
                        onTap: () => setState(() => _selectedGender = 'wanita'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildTextField('Berat (kg)', _weightController, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Tinggi (cm)', _heightController, isNumber: true)),
                  ],
                ),

                const Text('Tingkat Aktivitas Harian', style: TextStyle(color: Color(0xFF4D7060), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD5EAD9)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ActivityLevel>(
                      value: _selectedActivity,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4D7060)),
                      items: ActivityLevel.values.map((lvl) {
                        return DropdownMenuItem(
                          value: lvl,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(lvl.label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1C3028))),
                              Text(lvl.description, style: const TextStyle(fontSize: 11, color: Color(0xFF9AB5A5))),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedActivity = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A4F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

class _GenderSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderSelector({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D7A4F) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF2D7A4F) : const Color(0xFFD5EAD9)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF4D7060), size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF4D7060), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
