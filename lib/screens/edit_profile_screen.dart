import 'package:flutter/material.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/subefit_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({Key? key, required this.userProfile})
      : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.nombre);
    _bioController = TextEditingController(text: widget.userProfile.biografia);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      try {
        final Map<String, dynamic> dataToUpdate = {
          'nombre': _nameController.text,
          'nombre_lowercase': _nameController.text.toLowerCase(),
          'biografia': _bioController.text,
        };

        await _firebaseService.updateUserProfile(userId, dataToUpdate);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('¡Perfil actualizado con éxito!'),
              backgroundColor: Colors.green),
        );

        // Regresamos a la pantalla anterior, indicando que hubo cambios.
        Navigator.of(context).pop(true);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ))
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.isEmpty
                    ? 'El nombre no puede estar vacío'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Biografía'),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
