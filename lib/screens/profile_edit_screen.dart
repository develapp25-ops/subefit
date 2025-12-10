import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'image_optimization_service.dart';
import 'local_data_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final String? initialAvatarUrl;
  final String? initialUsername;
  final String? initialBio;

  const ProfileEditScreen({
    Key? key,
    this.initialAvatarUrl,
    this.initialUsername,
    this.initialBio,
  }) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  File? _selectedImage;
  String? _currentAvatarUrl;
  bool _isLoading = false;
  String? _uploadProgress;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername ?? '');
    _bioController = TextEditingController(text: widget.initialBio ?? '');
    _currentAvatarUrl = widget.initialAvatarUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showError('Error al acceder a la cámara: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showError('Error al acceder a la galería: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _errorMessage = null;
    });
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) {
      _showError('Por favor selecciona una imagen');
      return;
    }

    // Validar formato
    if (!ImageOptimizationService.isValidImageFormat(_selectedImage!)) {
      _showError('Formato no soportado. Usa JPG o PNG.');
      return;
    }

    // Validar tamaño inicial
    final sizeKb = await ImageOptimizationService.getFileSizeKb(_selectedImage!);
    if (sizeKb > 10000) {
      _showError('Imagen muy grande (>10MB). Selecciona otra.');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 'Optimizando imagen...';
      _errorMessage = null;
    });

    try {
      // Optimizar imagen
      final optimizedBytes = await ImageOptimizationService.optimizeImageFromFile(
        _selectedImage!,
      );

      if (optimizedBytes == null) {
        throw Exception('No se pudo procesar la imagen');
      }

      setState(() => _uploadProgress = 'Subiendo a servidor...');

      // Subir a Firebase Storage
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref('profiles').child(fileName);

      final uploadTask = ref.putData(
        optimizedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Escuchar progreso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(0);
        setState(() => _uploadProgress = 'Subiendo: $progress%');
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      // Guardar en base de datos local y Firebase
      await LocalDataService().updateUserData(user.uid, {
        'avatar_url': downloadUrl,
        'username': _usernameController.text,
        'bio': _bioController.text,
      });

      setState(() {
        _currentAvatarUrl = downloadUrl;
        _selectedImage = null;
        _uploadProgress = null;
        _isLoading = false;
      });

      _showSuccess('Perfil actualizado exitosamente');
    } catch (e) {
      _showError('Error al subir: ${e.toString()}');
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _uploadProgress = null;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: SubefitColors.darkBg,
        foregroundColor: SubefitColors.textWhite,
      ),
      backgroundColor: SubefitColors.darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: _isLoading ? null : () => _showImageSourceDialog(),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade700,
                  border: Border.all(
                    color: SubefitColors.primaryRed,
                    width: 2,
                  ),
                ),
                child: _buildAvatarContent(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap para cambiar foto',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Campos de texto
            TextField(
              controller: _usernameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Nombre de Usuario',
                hintText: 'Tu nombre',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade600),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: SubefitColors.primaryRed),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              enabled: !_isLoading,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Biografía',
                hintText: 'Cuéntanos sobre ti...',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade600),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: SubefitColors.primaryRed),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            // Progreso de subida
            if (_uploadProgress != null) ...[
              LinearProgressIndicator(
                backgroundColor: Colors.grey.shade700,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                _uploadProgress!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // Mensaje de error
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botones de acción
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadProfileImage,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SubefitColors.primaryRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _removeImage,
              icon: const Icon(Icons.delete),
              label: const Text('Descartar Imagen'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
      );
    } else if (_currentAvatarUrl != null) {
      return Image.network(
        _currentAvatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60),
      );
    } else {
      return const Icon(Icons.camera_alt, size: 60, color: Colors.grey);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: SubefitColors.darkBg,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: SubefitColors.primaryRed),
                title: const Text('Cámara', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: SubefitColors.primaryRed),
                title: const Text('Galería', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
