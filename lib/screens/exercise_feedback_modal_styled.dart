import 'package:flutter/material.dart';
import '../widgets/subefit_colors.dart';
import '../widgets/subefit_button.dart';
import '../widgets/subefit_celebration.dart';

class ExerciseFeedbackModalStyled extends StatelessWidget {
  final void Function(String) onFeelingSelected;
  final VoidCallback onFinish;
  final TextEditingController? otherController;
  final String? selectedFeeling;
  final int? totalReps;
  final int totalSets;
  final Duration totalTime;
  final int? calories;
  final int? medals;
  final int? points;
  final String iaFeedback;
  final bool showCelebration;

  const ExerciseFeedbackModalStyled({
    Key? key,
    this.onFeelingSelected = _defaultOnFeelingSelected,
    required this.onFinish,
    this.otherController,
    this.selectedFeeling,
    this.totalReps,
    required this.totalSets,
    required this.totalTime,
    this.calories,
    this.medals,
    this.points,
    required this.iaFeedback,
    this.showCelebration = false,
  }) : super(key: key);

  static void _defaultOnFeelingSelected(String feeling) {}

  @override
  Widget build(BuildContext context) {
    final min = totalTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = totalTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Stack(
      children: [
        Dialog(
          backgroundColor: SubefitColors.darkBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('¡Sesión completada!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF00FF94),
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (totalReps != null)
                    _SummaryRow(
                        label: 'Repeticiones', value: totalReps.toString()),
                  _SummaryRow(label: 'Series', value: totalSets.toString()),
                  _SummaryRow(label: 'Tiempo', value: '$min:$sec'),
                  if (calories != null)
                    _SummaryRow(label: 'Calorías', value: calories.toString()),
                  if (medals != null)
                    _SummaryRow(label: 'Medallas', value: medals.toString()),
                  if (points != null)
                    _SummaryRow(label: 'Puntos', value: points.toString()),
                  if (points != null) const SizedBox(height: 16),
                  Text('Feedback de IA:',
                      style: TextStyle(
                          color: SubefitColors.primaryRed,
                          fontWeight: FontWeight.bold)),
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
                      child: otherController != null
                          ? TextField(
                              controller: otherController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Describe cómo te sientes',
                                labelStyle:
                                    TextStyle(color: SubefitColors.primaryRed),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: SubefitColors.primaryRed)),
                                focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.green)),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  const SizedBox(height: 24),
                  SubefitButton(
                    label: 'Finalizar y guardar',
                    emoji: '✅',
                    isPrimary: true,
                    onPressed: onFinish,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showCelebration)
          const SubefitCelebration(message: '¡Lo lograste! Gran trabajo 💪'),
      ],
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
      selectedColor: Colors.green,
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
                  color: SubefitColors.primaryRed,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
