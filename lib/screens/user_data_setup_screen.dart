import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'firebase_service.dart'; // Cambiado de local_data_service a firebase_service

class UserDataSetupScreen extends StatefulWidget {
  const UserDataSetupScreen({Key? key}) : super(key: key);

  @override
  _UserDataSetupScreenState createState() => _UserDataSetupScreenState();
}

class _UserDataSetupScreenState extends State<UserDataSetupScreen> {
  final FirebaseService _firebaseService =
      FirebaseService(); // Instancia del servicio de Firebase
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  double _weight = 70;
  double _height = 175;
  String? _selectedGoal;
  bool _isLoading = false;

  final List<String> _goals = [
    'Quemar Grasa',
    'Ganar Fuerza',
    'Resistencia',
    'Flexibilidad',
    'Mejorar condición física'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecciona un objetivo principal.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Si no hay usuario, no debería estar en esta pantalla. Lo mandamos al inicio.
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      return;
    }

    try {
      // Actualizar el nombre en el perfil de Firebase Auth
      await user.updateDisplayName(_nameController.text.trim());

      // Guardar los datos en el almacenamiento local
      // *** CORRECCIÓN: Guardar los datos en Firestore en lugar de localmente ***
      await _firebaseService.updateUserProfile(user.uid, {
        'nombre': _nameController.text.trim(),
        'nombre_lowercase': _nameController.text.trim().toLowerCase(),
        'weight': _weight,
        'height': _height,
        'goals': _selectedGoal,
        'isProfileComplete':
            true, // ¡Marcamos el perfil como completo en Firestore!
      });

      // Navegar a la pantalla principal, eliminando el historial de navegación anterior
      // El AuthGate se encargará de redirigir a MainFlowScreen
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el perfil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu Perfil'),
        automaticallyImplyLeading: false, // Oculta el botón de regreso
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('¿Cómo te llamas?'),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Nombre de Usuario'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Tu Objetivo Principal'),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _goals.map((goal) {
                final isSelected = _selectedGoal == goal;
                return ChoiceChip(
                  label: Text(goal),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedGoal = goal),
                  selectedColor: SubefitColors.primaryRed,
                  backgroundColor: SubefitColors.darkGrey,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Tu Peso (kg)'),
            _buildSlider(
              value: _weight,
              min: 40,
              max: 150,
              label: '${_weight.toInt()} kg',
              onChanged: (value) => setState(() => _weight = value),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Tu Altura (cm)'),
            _buildSlider(
              value: _height,
              min: 140,
              max: 220,
              label: '${_height.toInt()} cm',
              onChanged: (value) => setState(() => _height = value),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SubefitColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Guardar y Empezar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(title,
            style: const TextStyle(
                color: SubefitColors.primaryRed,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      );

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: label,
          activeColor: SubefitColors.primaryRed,
          inactiveColor: Colors.grey.shade700,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
