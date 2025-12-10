import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subefit/screens/local_data_service.dart';
import 'package:subefit/screens/local_auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserDataScreen extends StatefulWidget {
  const UserDataScreen({Key? key}) : super(key: key);

  @override
  _UserDataScreenState createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  final _restrictionsController = TextEditingController();

  String? _selectedGender;
  int _age = 25;
  double _weight = 70;
  double _height = 175;
  String? _experienceLevel;
  double _trainingDays = 3;
  TimeOfDay? _trainingTime;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  bool isSaving = false;

  Future<void> saveUserData() async {
    if (!_formKey.currentState!.validate() ||
        _experienceLevel == null ||
        _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.')));
      return;
    }

    setState(() => isSaving = true);

    final authService = Provider.of<LocalAuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      setState(() => isSaving = false);
      return; // Should not happen
    }

    // 1. Usar LocalDataService para guardar los datos del usuario
    final dataService = LocalDataService();
    final userData = await dataService.loadUserData(user.id);

    // Actualizar los campos del perfil
    userData['gender'] = _selectedGender;
    userData['age'] = _age;
    userData['weight'] = _weight;
    userData['height'] = _height;
    userData['experienceLevel'] = _experienceLevel;
    userData['goals'] = _goalController.text.trim();
    userData['trainingDays'] = _trainingDays.toInt();
    userData['restrictions'] = _restrictionsController.text.trim();

    if (_trainingTime != null) {
      userData['trainingTime'] =
          '${_trainingTime!.hour}:${_trainingTime!.minute}';
    }

    // Guardar todos los datos actualizados
    await dataService.saveUserData(user.id, userData);

    // TODO: Considerar si esta pantalla debe marcar un "onboarding completado"

    if (mounted) {
      setState(() => isSaving = false);
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _goalController.dispose();
    _restrictionsController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      // Estilo unificado para los campos de texto
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Como Firebase ya no se usa, esta pantalla pierde su propósito principal
    // de recolección de datos post-registro. Se mantiene la UI pero la funcionalidad
    // de guardado está desactivada.

    return Scaffold(
        appBar: AppBar(
          title: const Text('Cuéntanos sobre ti'),
          backgroundColor: SubefitColors.darkGrey,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Identidad'),
              Tab(text: 'Físico'),
              Tab(text: 'Metas'),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIdentityTab(),
                    _buildPhysicalInfoTab(),
                    _buildGoalsTab(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50)),
                  onPressed: isSaving ? null : saveUserData,
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Guardar y Empezar',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildIdentityTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Selecciona tu sexo',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _GenderSelector(
              icon: Icons.male,
              label: 'Masculino',
              isSelected: _selectedGender == 'Male',
              onTap: () => setState(() => _selectedGender = 'Male')),
          _GenderSelector(
              icon: Icons.female,
              label: 'Femenino',
              isSelected: _selectedGender == 'Female',
              onTap: () => setState(() => _selectedGender = 'Female')),
        ],
      ),
      const SizedBox(height: 32),
      const Text('¿Cuál es tu edad?',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      _buildSlider(
        label: 'Edad',
        value: _age.toDouble(),
        min: 10,
        max: 100,
        divisions: 90,
        unit: ' años',
        onChanged: (val) => setState(() => _age = val.toInt()),
      ),
    ]);
  }

  Widget _buildPhysicalInfoTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _buildSlider(
          label: 'Peso',
          value: _weight,
          min: 30,
          max: 200,
          divisions: 170,
          unit: 'kg',
          onChanged: (val) => setState(() => _weight = val)),
      const SizedBox(height: 24),
      _buildSlider(
          label: 'Altura',
          value: _height,
          min: 120,
          max: 220,
          divisions: 100,
          unit: 'cm',
          onChanged: (val) => setState(() => _height = val)),
      const SizedBox(height: 24),
      DropdownButtonFormField<String>(
        decoration: _inputDecoration('Nivel de experiencia'),
        value: _experienceLevel,
        dropdownColor: SubefitColors.darkGrey,
        items: ['Principiante', 'Intermedio', 'Avanzado']
            .map((label) => DropdownMenuItem(child: Text(label), value: label))
            .toList(),
        onChanged: (value) => setState(() => _experienceLevel = value),
        validator: (v) => v == null ? 'Selecciona tu nivel' : null,
      ),
    ]);
  }

  Widget _buildGoalsTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextFormField(
          controller: _goalController,
          decoration: _inputDecoration(
              'Objetivo principal (ej: Perder peso, ganar fuerza)'),
          validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
      const SizedBox(height: 16),
      _buildSlider(
          label: 'Días de entreno por semana',
          value: _trainingDays,
          min: 1,
          max: 7,
          divisions: 6,
          unit: ' días',
          onChanged: (val) => setState(() => _trainingDays = val)),
      const SizedBox(height: 16),
      TextFormField(
          controller: _restrictionsController,
          decoration:
              _inputDecoration('Restricciones médicas o lesiones (opcional)')),
      const SizedBox(height: 24),
      ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.primary)),
        title: const Text('Horario preferido para entrenar'),
        subtitle:
            Text(_trainingTime?.format(context) ?? 'Toca para seleccionar'),
        trailing:
            Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
        onTap: () async {
          final time = await showTimePicker(
              context: context, initialTime: TimeOfDay.now());
          if (time != null) setState(() => _trainingTime = time);
        },
      ),
    ]);
  }

  Widget _buildSlider(
      {required String label,
      required double value,
      required double min,
      required double max,
      required int divisions,
      required String unit,
      required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(0)}$unit',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(0),
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderSelector(
      {required this.icon,
      required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                    size: 60,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white)
                .animate(target: isSelected ? 1 : 0)
                .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut),
            Text(label,
                style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
