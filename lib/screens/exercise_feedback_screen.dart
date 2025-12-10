import 'package:flutter/material.dart';

class ExerciseFeedbackScreen extends StatelessWidget {
  final void Function(String) onFeelingSelected;
  final VoidCallback onFinish;
  final TextEditingController otherController;
  final String? selectedFeeling;
  final int totalReps;
  final int totalSets;
  final Duration totalTime;
  final int calories;
  final int medals;
  final int points;

  const ExerciseFeedbackScreen({
    Key? key,
    required this.onFeelingSelected,
    required this.onFinish,
    required this.otherController,
    this.selectedFeeling,
    required this.totalReps,
    required this.totalSets,
    required this.totalTime,
    required this.calories,
    required this.medals,
    required this.points,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('¡Ejercicio completado!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('¿Cómo te sientes ahora?',
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
            _SummaryRow(label: 'Repeticiones', value: totalReps.toString()),
            _SummaryRow(label: 'Series', value: totalSets.toString()),
            _SummaryRow(
                label: 'Tiempo',
                value:
                    '${totalTime.inMinutes}:${(totalTime.inSeconds % 60).toString().padLeft(2, '0')}'),
            _SummaryRow(label: 'Calorías', value: calories.toString()),
            _SummaryRow(label: 'Medallas', value: medals.toString()),
            _SummaryRow(label: 'Puntos', value: points.toString()),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF94),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Finalizar sesión'),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
