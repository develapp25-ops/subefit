import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:subefit/screens/glassmorphism.dart';
import 'user_data_model.dart';
import 'user_data_wizard_screen.dart' show WizardSection;

class GoalsStep extends StatefulWidget {
  final UserDataModel userData;
  final VoidCallback onNext;

  const GoalsStep({Key? key, required this.userData, required this.onNext})
      : super(key: key);

  @override
  State<GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends State<GoalsStep> {
  final Map<String, String> _goalAnimations = {
    'Definición': 'assets/lottie/muscle.json',
    'Ganar Masa': 'assets/lottie/dumbbell.json',
    'Rendimiento': 'assets/lottie/running.json',
  };

  @override
  Widget build(BuildContext context) {
    return WizardSection(
      title: '¿Cuál es tu Meta?',
      subtitle: 'Define tu objetivo principal para personalizar tu camino.',
      children: [
        _buildGoalSelector(),
        const SizedBox(height: 24),
        _buildIntensitySlider(),
        const SizedBox(height: 16),
        _buildCardioSwitch(),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.userData.mainGoal != null ? widget.onNext : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildGoalSelector() {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _goalAnimations.keys.map((goal) {
          final isSelected = widget.userData.mainGoal == goal;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => widget.userData.mainGoal = goal);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.cyanAccent : Colors.white24,
                  width: 2,
                ),
                gradient: LinearGradient(
                  colors: isSelected
                      ? [
                          Colors.cyan.withOpacity(0.3),
                          Colors.purple.withOpacity(0.3)
                        ]
                      : [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(_goalAnimations[goal]!,
                      height: 60, repeat: false, animate: isSelected),
                  const SizedBox(height: 8),
                  Text(goal,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIntensitySlider() {
    return GlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Nivel de Intensidad Deseado',
                style: TextStyle(color: Colors.white)),
            Slider(
              value: widget.userData.intensity,
              min: 1,
              max: 10,
              divisions: 9,
              label: widget.userData.intensity.round().toString(),
              activeColor: Colors.cyanAccent,
              inactiveColor: Colors.white30,
              onChanged: (value) {
                setState(() => widget.userData.intensity = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardioSwitch() {
    return GlassmorphicContainer(
      child: SwitchListTile.adaptive(
        title:
            const Text('Incluir Cardio', style: TextStyle(color: Colors.white)),
        subtitle: const Text('Añadir sesiones cardiovasculares a tu plan',
            style: TextStyle(color: Colors.white70)),
        value: widget.userData.includeCardio,
        onChanged: (value) {
          setState(() => widget.userData.includeCardio = value);
        },
        activeColor: Colors.cyanAccent,
      ),
    );
  }
}
