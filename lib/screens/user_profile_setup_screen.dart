import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/services/user_profile_service.dart';
import 'package:subefit/widgets/subefit_colors.dart';

class UserProfileSetupScreen extends StatefulWidget {
  const UserProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileSetupScreen> createState() => _UserProfileSetupScreenState();
}

class _UserProfileSetupScreenState extends State<UserProfileSetupScreen> {
  late final UserProfileService _profileService = UserProfileService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _selectedLevel = 'intermedio';
  bool _hasDumbbells = false;
  bool _hasResistanceBand = false;
  bool _hasBar = false;
  bool _hasKettlebell = false;
  List<String> _selectedInjuries = [];
  List<String> _selectedPreferences = [];

  final List<String> _injuries = ['Espalda', 'Rodilla', 'Hombro', 'Muñeca', 'Tobillo'];
  final List<String> _preferences = ['Cardio', 'Fuerza', 'Flexibilidad', 'Core', 'AMRAP'];

  void _saveProfile() {
    final profile = UserProfile(
      userId: _userId,
      level: _selectedLevel,
      hasDumbbells: _hasDumbbells,
      hasResistanceBand: _hasResistanceBand,
      hasBar: _hasBar,
      hasKettlebell: _hasKettlebell,
      injuries: _selectedInjuries,
      preferences: _selectedPreferences,
      createdAt: DateTime.now(),
    );

    _profileService.saveUserProfile(_userId, profile).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Mi Perfil'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nivel
            _buildSectionTitle('🎯 Tu Nivel de Entrenamiento'),
            const SizedBox(height: 12),
            _buildLevelSelector(),
            const SizedBox(height: 24),

            // Equipamiento
            _buildSectionTitle('🏋️ Equipamiento Disponible'),
            const SizedBox(height: 12),
            _buildEquipmentCheckboxes(),
            const SizedBox(height: 24),

            // Lesiones
            _buildSectionTitle('⚠️ Lesiones o Limitaciones'),
            const SizedBox(height: 12),
            _buildInjurySelection(),
            const SizedBox(height: 24),

            // Preferencias
            _buildSectionTitle('❤️ Preferencias de Entrenamiento'),
            const SizedBox(height: 12),
            _buildPreferenceSelection(),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SubefitColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Guardar Perfil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Row(
      children: ['principiante', 'intermedio', 'avanzado']
          .map((level) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(level.toUpperCase()),
                    selected: _selectedLevel == level,
                    onSelected: (selected) {
                      setState(() => _selectedLevel = level);
                    },
                    selectedColor: SubefitColors.primaryRed,
                    labelStyle: TextStyle(
                      color: _selectedLevel == level ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildEquipmentCheckboxes() {
    return Column(
      children: [
        _buildCheckboxTile('Mancuernas', _hasDumbbells, (val) {
          setState(() => _hasDumbbells = val ?? false);
        }),
        _buildCheckboxTile('Banda Elástica', _hasResistanceBand, (val) {
          setState(() => _hasResistanceBand = val ?? false);
        }),
        _buildCheckboxTile('Barra', _hasBar, (val) {
          setState(() => _hasBar = val ?? false);
        }),
        _buildCheckboxTile('Kettlebell', _hasKettlebell, (val) {
          setState(() => _hasKettlebell = val ?? false);
        }),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Siempre disponible: Peso corporal',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildInjurySelection() {
    return Wrap(
      spacing: 8,
      children: _injuries
          .map((injury) => FilterChip(
                label: Text(injury),
                selected: _selectedInjuries.contains(injury),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedInjuries.add(injury.toLowerCase());
                    } else {
                      _selectedInjuries.remove(injury.toLowerCase());
                    }
                  });
                },
                selectedColor: Colors.red.shade100,
                labelStyle: TextStyle(
                  color: _selectedInjuries.contains(injury.toLowerCase())
                      ? Colors.red.shade700
                      : Colors.black,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildPreferenceSelection() {
    return Wrap(
      spacing: 8,
      children: _preferences
          .map((pref) => FilterChip(
                label: Text(pref),
                selected: _selectedPreferences.contains(pref.toLowerCase()),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPreferences.add(pref.toLowerCase());
                    } else {
                      _selectedPreferences.remove(pref.toLowerCase());
                    }
                  });
                },
                selectedColor: SubefitColors.primaryRed.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: _selectedPreferences.contains(pref.toLowerCase())
                      ? SubefitColors.primaryRed
                      : Colors.black,
                ),
              ))
          .toList(),
    );
  }
}
