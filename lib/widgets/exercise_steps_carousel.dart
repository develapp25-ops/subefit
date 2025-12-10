import 'package:flutter/material.dart';

class ExerciseStep {
  final int position;
  final String description;
  final String imageUrl;

  ExerciseStep({
    required this.position,
    required this.description,
    required this.imageUrl,
  });
}

class ExerciseStepsCarousel extends StatefulWidget {
  final List<ExerciseStep> steps;

  const ExerciseStepsCarousel({
    required this.steps,
    Key? key,
  }) : super(key: key);

  @override
  State<ExerciseStepsCarousel> createState() => _ExerciseStepsCarouselState();
}

class _ExerciseStepsCarouselState extends State<ExerciseStepsCarousel> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final step = widget.steps[_currentStep];

    return Column(
      children: [
        Text(
          'Paso ${_currentStep + 1} de ${widget.steps.length}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[200],
          ),
          child: Image.asset(
            step.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[400],
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 60),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _currentStep > 0
                  ? () => setState(() => _currentStep--)
                  : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _currentStep < widget.steps.length - 1
                  ? () => setState(() => _currentStep++)
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Siguiente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
