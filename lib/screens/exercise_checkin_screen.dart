import 'package:flutter/material.dart';

class ExerciseCheckinScreen extends StatelessWidget {
  final void Function(String) onFeelingSelected;
  final VoidCallback onContinue;
  final VoidCallback onRest;
  final TextEditingController otherController;
  final String? selectedFeeling;

  const ExerciseCheckinScreen({
    Key? key,
    required this.onFeelingSelected,
    required this.onContinue,
    required this.onRest,
    required this.otherController,
    this.selectedFeeling,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Check-in de estado físico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('¿Cómo te sientes?',
                style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                _FeelingChip(
                    label: 'Cansado',
                    selected: selectedFeeling == 'Cansado',
                    onTap: () => onFeelingSelected('Cansado')),
                _FeelingChip(
                    label: 'Bien',
                    selected: selectedFeeling == 'Bien',
                    onTap: () => onFeelingSelected('Bien')),
                _FeelingChip(
                    label: 'Muy motivado',
                    selected: selectedFeeling == 'Muy motivado',
                    onTap: () => onFeelingSelected('Muy motivado')),
                _FeelingChip(
                    label: 'Otro',
                    selected: selectedFeeling == 'Otro',
                    onTap: () => onFeelingSelected('Otro')),
              ],
            ),
            if (selectedFeeling == 'Otro')
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: TextField(
                  controller: otherController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Describe cómo te sientes',
                    labelStyle: TextStyle(color: Color(0xFF00E5FF)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00E5FF))),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF94))),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Continuar rutina'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRest,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF00E5FF)),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Tomar un descanso'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeelingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FeelingChip(
      {Key? key,
      required this.label,
      required this.selected,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF00FF94),
      backgroundColor: Colors.grey[800],
      labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
    );
  }
}
