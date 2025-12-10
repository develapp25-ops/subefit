import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para gestionar notificaciones push motivacionales
class PushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guardar preferencias de notificaciones del usuario
  Future<void> saveNotificationPreferences(
    String userId,
    NotificationPreferences prefs,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'notificationPreferences': prefs.toJson(),
    });
  }

  /// Obtener preferencias de notificaciones
  Future<NotificationPreferences?> getNotificationPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data()!.containsKey('notificationPreferences')) {
      return NotificationPreferences.fromJson(doc['notificationPreferences']);
    }
    return null;
  }

  /// Generar mensaje motivacional según el tipo de evento
  static String generateMotivationalMessage(
    String eventType,
    int? value,
    String? userName,
  ) {
    userName ??= 'Usuario';

    switch (eventType) {
      case 'sessionComplete':
        return '¡Lo hiciste, $userName! 🎉 +${value ?? 0} puntos ganados';
      case 'streakMilestone':
        return '¡Racha de $value días! 🔥 Mantén el fuego encendido';
      case 'streakWarning':
        return 'Oops, a punto de perder tu racha de $value días 😅 ¡Entrena hoy!';
      case 'sessionMilestone':
        return '¡$value sesiones completadas! 💪 Eres imparable';
      case 'pointsMilestone':
        return '¡$value puntos ganados! 💎 Sigue así';
      case 'medalEarned':
        return 'Ganaste una medalla 🏆 ¡Increíble, $userName!';
      case 'topRankAchieved':
        return '¡Top 10 ranking! 👑 $userName, estás entre los mejores';
      case 'inactiveReminder':
        return 'Hace $value días que no entrenas. ¿Volvemos? 💪';
      case 'friendActivity':
        return 'Tu amigo $userName acaba de completar una sesión 🔥';
      case 'dailyChallenge':
        return 'Nuevo reto diario disponible. ¿Aceptas el desafío? ⚡';
      default:
        return '¡Hora de entrenar! 💪';
    }
  }

  /// Programa notificación de recordatorio
  Future<void> scheduleReminderNotification(
    String userId,
    DateTime scheduledTime,
    String title,
    String body,
  ) async {
    await _firestore.collection('scheduledNotifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'sent': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Obtener notificaciones pendientes
  Future<List<ScheduledNotification>> getPendingNotifications(String userId) async {
    final now = Timestamp.now();
    final query = await _firestore
        .collection('scheduledNotifications')
        .where('userId', isEqualTo: userId)
        .where('sent', isEqualTo: false)
        .where('scheduledTime', isLessThanOrEqualTo: now)
        .get();

    return query.docs
        .map((doc) => ScheduledNotification(
              id: doc.id,
              userId: doc['userId'],
              title: doc['title'],
              body: doc['body'],
              scheduledTime: doc['scheduledTime'].toDate(),
              sent: doc['sent'],
            ))
        .toList();
  }

  /// Marcar notificación como enviada
  Future<void> markNotificationAsSent(String notificationId) async {
    await _firestore
        .collection('scheduledNotifications')
        .doc(notificationId)
        .update({'sent': true, 'sentAt': FieldValue.serverTimestamp()});
  }

  /// Analizar si enviar recordatorio por inactividad
  static bool shouldSendInactivityReminder(
    String? lastSessionDate,
    int daysSinceLastSession,
    NotificationPreferences prefs,
  ) {
    if (!prefs.enableInactivityReminders) return false;
    if (daysSinceLastSession < 3) return false; // Mínimo 3 días sin entrenar
    if (daysSinceLastSession > 14) return true; // Siempre recordar después de 2 semanas
    return daysSinceLastSession % prefs.inactivityReminderDays == 0;
  }

  /// Analizar si enviar advertencia de racha
  static bool shouldSendStreakWarning(
    int currentStreak,
    String? lastSessionDate,
    NotificationPreferences prefs,
  ) {
    if (!prefs.enableStreakWarnings) return false;
    if (currentStreak < 3) return false; // No avisar si la racha es muy corta
    
    // Avisar a las 20:00 si no ha entrenado hoy
    final now = DateTime.now();
    final lastSession = lastSessionDate;
    
    if (lastSession == null) return false;
    
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return lastSession != today && now.hour >= 20;
  }

  /// Generar resumen semanal
  static String generateWeeklySummary(
    int sessionsThisWeek,
    int pointsThisWeek,
    int minutesThisWeek,
  ) {
    return 'Resumen semanal: $sessionsThisWeek sesiones, $pointsThisWeek puntos, $minutesThisWeek minutos ⏱️';
  }
}

/// Modelo de Preferencias de Notificaciones
class NotificationPreferences {
  final bool enableSessionCompletion; // Notificar cuando completa sesión
  final bool enableStreakMilestones; // Notificar por hitos de racha (7, 30 días)
  final bool enableStreakWarnings; // Advertencia de riesgo de perder racha
  final bool enableSessionMilestones; // Notificar por 50, 100 sesiones
  final bool enablePointsMilestones; // Notificar por puntos
  final bool enableMedalNotifications; // Notificar cuando gana medalla
  final bool enableInactivityReminders; // Recordar si no entrena
  final bool enableDailyChallenges; // Retos diarios
  final bool enableWeeklySummary; // Resumen semanal
  final int inactivityReminderDays; // Cada cuántos días recordar (3, 5, 7)
  final String? preferredReminderTime; // Hora preferida para recordatorios (HH:mm)

  const NotificationPreferences({
    this.enableSessionCompletion = true,
    this.enableStreakMilestones = true,
    this.enableStreakWarnings = true,
    this.enableSessionMilestones = true,
    this.enablePointsMilestones = true,
    this.enableMedalNotifications = true,
    this.enableInactivityReminders = true,
    this.enableDailyChallenges = true,
    this.enableWeeklySummary = true,
    this.inactivityReminderDays = 7,
    this.preferredReminderTime = '08:00',
  });

  Map<String, dynamic> toJson() => {
        'enableSessionCompletion': enableSessionCompletion,
        'enableStreakMilestones': enableStreakMilestones,
        'enableStreakWarnings': enableStreakWarnings,
        'enableSessionMilestones': enableSessionMilestones,
        'enablePointsMilestones': enablePointsMilestones,
        'enableMedalNotifications': enableMedalNotifications,
        'enableInactivityReminders': enableInactivityReminders,
        'enableDailyChallenges': enableDailyChallenges,
        'enableWeeklySummary': enableWeeklySummary,
        'inactivityReminderDays': inactivityReminderDays,
        'preferredReminderTime': preferredReminderTime,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        enableSessionCompletion: json['enableSessionCompletion'] ?? true,
        enableStreakMilestones: json['enableStreakMilestones'] ?? true,
        enableStreakWarnings: json['enableStreakWarnings'] ?? true,
        enableSessionMilestones: json['enableSessionMilestones'] ?? true,
        enablePointsMilestones: json['enablePointsMilestones'] ?? true,
        enableMedalNotifications: json['enableMedalNotifications'] ?? true,
        enableInactivityReminders: json['enableInactivityReminders'] ?? true,
        enableDailyChallenges: json['enableDailyChallenges'] ?? true,
        enableWeeklySummary: json['enableWeeklySummary'] ?? true,
        inactivityReminderDays: json['inactivityReminderDays'] ?? 7,
        preferredReminderTime: json['preferredReminderTime'] ?? '08:00',
      );

  NotificationPreferences copyWith({
    bool? enableSessionCompletion,
    bool? enableStreakMilestones,
    bool? enableStreakWarnings,
    bool? enableSessionMilestones,
    bool? enablePointsMilestones,
    bool? enableMedalNotifications,
    bool? enableInactivityReminders,
    bool? enableDailyChallenges,
    bool? enableWeeklySummary,
    int? inactivityReminderDays,
    String? preferredReminderTime,
  }) =>
      NotificationPreferences(
        enableSessionCompletion: enableSessionCompletion ?? this.enableSessionCompletion,
        enableStreakMilestones: enableStreakMilestones ?? this.enableStreakMilestones,
        enableStreakWarnings: enableStreakWarnings ?? this.enableStreakWarnings,
        enableSessionMilestones: enableSessionMilestones ?? this.enableSessionMilestones,
        enablePointsMilestones: enablePointsMilestones ?? this.enablePointsMilestones,
        enableMedalNotifications: enableMedalNotifications ?? this.enableMedalNotifications,
        enableInactivityReminders: enableInactivityReminders ?? this.enableInactivityReminders,
        enableDailyChallenges: enableDailyChallenges ?? this.enableDailyChallenges,
        enableWeeklySummary: enableWeeklySummary ?? this.enableWeeklySummary,
        inactivityReminderDays: inactivityReminderDays ?? this.inactivityReminderDays,
        preferredReminderTime: preferredReminderTime ?? this.preferredReminderTime,
      );
}

/// Modelo de Notificación Programada
class ScheduledNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final bool sent;

  const ScheduledNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.sent,
  });
}
