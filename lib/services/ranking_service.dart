import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para gestionar el ranking global y medallas
class RankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener top 10 usuarios por puntos
  Future<List<UserRanking>> getTopPlayers(int limit) async {
    final querySnapshot = await _firestore
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs
        .asMap()
        .entries
        .map((entry) {
          int index = entry.key;
          var doc = entry.value;
          return UserRanking(
            rank: index + 1,
            userId: doc.id,
            username: doc['username'] ?? 'Usuario',
            totalPoints: (doc['totalPoints'] ?? 0).toInt(),
            sessionsCompleted: (doc['sessionsCompleted'] ?? 0).toInt(),
            currentStreak: (doc['currentStreak'] ?? 0).toInt(),
            avatarUrl: doc['avatar_url'],
            medals: List<String>.from(doc['medals'] ?? []),
          );
        })
        .toList();
  }

  /// Obtener ranking del usuario (posición y contexto)
  Future<UserRanking?> getUserRank(String userId) async {
    final allUsers = await _firestore
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .get();

    for (int i = 0; i < allUsers.docs.length; i++) {
      if (allUsers.docs[i].id == userId) {
        var doc = allUsers.docs[i];
        return UserRanking(
          rank: i + 1,
          userId: doc.id,
          username: doc['username'] ?? 'Usuario',
          totalPoints: (doc['totalPoints'] ?? 0).toInt(),
          sessionsCompleted: (doc['sessionsCompleted'] ?? 0).toInt(),
          currentStreak: (doc['currentStreak'] ?? 0).toInt(),
          avatarUrl: doc['avatar_url'],
          medals: List<String>.from(doc['medals'] ?? []),
        );
      }
    }
    return null;
  }

  /// Agregar puntos a un usuario
  Future<void> addPoints(String userId, int points) async {
    final userRef = _firestore.collection('users').doc(userId);
    await userRef.update({
      'totalPoints': FieldValue.increment(points),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
    _checkAndAwardMedals(userId);
  }

  /// Registrar sesión completada
  Future<void> recordSessionCompletion(
    String userId,
    int pointsEarned,
    String sessionType,
  ) async {
    final userRef = _firestore.collection('users').doc(userId);
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await userRef.update({
      'sessionsCompleted': FieldValue.increment(1),
      'totalPoints': FieldValue.increment(pointsEarned),
      'lastSessionDate': dateKey,
      'lastSessionType': sessionType,
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    _updateStreak(userId);
    _checkAndAwardMedals(userId);
  }

  /// Actualizar racha de días consecutivos
  Future<void> _updateStreak(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final lastSessionDate = userDoc['lastSessionDate'];
    final currentStreak = (userDoc['currentStreak'] ?? 0) as int;

    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (lastSessionDate != dateKey) {
      final yesterday = today.subtract(Duration(days: 1));
      final yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      if (lastSessionDate == yesterdayKey) {
        // Continuar la racha
        await _firestore.collection('users').doc(userId).update({
          'currentStreak': currentStreak + 1,
          'maxStreak': currentStreak + 1,
        });
      } else {
        // Reiniciar la racha
        await _firestore.collection('users').doc(userId).update({
          'currentStreak': 1,
        });
      }
    }
  }

  /// Verificar y otorgar medallas al usuario
  Future<void> _checkAndAwardMedals(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final medals = List<String>.from(userDoc['medals'] ?? []);
    final sessionsCompleted = (userDoc['sessionsCompleted'] ?? 0) as int;
    final totalPoints = (userDoc['totalPoints'] ?? 0) as int;
    final currentStreak = (userDoc['currentStreak'] ?? 0) as int;

    final newMedals = <String>[];

    // Medalla 7 días
    if (currentStreak >= 7 && !medals.contains('7dias')) {
      newMedals.add('7dias');
    }

    // Medalla 30 días
    if (currentStreak >= 30 && !medals.contains('30dias')) {
      newMedals.add('30dias');
    }

    // Medalla 100 sesiones
    if (sessionsCompleted >= 100 && !medals.contains('100sesiones')) {
      newMedals.add('100sesiones');
    }

    // Medalla 1000 puntos
    if (totalPoints >= 1000 && !medals.contains('1000puntos')) {
      newMedals.add('1000puntos');
    }

    // Medalla 500 sesiones
    if (sessionsCompleted >= 500 && !medals.contains('500sesiones')) {
      newMedals.add('500sesiones');
    }

    // Medalla Top 10
    final userRank = await getUserRank(userId);
    if (userRank != null && userRank.rank <= 10 && !medals.contains('top10')) {
      newMedals.add('top10');
    }

    if (newMedals.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update({
        'medals': FieldValue.arrayUnion(newMedals),
      });
    }
  }

  /// Obtener descripción de una medalla
  static String getMedalDescription(String medalId) {
    const descriptions = {
      '7dias': '7 días consecutivos',
      '30dias': '30 días consecutivos',
      '100sesiones': '100 sesiones completadas',
      '500sesiones': '500 sesiones completadas',
      '1000puntos': '1000 puntos ganados',
      'top10': 'Top 10 ranking global',
    };
    return descriptions[medalId] ?? 'Medalla desconocida';
  }

  /// Obtener emoji/icono de una medalla
  static String getMedalEmoji(String medalId) {
    const emojis = {
      '7dias': '🔥',
      '30dias': '🌟',
      '100sesiones': '💪',
      '500sesiones': '🏆',
      '1000puntos': '💎',
      'top10': '👑',
    };
    return emojis[medalId] ?? '🎖️';
  }
}

/// Modelo de Ranking del Usuario
class UserRanking {
  final int rank;
  final String userId;
  final String username;
  final int totalPoints;
  final int sessionsCompleted;
  final int currentStreak;
  final String? avatarUrl;
  final List<String> medals;

  const UserRanking({
    required this.rank,
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.sessionsCompleted,
    required this.currentStreak,
    this.avatarUrl,
    required this.medals,
  });
}
