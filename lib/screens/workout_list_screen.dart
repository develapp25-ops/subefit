import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exercise_model.dart';
import 'package:subefit/screens/local_auth_service.dart';
import 'local_data_service.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'exercise_main_screen_styled.dart' show ExerciseMainScreenStyled;
import 'exercise_detail_screen.dart';
import 'package:subefit/widgets/exercise_steps_carousel.dart' as carousel;

class WorkoutListScreen extends StatefulWidget {
  final String category;
  const WorkoutListScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  late Future<List<Exercise>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _loadExercisesForCategory();
  }

  Future<List<Exercise>> _loadExercisesForCategory() async {
    final allExercises = await loadExercises();
    // Filtra los ejercicios por una categoría (esto es una simulación,
    // en un caso real, el modelo `Exercise` tendría un campo de categoría).
    return allExercises
        .where((ex) => ex.mainMuscles.any((m) => m
            .toLowerCase()
            .contains(widget.category.toLowerCase().substring(0, 3))))
        .toList();
  }

  void _startWorkout(BuildContext context, List<Exercise> exercises) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (isLoggedIn) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ExerciseMainScreenStyled(
          session: DailySession(
            day: 0, // You might want to make this dynamic or a placeholder
            title: 'Entrenamiento de ${widget.category}',
            motivationalQuote: '¡Tu fuerza te espera!',
            exercises: exercises
              .map((e) => ExerciseStep(
                  name: e.name,
                  description: e.description,
                  duration: e.duration,
                  reps: e.reps,
                  points: e.points,
                  fallbackIcon: e.fallbackIcon,
                ))
              .toList(),
          ),
        ),
      ));
    } else {
      _showLoginDialog(
          context, 'Debes iniciar sesión para comenzar el entrenamiento.', () {
        // Callback para iniciar el entrenamiento después del login exitoso
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ExerciseMainScreenStyled(
            session: DailySession(
              day: 0,
              title: 'Entrenamiento de ${widget.category}',
              motivationalQuote: '¡Tu fuerza te espera!',
                exercises: exercises
                  .map((e) => ExerciseStep(
                    name: e.name,
                    description: e.description,
                    duration: e.duration,
                    reps: e.reps,
                    points: e.points,
                    fallbackIcon: e.fallbackIcon,
                    ))
                  .toList(),
            ),
          ),
        ));
      });
    }
  }

  void _showExerciseDetail(BuildContext context, Exercise exercise) {
    // Crear los pasos para el ejercicio
    String sanitizeForAsset(String name) {
      var s = name;
      // Reemplazos básicos de acentos comunes
      const accents = {
        'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
        'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n'
      };
      accents.forEach((k, v) => s = s.replaceAll(k, v));
      // Lowercase, quitar caracteres no alfanuméricos y convertir a guiones bajos
      s = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      s = s.replaceAll(RegExp(r'_+'), '_');
      s = s.trim();
      if (s.startsWith('_')) s = s.substring(1);
      if (s.endsWith('_')) s = s.substring(0, s.length - 1);
      return s;
    }

    final base = sanitizeForAsset(exercise.name);
    final steps = <carousel.ExerciseStep>[
      carousel.ExerciseStep(
        position: 1,
        description: 'Posición inicial: ${exercise.description}',
        imageUrl: 'assets/exercises/${base}_step1.png',
      ),
      carousel.ExerciseStep(
        position: 2,
        description: 'Movimiento: Realiza el movimiento de forma controlada',
        imageUrl: 'assets/exercises/${base}_step2.png',
      ),
      carousel.ExerciseStep(
        position: 3,
        description: 'Final: Vuelve a la posición inicial',
        imageUrl: 'assets/exercises/${base}_step3.png',
      ),
    ];

    // Advertencias por tipo de ejercicio
    final warnings = _getWarningsForExercise(exercise.name);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExerciseDetailScreen(
        exerciseName: exercise.name,
        description: exercise.description,
        imageUrl: 'assets/exercises/${sanitizeForAsset(exercise.name)}_step1.png',
        steps: steps,
        warnings: warnings,
        targetMuscles: exercise.mainMuscles,
        difficulty: _getDifficultyForExercise(exercise.name),
        reps: exercise.reps != null ? int.tryParse(exercise.reps!) : null,
        duration: exercise.duration ?? const Duration(seconds: 30),
        onStartWorkout: () {
          Navigator.of(context).pop();
          _startWorkout(context, [exercise]);
        },
      ),
    ));
  }

  String _getDifficultyForExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('planchas') || name.contains('flexiones')) {
      return 'principiante';
    } else if (name.contains('burpee') || name.contains('dominadas')) {
      return 'avanzado';
    }
    return 'intermedio';
  }

  List<String> _getWarningsForExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('flexiones')) {
      return [
        'No bloquees los codos completamente',
        'Mantén el cuerpo recto de hombros a pies',
        'Controla la respiración: exhala al subir, inhala al bajar',
      ];
    } else if (name.contains('sentadillas')) {
      return [
        'Mantén las rodillas alineadas con los dedos de los pies',
        'No dejes que las rodillas superen demasiado los dedos',
        'Mantén la espalda recta',
      ];
    } else if (name.contains('burpee')) {
      return [
        'Este ejercicio es de alta intensidad',
        'Detente si sientes dolor en articulaciones',
        'Respira profundamente entre repeticiones',
      ];
    } else if (name.contains('plancha')) {
      return [
        'No dejes que tu cadera caiga',
        'Mantén el núcleo activado durante todo el movimiento',
        'Si tienes problemas de espalda, consulta a un profesional',
      ];
    }
    return ['Mantén buena forma durante el movimiento'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ejercicios: ${widget.category}'),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Exercise>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No se encontraron ejercicios para esta categoría.',
                    style: TextStyle(color: Colors.black54)));
          }

          final exercises = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      child: ListTile(
                        onTap: () => _showExerciseDetail(context, exercise),
                        leading: Icon(exercise.fallbackIcon,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30),
                        title: Text(exercise.name,
                            style: const TextStyle(
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(exercise.mainMuscles.join(', '),
                            style: const TextStyle(color: Colors.black54)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  },
                ),
              ),
              // Botón "Comenzar Entrenamiento"
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _PulsingButton(
                  onPressed: () => _startWorkout(context, exercises),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLoginDialog(
      BuildContext context, String message, VoidCallback onLoggedIn) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Acceso Requerido'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Iniciar Sesión'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el diálogo
                Navigator.of(context).pushNamed('/login').then((result) {
                  // Después de intentar el login, si fue exitoso (result == true), llamamos al callback.
                  if (result == true) {
                    onLoggedIn();
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }
}

class _PulsingButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _PulsingButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
      ),
      child: const Text('Comenzar Entrenamiento',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
        delay: 2.seconds,
        duration: 1.5.seconds,
        color: SubefitColors.primaryRed.withOpacity(0.5));
  }
}
