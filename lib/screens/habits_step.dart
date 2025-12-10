import 'package:flutter/material.dart';
import 'package:subefit/screens/glassmorphism.dart';
import 'user_data_model.dart';
import 'user_data_wizard_screen.dart' show WizardSection;

class HabitsStep extends StatefulWidget {
  final UserDataModel userData;
  final VoidCallback onNext;

  const HabitsStep({Key? key, required this.userData, required this.onNext})
      : super(key: key);

  @override
  State<HabitsStep> createState() => _HabitsStepState();
}

class _HabitsStepState extends State<HabitsStep> {
  @override
  Widget build(BuildContext context) {
    bool showSleepWarning = widget.userData.sleepHours < 5;

    return WizardSection(
      title: 'Tus Hábitos',
      subtitle: 'Tu rutina diaria influye en tu rendimiento. Conozcámosla.',
      children: [
        _buildSleepSlider(),
        const SizedBox(height: 16),
        AnimatedOpacity(
          opacity: showSleepWarning ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: GlassmorphicContainer(
            borderColor: Colors.orangeAccent,
            child: const ListTile(
              leading:
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              title: Text('Descanso Insuficiente',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Menos de 5 horas de sueño puede afectar tu recuperación y energía.',
                  style: TextStyle(color: Colors.white70)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
                child: _buildTimePicker(
                    'Hora de Dormir',
                    widget.userData.bedtime,
                    (time) => setState(() => widget.userData.bedtime = time))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTimePicker(
                    'Hora de Despertar',
                    widget.userData.wakeupTime,
                    (time) =>
                        setState(() => widget.userData.wakeupTime = time))),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.onNext,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildSleepSlider() {
    return GlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
                'Horas de sueño promedio: ${widget.userData.sleepHours.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white)),
            Slider(
              value: widget.userData.sleepHours,
              min: 4,
              max: 10,
              divisions: 12,
              label: widget.userData.sleepHours.toStringAsFixed(1),
              activeColor: Colors.cyanAccent,
              inactiveColor: Colors.white30,
              onChanged: (value) {
                setState(() => widget.userData.sleepHours = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
      String label, TimeOfDay? initialTime, Function(TimeOfDay) onTimeChanged) {
    return GlassmorphicContainer(
      child: InkWell(
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: initialTime ?? TimeOfDay.now(),
          );
          if (time != null) {
            onTimeChanged(time);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(
                initialTime?.format(context) ?? 'Seleccionar',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
