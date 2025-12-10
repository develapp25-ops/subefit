import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'user_data_model.dart';
import 'user_data_wizard_screen.dart'; // For WizardSection
import '../widgets/subefit_colors.dart';

class AvatarStep extends StatefulWidget {
  final UserDataModel userData;
  final VoidCallback onNext;

  const AvatarStep({Key? key, required this.userData, required this.onNext})
      : super(key: key);

  @override
  State<AvatarStep> createState() => _AvatarStepState();
}

class _AvatarStepState extends State<AvatarStep> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        widget.userData.avatarBytes = bytes; // Guardamos los bytes en el modelo
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WizardSection(
      title: 'Elige tu Avatar',
      subtitle:
          'Sube una foto para que la comunidad te reconozca. ¡Este paso es opcional!',
      children: [
        const SizedBox(height: 32),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage:
                  _imageBytes != null ? MemoryImage(_imageBytes!) : null,
              child: _imageBytes == null
                  ? const Icon(Icons.camera_alt, color: Colors.white, size: 50)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Elegir de la Galería'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: SubefitColors.primaryRed.withOpacity(0.8),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: widget.onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: SubefitColors.primaryRed,
            minimumSize: const Size(double.infinity, 50),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // El texto cambia si el usuario ha subido una foto o no
          child: Text(_imageBytes == null ? 'Omitir y Continuar' : 'Siguiente'),
        ),
      ],
    );
  }
}
