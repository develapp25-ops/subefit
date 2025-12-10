import 'package:flutter/material.dart';

class ExerciseFeedbackModal extends StatelessWidget {
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
  final String iaFeedback;

  const ExerciseFeedbackModal({
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
    required this.iaFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final min = totalTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = totalTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('¡Sesión completada!',
                  style: TextStyle(
                      color: Color(0xFF00FF94),
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _SummaryRow(label: 'Repeticiones', value: totalReps.toString()),
              _SummaryRow(label: 'Series', value: totalSets.toString()),
              _SummaryRow(label: 'Tiempo', value: '$min:$sec'),
              _SummaryRow(label: 'Calorías', value: calories.toString()),
              _SummaryRow(label: 'Medallas', value: medals.toString()),
              _SummaryRow(label: 'Puntos', value: points.toString()),
              const SizedBox(height: 24),
              Text('Feedback de IA:',
                  style: TextStyle(
                      color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(iaFeedback, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              const Text('¿Cómo te sientes ahora?',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 12),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF94),
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Finalizar y guardar'),
              ),
            ],
          ),
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
