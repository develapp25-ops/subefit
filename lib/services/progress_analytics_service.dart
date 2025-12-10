import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para gestionar análisis y estadísticas de progreso
class ProgressAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener estadísticas completas del usuario
  Future<UserStats?> getUserStats(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return UserStats(
      userId: userId,
      totalSessions: (data['sessionsCompleted'] ?? 0).toInt(),
      totalMinutes: (data['totalMinutes'] ?? 0).toInt(),
      totalPoints: (data['totalPoints'] ?? 0).toInt(),
      currentStreak: (data['currentStreak'] ?? 0).toInt(),
      maxStreak: (data['maxStreak'] ?? 0).toInt(),
      favoriteExerciseType: data['favoriteExerciseType'] ?? 'cardio',
      avgPointsPerWeek: _calculateAvgPointsPerWeek(data),
      lastSessionDate: data['lastSessionDate'],
      joinDate: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
    );
  }

  /// Obtener actividad de los últimos N días
  Future<List<DailyActivity>> getActivityHistory(String userId, int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final activityMap = <String, DailyActivity>{};

    // Inicializar con ceros para todos los días
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      activityMap[key] = DailyActivity(
        date: key,
        sessionsCompleted: 0,
        totalMinutes: 0,
        pointsEarned: 0,
      );
    }

    // Obtener datos reales de la sesión
    final sessionsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .where('completedAt', isGreaterThanOrEqualTo: startDate)
        .get();

    for (var doc in sessionsQuery.docs) {
      final data = doc.data();
      final dateKey = data['dateKey'] as String?;
      if (dateKey != null && activityMap.containsKey(dateKey)) {
        final current = activityMap[dateKey]!;
        activityMap[dateKey] = DailyActivity(
          date: dateKey,
          sessionsCompleted: current.sessionsCompleted + 1,
          totalMinutes: current.totalMinutes + (data['durationMinutes'] as int? ?? 0),
          pointsEarned: current.pointsEarned + (data['pointsEarned'] as int? ?? 0),
        );
      }
    }

    return activityMap.values.toList();
  }

  /// Obtener ejercicios favoritos (más completados)
  Future<List<FavoriteExercise>> getFavoriteExercises(String userId, int limit) async {
    final exerciseCounts = <String, int>{};

    final sessionsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .get();

    for (var doc in sessionsQuery.docs) {
      final data = doc.data();
      final exercises = List<Map<String, dynamic>>.from(data['exercises'] ?? []);
      for (var exercise in exercises) {
        final name = exercise['name'] as String?;
        if (name != null) {
          exerciseCounts[name] = (exerciseCounts[name] ?? 0) + 1;
        }
      }
    }

    final favorites = exerciseCounts.entries
        .map((e) => FavoriteExercise(name: e.key, timesCompleted: e.value))
        .toList()
      ..sort((a, b) => b.timesCompleted.compareTo(a.timesCompleted));

    return favorites.take(limit).toList();
  }

  /// Grabar sesión completada
  Future<void> recordSessionCompletion(
    String userId, {
    required String sessionType,
    required int durationMinutes,
    required int pointsEarned,
    required List<String> exercisesCompleted,
  }) async {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .add({
          'sessionType': sessionType,
          'durationMinutes': durationMinutes,
          'pointsEarned': pointsEarned,
          'exercises': exercisesCompleted.map((e) => {'name': e}).toList(),
          'dateKey': dateKey,
          'completedAt': FieldValue.serverTimestamp(),
        });

    // Actualizar totales del usuario
    await _firestore.collection('users').doc(userId).update({
      'totalMinutes': FieldValue.increment(durationMinutes),
      'sessionsCompleted': FieldValue.increment(1),
      'totalPoints': FieldValue.increment(pointsEarned),
      'favoriteExerciseType': sessionType,
      'lastSessionDate': dateKey,
    });
  }

  /// Calcular promedio de puntos por semana
  double _calculateAvgPointsPerWeek(Map<String, dynamic> userData) {
    final createdAt = userData['createdAt'] != null ? DateTime.parse(userData['createdAt']) : DateTime.now();
    final weeksPassed = DateTime.now().difference(createdAt).inDays / 7;
    final totalPoints = (userData['totalPoints'] ?? 0).toDouble();
    return weeksPassed > 0 ? totalPoints / weeksPassed : 0;
  }
}

/// Modelo de Estadísticas del Usuario
class UserStats {
  final String userId;
  final int totalSessions;
  final int totalMinutes;
  final int totalPoints;
  final int currentStreak;
  final int maxStreak;
  final String favoriteExerciseType;
  final double avgPointsPerWeek;
  final String? lastSessionDate;
  final DateTime joinDate;

  const UserStats({
    required this.userId,
    required this.totalSessions,
    required this.totalMinutes,
    required this.totalPoints,
    required this.currentStreak,
    required this.maxStreak,
    required this.favoriteExerciseType,
    required this.avgPointsPerWeek,
    this.lastSessionDate,
    required this.joinDate,
  });

  /// Calcular días desde que se unió
  int get daysSinceJoin => DateTime.now().difference(joinDate).inDays;

  /// Calcular promedio de puntos por sesión
  double get avgPointsPerSession => totalSessions > 0 ? totalPoints / totalSessions : 0;
}

/// Modelo de Actividad Diaria
class DailyActivity {
  final String date; // Formato: YYYY-MM-DD
  final int sessionsCompleted;
  final int totalMinutes;
  final int pointsEarned;

  const DailyActivity({
    required this.date,
    required this.sessionsCompleted,
    required this.totalMinutes,
    required this.pointsEarned,
  });
}

/// Modelo de Ejercicio Favorito
class FavoriteExercise {
  final String name;
  final int timesCompleted;

  const FavoriteExercise({
    required this.name,
    required this.timesCompleted,
  });
}
