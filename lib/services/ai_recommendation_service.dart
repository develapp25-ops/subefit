import 'package:subefit/screens/exercise_model.dart';
import 'package:subefit/services/user_profile_service.dart';
import 'package:subefit/services/progress_analytics_service.dart';

/// Servicio de recomendaciones inteligentes basadas en IA
class AIRecommendationService {
  /// Recomendar siguiente sesión según historial y perfil
  static String recommendNextSession(
    UserStats? stats,
    UserProfile? profile,
    List<String> recentSessionTypes,
  ) {
    if (stats == null || profile == null) {
      return 'Cardio Express'; // Recomendación por defecto
    }

    // Si ha hecho mucha fuerza, recomendar flexibilidad
    if (recentSessionTypes.where((s) => s.contains('Fuerza')).length >= 2) {
      return 'Flexibilidad y Movilidad';
    }

    // Si ha hecho mucho cardio, recomendar fuerza o core
    if (recentSessionTypes.where((s) => s.contains('Cardio')).length >= 2) {
      return profile.level == 'principiante' ? 'Core y Abdominales' : 'Fuerza Total';
    }

    // Según el nivel
    if (profile.level == 'principiante') {
      return 'Principiante: Sin Impacto';
    } else if (profile.level == 'avanzado') {
      return 'AMRAP: As Many Rounds As Possible';
    }

    return 'Fuerza Total';
  }

  /// Obtener mensaje motivacional personalizado
  static String getMotivationalMessage(UserStats? stats, int currentStreak) {
    if (stats == null) return '¡Vamos a entrenar! 💪';

    if (currentStreak == 0) {
      return '¡Hoy es el día! Comienza tu racha 🔥';
    } else if (currentStreak >= 30) {
      return '¡30 días consecutivos! Eres un campeón 👑';
    } else if (currentStreak >= 7) {
      return '¡Una semana de fuego! Mantén la racha 🔥';
    } else if (stats.totalSessions >= 100) {
      return '¡Ya 100 sesiones! Eres increíble 🎯';
    } else if (stats.totalSessions >= 50) {
      return '¡50 sesiones completadas! Vas fuerte 💪';
    }

    return '¡Sigamos mejorando! 🚀';
  }

  /// Detectar si el usuario necesita descanso
  static bool shouldSuggestRest(
    UserStats? stats,
    String? lastSessionDate,
  ) {
    if (stats == null || lastSessionDate == null) return false;

    // Si tiene una racha larga, recomendar descanso
    if (stats.currentStreak > 21) {
      return true;
    }

    // Si ha entrenado muchos minutos esta semana
    if (stats.totalMinutes > 300) {
      return true;
    }

    return false;
  }

  /// Obtener sugerencia de variedad
  static String getVarietySuggestion(List<String> recentSessions) {
    if (recentSessions.isEmpty) return 'Comienza con Cardio Express';

    // Contar tipos
    final cardio = recentSessions.where((s) => s.contains('Cardio')).length;
    final fuerza = recentSessions.where((s) => s.contains('Fuerza')).length;
    final flex = recentSessions.where((s) => s.contains('Flexibilidad')).length;
    final core = recentSessions.where((s) => s.contains('Core')).length;

    // Sugerir la que menos se ha hecho
    if (flex < cardio && flex < fuerza) {
      return 'Has hecho mucha fuerza y cardio, intenta flexibilidad hoy';
    }
    if (cardio < fuerza) {
      return 'Última sesión fue fuerza, calienta con cardio';
    }
    if (core < fuerza && core < cardio) {
      return 'Fortalece tu core hoy para mejor estabilidad';
    }

    return 'Elige la sesión que más te apetezca';
  }

  /// Predecir siguiente meta del usuario
  static String predictNextMilestone(UserStats? stats) {
    if (stats == null) return 'Primera sesión completada';

    if (stats.totalSessions < 10) return 'Primera semana (10 sesiones)';
    if (stats.totalSessions < 50) return 'Mes de consistencia (50 sesiones)';
    if (stats.totalSessions < 100) return 'Sigue adelante (100 sesiones)';
    if (stats.totalPoints < 1000) return '1000 puntos (${1000 - stats.totalPoints} puntos restantes)';
    if (stats.currentStreak < 30) return '30 días consecutivos (${30 - stats.currentStreak} días)';

    return 'Campeón absoluto ¡Crea tu propia meta!';
  }

  /// Sugerir equipamiento según capacidad
  static String suggestEquipment(UserProfile profile) {
    if (profile.hasDumbbells &&
        profile.hasResistanceBand &&
        profile.hasBar &&
        profile.hasKettlebell) {
      return 'Tienes todo el equipamiento. Intenta ejercicios combinados';
    }

    final missing = <String>[];
    if (!profile.hasDumbbells) missing.add('mancuernas');
    if (!profile.hasResistanceBand) missing.add('banda elástica');
    if (!profile.hasBar) missing.add('barra');
    if (!profile.hasKettlebell) missing.add('kettlebell');

    if (missing.isEmpty) return 'Excelente equipamiento';

    return 'Considera agregar: ${missing.join(', ')}';
  }

  /// Analizar consistencia semanal
  static String analyzeWeeklyConsistency(List<DailyActivity> weekActivity) {
    final daysActive = weekActivity.where((d) => d.sessionsCompleted > 0).length;

    if (daysActive == 0) return 'No entrenaste esta semana. ¡Comienza hoy! 💪';
    if (daysActive <= 2) return 'Baja consistencia esta semana. Intenta 3-4 días';
    if (daysActive <= 4) return 'Bien, pero puedes hacer más. Apunta a 5-6 días';
    if (daysActive <= 6) return 'Excelente semana. Casi perfecto';

    return '¡Semana perfecta! 7 días entrenando 🔥';
  }
}
