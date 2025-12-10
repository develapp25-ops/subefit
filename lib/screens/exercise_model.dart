import 'package:flutter/material.dart';
import 'package:subefit/widgets/subefit_icons.dart';
import 'package:subefit/widgets/subefit_colors.dart';

/// Representa un paso individual o ejercicio dentro de una sesión.
class ExerciseStep {
  final String name;
  final String description;
  final Duration? duration; // Para ejercicios cronometrados (ej. plancha 30s)
  final String?
      reps; // Para ejercicios basados en repeticiones (ej. "10-12 reps")
  final int
      sets; // Número de sets para ejercicios basados en repeticiones, por defecto 1.
  final int points; // Puntos ganados por completar el ejercicio.
  final String? type; // Tipo de ejercicio: fuerza, cardio, movilidad, etc.
  final String? motivacion; // NUEVO: Frase motivacional para el ejercicio
  final String? dificultad; // NUEVO: Principiante, Intermedio, Avanzado
  final bool requiereEquipo; // NUEVO: Si el ejercicio necesita equipo
  final IconData? fallbackIcon;

  const ExerciseStep({
    required this.name,
    required this.description,
    this.duration,
    this.reps,
    this.sets = 1,
    this.points = 0,
    this.type,
    this.motivacion,
    this.dificultad,
    this.requiereEquipo = false,
    this.fallbackIcon,
  });

  // NUEVO: Método para crear una copia con valores modificados (útil para progresión)
  ExerciseStep copyWith({
    String? name,
    String? description,
    Duration? duration,
    String? reps,
    int? sets,
    int? points,
    String? type,
    String? motivacion,
    String? dificultad,
    bool? requiereEquipo,
  }) {
    return ExerciseStep(
      name: name ?? this.name,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      points: points ?? this.points,
      type: type ?? this.type,
      motivacion: motivacion ?? this.motivacion,
      dificultad: dificultad ?? this.dificultad,
      requiereEquipo: requiereEquipo ?? this.requiereEquipo,
    );
  }

  // Constructor factory para crear desde el JSON de la IA
  factory ExerciseStep.fromJson(Map<String, dynamic> json) {
    return ExerciseStep(
      name: json['nombre'] ?? 'Ejercicio sin nombre',
      description: json['instrucciones'] ?? 'Sin instrucciones.',
      reps: (json['repeticiones'] as String?) ??
          (json['reps'] as String?), // Compatible con ambos formatos
      sets: (json['series'] as num?)?.toInt() ?? 1,
      type: json['tipo'],
      dificultad: json['dificultad'],
      requiereEquipo:
          json['requiere_equipo'] ?? json['requiereEquipo'] ?? false,
      motivacion: json['motivacion'],
    );
  }
}

/// Extension para facilitar la visualización de la duración o las repeticiones.
extension ExerciseStepDisplay on ExerciseStep {
  String displayDurationOrReps() {
    if (reps != null && reps!.isNotEmpty) {
      return '$reps reps';
    }
    if (duration != null && duration! > Duration.zero) {
      return '${duration!.inSeconds} seg';
    }
    return 'N/A';
  }

  // NUEVO: Para mostrar series y repeticiones de forma clara
  String displaySetsAndReps() {
    if (reps != null && reps!.isNotEmpty && sets > 0) {
      return '$sets x $reps reps';
    }
    return displayDurationOrReps();
  }
}

/// Representa una sesión de entrenamiento diaria o una rutina predefinida.
class DailySession {
  final int day;
  final String title;
  final String motivationalQuote;
  final List<ExerciseStep> exercises;
  const DailySession(
      {required this.day,
      required this.title,
      required this.motivationalQuote,
      required this.exercises});
}

/// Representa un plan de entrenamiento completo con varias sesiones diarias.
class TrainingPlan {
  final String id;
  final String title;
  final String description;
  final String level;
  final int durationWeeks;
  final IconData icon;
  final Color color;
  final List<DailySession> dailySessions;

  const TrainingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.durationWeeks,
    required this.icon,
    required this.color,
    required this.dailySessions,
  });

  // Constructor factory para crear un plan desde el JSON de la IA
  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    final List<dynamic> sessionsJson = json['sesiones'] ?? [];

    final List<DailySession> sessions = sessionsJson.map((sessionData) {
      final List<ExerciseStep> calentamiento =
          (sessionData['calentamiento'] as List? ?? [])
              .map((e) => ExerciseStep.fromJson(e))
              .toList();
      final List<ExerciseStep> principal =
          (sessionData['principal'] as List? ?? [])
              .map((e) => ExerciseStep.fromJson(e))
              .toList();
      final List<ExerciseStep> core = (sessionData['core'] as List? ?? [])
          .map((e) => ExerciseStep.fromJson(e))
          .toList();
      final List<ExerciseStep> estiramiento =
          (sessionData['estiramiento'] as List? ?? [])
              .map((e) => ExerciseStep.fromJson(e))
              .toList();

      return DailySession(
        day: (sessionData['dia'] as num?)?.toInt() ?? 0,
        title: sessionData['titulo'] ?? 'Día de Entrenamiento',
        motivationalQuote:
            sessionData['motivacionFinal'] ?? '¡Vamos a por ello!',
        exercises: [...calentamiento, ...principal, ...core, ...estiramiento],
      );
    }).toList();

    return TrainingPlan(
      id: 'ia_${json['nombre']?.toString().replaceAll(' ', '_').toLowerCase() ?? 'plan'}', // ID único para planes de IA
      title: json['nombre'] ?? 'Plan de IA',
      description: json['mensajeFinal'] ?? 'Un plan personalizado para ti.',
      level: json['nivel'] ?? 'Personalizado',
      durationWeeks: (json['duracionSemanas'] as num?)?.toInt() ?? 4,
      icon: Icons.smart_toy_outlined, // Icono distintivo para planes de IA
      color: SubefitColors.primaryRed, // Color distintivo
      dailySessions: sessions,
    );
  }
}

/// Representa un ejercicio individual de la librería.
class Exercise {
  final String id;
  final String name;
  final String description;
  final List<String> mainMuscles;
  final Duration? duration;
  final String? reps;
  final int points;
  final String? imageUrl;
  final IconData fallbackIcon;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.mainMuscles,
    this.duration,
    this.reps,
    this.points = 10,
    this.imageUrl,
    this.fallbackIcon = SubefitIcons.dumbbell,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Ejercicio sin nombre',
      description: json['description'] ?? '',
      mainMuscles: List<String>.from(json['main_muscles'] ?? []),
      // Normalizar y limitar la duración recibida de la fuente externa
      duration: (() {
        final secsNum = json['duration_seconds'];
        if (secsNum == null) return null;
        int secs = (secsNum as num).toInt();
        if (secs < 5) secs = 5; // mínimo 5s
        if (secs > 120) secs = 120; // máximo 120s (evita valores absurdos como 300s)
        return Duration(seconds: secs);
      })(),
      reps: (json['reps'] as num?)?.toString(),
      points: json['points'] ?? 10,
      imageUrl: json['image_url'],
    );
  }
}
