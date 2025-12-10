import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subefit/screens/glassmorphism.dart';
import 'user_data_model.dart';
import 'user_data_wizard_screen.dart' show WizardSection;

class ExperienceStep extends StatefulWidget {
  final UserDataModel userData;
  final VoidCallback onNext;

  const ExperienceStep({Key? key, required this.userData, required this.onNext})
      : super(key: key);

  @override
  State<ExperienceStep> createState() => _ExperienceStepState();
}

class _ExperienceStepState extends State<ExperienceStep> {
  final List<String> _levels = ['Principiante', 'Intermedio', 'Avanzado'];
  final List<String> _locations = ['Casa', 'Gimnasio', 'Exterior'];

  @override
  Widget build(BuildContext context) {
    return WizardSection(
      title: 'Tu Experiencia',
      subtitle: 'Cuéntanos sobre tu nivel y dónde prefieres entrenar.',
      children: [
        _buildSelector(
            'Nivel de Experiencia',
            _levels,
            widget.userData.experienceLevel,
            (val) => setState(() => widget.userData.experienceLevel = val)),
        const SizedBox(height: 16),
        _buildSelector(
            'Lugar de Entrenamiento',
            _locations,
            widget.userData.trainingLocation,
            (val) => setState(() => widget.userData.trainingLocation = val)),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: widget.userData.trainingLocation == 'Gimnasio'
              ? _buildGymAccessSelector()
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.userData.experienceLevel != null &&
                  widget.userData.trainingLocation != null
              ? widget.onNext
              : null,
          child: const Text('Finalizar y Ver Resumen'),
        ),
      ],
    );
  }

  Widget _buildSelector(String title, List<String> items, String? groupValue,
      Function(String?) onChanged) {
    return GlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            ...items
                .map((item) => RadioListTile<String>(
                      title: Text(item,
                          style: const TextStyle(color: Colors.white)),
                      value: item,
                      groupValue: groupValue,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        onChanged(val);
                      },
                      activeColor: Colors.cyanAccent,
                      contentPadding: EdgeInsets.zero,
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGymAccessSelector() {
    return GlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('En el gimnasio, ¿tienes acceso a...',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('Máquinas y peso libre',
                  style: TextStyle(color: Colors.white)),
              value: 'todo',
              groupValue: widget.userData.gymAccess,
              onChanged: (val) =>
                  setState(() => widget.userData.gymAccess = val),
              activeColor: Colors.cyanAccent,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              title: const Text('Solo peso libre (mancuernas, barras)',
                  style: TextStyle(color: Colors.white)),
              value: 'solo_peso_libre',
              groupValue: widget.userData.gymAccess,
              onChanged: (val) =>
                  setState(() => widget.userData.gymAccess = val),
              activeColor: Colors.cyanAccent,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
