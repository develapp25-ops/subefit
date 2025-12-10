import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subefit/screens/glassmorphism.dart';
import 'user_data_model.dart';
import 'user_data_wizard_screen.dart' show WizardSection;

class PhysicalDataStep extends StatefulWidget {
  final UserDataModel userData;
  final VoidCallback onNext;

  const PhysicalDataStep(
      {Key? key, required this.userData, required this.onNext})
      : super(key: key);

  @override
  State<PhysicalDataStep> createState() => _PhysicalDataStepState();
}

class _PhysicalDataStepState extends State<PhysicalDataStep> {
  double _bmi = 0;
  String _bmiMessage = '';

  @override
  void initState() {
    super.initState();
    _calculateBmi();
  }

  void _calculateBmi() {
    final height = widget.userData.height;
    final weight = widget.userData.weight;

    if (height != null && height > 0 && weight != null && weight > 0) {
      setState(() {
        _bmi = weight / pow(height / 100, 2);
        if (_bmi < 18.5) {
          _bmiMessage = 'Tu plan podría enfocarse en ganar masa muscular.';
        } else if (_bmi > 25) {
          _bmiMessage = 'Tu plan priorizará la quema de grasa y cardio.';
        } else {
          _bmiMessage = '¡Estás en un rango de peso saludable!';
        }
      });
    } else {
      setState(() {
        _bmi = 0;
        _bmiMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WizardSection(
      title: 'Tu Composición',
      subtitle: 'Empecemos con lo básico para entender tu punto de partida.',
      children: [
        _buildBmiIndicator(),
        const SizedBox(height: 24),
        GlassmorphicContainer(
          child: TextField(
            onChanged: (value) {
              widget.userData.height = double.tryParse(value);
              _calculateBmi();
            },
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Altura (cm)'),
          ),
        ),
        const SizedBox(height: 16),
        GlassmorphicContainer(
          child: TextField(
            onChanged: (value) {
              widget.userData.weight = double.tryParse(value);
              _calculateBmi();
            },
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Peso (kg)'),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed:
              widget.userData.height != null && widget.userData.weight != null
                  ? widget.onNext
                  : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildBmiIndicator() {
    return GlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('IMC (Índice de Masa Corporal)',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                _bmi.toStringAsFixed(1),
                key: ValueKey<String>(_bmi.toStringAsFixed(1)),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _bmiMessage,
                key: ValueKey<String>(_bmiMessage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.cyanAccent, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.cyanAccent),
      ),
    );
  }
}
