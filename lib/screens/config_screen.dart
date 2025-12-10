import 'package:flutter/material.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:subefit/screens/tts_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar Firebase Auth
import 'firebase_auth_service.dart'; // Importar el servicio de autenticación
import 'firebase_service.dart'; // Importar el servicio de Firestore
import 'user_profile_model.dart'; // Importar el modelo de perfil

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({Key? key}) : super(key: key);

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();
  late ({
    TextEditingController weight,
    TextEditingController height,
    TextEditingController goals
  }) _profileControllers;

  // Variables para los ajustes de la app
  String _selectedLanguage = 'es'; // Valor por defecto
  String _selectedVoice = 'Femenino'; // Valor por defecto
  bool _notificationsEnabled = true;

  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _profileControllers = (
      weight: TextEditingController(),
      height: TextEditingController(),
      goals: TextEditingController(),
    );
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    try {
      final profile = await _firebaseService.getUserProfile(user!.uid);
      if (profile != null && mounted) {
        setState(() {
          _userProfile = profile;
          // SOLUCIÓN: Aseguramos que los valores no sean nulos.
          // Usamos `?? ''` para `goals` para proveer un string vacío si es nulo.
          _profileControllers.weight.text = profile.weight?.toString() ?? '0.0';
          _profileControllers.height.text = profile.height?.toString() ?? '0.0';
          _profileControllers.goals.text = profile.goals ?? '';

          // Cargar ajustes (si existen en Firestore, si no, usar defaults)
          // Nota: El modelo de datos en Firestore debería tener un mapa 'settings'.
          // Por ahora, lo manejamos así. En el futuro, se puede añadir al UserProfileModel.
          // _selectedLanguage = profile.settings['language'] ?? 'es';
          // _selectedVoice = profile.settings['voiceGender'] ?? 'Femenino';
          // _notificationsEnabled = profile.settings['notifications'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cargar el perfil: $e'),
              backgroundColor: SubefitColors.dangerRed),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final Map<String, dynamic> dataToUpdate = {
        'weight': double.tryParse(_profileControllers.weight.text) ?? 0.0,
        'height': double.tryParse(_profileControllers.height.text) ?? 0.0,
        'goals': _profileControllers.goals.text,
        'isProfileComplete': true, // Marcar perfil como completo
        'settings': {
          'language': _selectedLanguage,
          'voiceGender': _selectedVoice,
          'notifications': _notificationsEnabled,
        }
      };

      await _firebaseService.updateUserProfile(user.uid, dataToUpdate);

      // 3.1. Actualizar el servicio de TTS si la voz cambió
      final ttsService = TtsService();
      final newVoiceGender = TtsVoiceGender.values.firstWhere(
          (e) => e.toString().split('.').last == _selectedVoice,
          orElse: () => TtsVoiceGender.Femenino);
      ttsService.setVoice(user.uid, newVoiceGender);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Perfil actualizado con éxito'),
            backgroundColor: Colors.green),
      );

      if (mounted) {
        // Navegamos a la pantalla principal, limpiando el historial para que no pueda volver.
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: SubefitColors.dangerRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetProgress() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Restablecer Progreso?'),
        content: const Text(
            'Esta acción es irreversible. Se borrarán tus puntos, racha e historial de entrenamientos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restablecer',
                style: TextStyle(color: SubefitColors.dangerRed)),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firebaseService.resetUserProgress(user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tu progreso ha sido restablecido.'),
              backgroundColor: Colors.orange),
        );
        if (mounted)
          Navigator.of(context)
              .pop(true); // Vuelve al perfil y notifica cambios
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  void dispose() {
    _profileControllers.weight.dispose();
    _profileControllers.height.dispose();
    _profileControllers.goals.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuración y Perfil'),
          bottom: const TabBar(
            indicatorColor: SubefitColors.primaryRed,
            labelColor: SubefitColors.primaryRed,
            tabs: [
              Tab(icon: Icon(Icons.account_circle_outlined), text: 'Perfil'),
              Tab(icon: Icon(Icons.tune_outlined), text: 'Ajustes'),
              Tab(icon: Icon(Icons.security_outlined), text: 'Cuenta'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildProfileFormPage(),
                  _buildAppSettingsPage(),
                  _buildAccountPage(),
                ],
              ),
        bottomNavigationBar: _isLoading ? null : _buildBottomControls(),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveUserData,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Guardar Cambios'),
        ),
      ),
    );
  }

  Widget _buildProfileFormPage() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        children: [
          TextFormField(
            controller: _profileControllers.weight,
            decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                prefixIcon: Icon(Icons.monitor_weight_outlined)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Introduce tu peso.';
              if (double.tryParse(value) == null)
                return 'Introduce un número válido.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _profileControllers.height,
            decoration: const InputDecoration(
                labelText: 'Altura (cm)',
                prefixIcon: Icon(Icons.height_outlined)),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Introduce tu altura.';
              if (double.tryParse(value) == null)
                return 'Introduce un número válido.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _profileControllers.goals,
            decoration: const InputDecoration(
                labelText: 'Mis Objetivos',
                hintText: 'Ej: Perder peso, ganar fuerza...',
                prefixIcon: Icon(Icons.flag_outlined)),
            maxLines: 3,
            minLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsPage() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        DropdownButtonFormField<String>(
          value: _selectedLanguage,
          decoration: const InputDecoration(labelText: 'Idioma'),
          items: const [
            DropdownMenuItem(value: 'es', child: Text('Español')),
            DropdownMenuItem(value: 'en', child: Text('Inglés')),
          ],
          onChanged: (value) => setState(() => _selectedLanguage = value!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedVoice,
          decoration: const InputDecoration(labelText: 'Tipo de Voz (TTS)'),
          items: const [
            DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
            DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
            DropdownMenuItem(value: 'Neutro', child: Text('Neutro')),
          ],
          onChanged: (value) => setState(() => _selectedVoice = value!),
        ),
        SwitchListTile(
          title: const Text('Notificaciones'),
          value: _notificationsEnabled,
          onChanged: (value) => setState(() => _notificationsEnabled =
              value), // La lógica de tema oscuro se ha eliminado por simplicidad
          secondary: const Icon(Icons.notifications_active_outlined),
        ),
      ],
    );
  }

  Widget _buildAccountPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _resetProgress,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Restablecer Progreso'),
            style: ElevatedButton.styleFrom(
                backgroundColor: SubefitColors.dangerRed,
                foregroundColor: Colors.white),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'), // El color se hereda del tema
          ),
        ],
      ),
    );
  }
}
