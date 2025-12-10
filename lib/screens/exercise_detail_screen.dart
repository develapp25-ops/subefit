import 'package:flutter/material.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:subefit/widgets/exercise_video_player.dart';
import 'package:subefit/widgets/exercise_steps_carousel.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseName;
  final String description;
  final String imageUrl;
  final List<ExerciseStep> steps;
  final List<String> warnings;
  final List<String> targetMuscles;
  final String difficulty;
  final int? reps;
  final Duration duration;
  final VoidCallback onStartWorkout;

  const ExerciseDetailScreen({
    required this.exerciseName,
    required this.description,
    required this.imageUrl,
    required this.steps,
    required this.warnings,
    required this.targetMuscles,
    required this.difficulty,
    this.reps,
    required this.duration,
    required this.onStartWorkout,
    Key? key,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Video/Imagen
            ExerciseVideoPlayer(
              imageUrl: widget.imageUrl,
            ),
            const SizedBox(height: 24),

            // Nombre y dificultad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.exerciseName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(widget.difficulty),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.difficulty,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Músculos y tiempo
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  icon: Icons.timer,
                  label: '${widget.duration.inSeconds}s',
                ),
                if (widget.reps != null)
                  _buildInfoChip(
                    icon: Icons.repeat,
                    label: '${widget.reps} reps',
                  ),
                ...widget.targetMuscles.map(
                  (muscle) => _buildInfoChip(
                    icon: Icons.fitness_center,
                    label: muscle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Descripción
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pasos
            if (widget.steps.isNotEmpty) ...[
              const Text(
                'Técnica Correcta (Paso a Paso)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ExerciseStepsCarousel(
                    steps: widget.steps,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Advertencias
            if (widget.warnings.isNotEmpty) ...[
              const Text(
                '⚠️ Advertencias de Seguridad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: widget.warnings
                        .map(
                          (warning) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(warning),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Botón Empezar
            ElevatedButton(
              onPressed: widget.onStartWorkout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: SubefitColors.primaryRed,
              ),
              child: const Text(
                'Empezar Ejercicio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'principiante':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
