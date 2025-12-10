import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subefit/screens/glassmorphism.dart';
import 'user_data_model.dart';
import 'user_data_wizard_screen.dart' show WizardSection;

class HealthStep extends StatefulWidget {
  final UserDataModel userData;
  final VoidCallback onNext;

  const HealthStep({Key? key, required this.userData, required this.onNext})
      : super(key: key);

  @override
  State<HealthStep> createState() => _HealthStepState();
}

class _HealthStepState extends State<HealthStep> {
  final List<String> _bodyParts = [
    'Hombros',
    'Espalda',
    'Rodillas',
    'Muñecas',
    'Tobillos',
    'Cuello',
    'Cadera'
  ];

  void _toggleInjury(String part) {
    HapticFeedback.lightImpact();
    setState(() {
      if (widget.userData.injuries.contains(part)) {
        widget.userData.injuries.remove(part);
      } else {
        widget.userData.injuries.add(part);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WizardSection(
      title: 'Tu Bienestar',
      subtitle: 'Indícanos si tienes alguna lesión o condición a considerar.',
      children: [
        _buildInjurySelector(),
        const SizedBox(height: 24),
        GlassmorphicContainer(
          child: TextField(
            onChanged: (value) => widget.userData.medicalNotes = value,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comentarios médicos (opcional)',
              labelStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.onNext,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildInjurySelector() {
    return GlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Zonas con molestias o lesiones?',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _bodyParts.map((part) {
                final isSelected = widget.userData.injuries.contains(part);
                return ChoiceChip(
                  label: Text(part),
                  selected: isSelected,
                  onSelected: (_) => _toggleInjury(part),
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white),
                  selectedColor: Colors.cyanAccent,
                  backgroundColor: Colors.white.withOpacity(0.2),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
