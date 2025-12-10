import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'exercise_model.dart';
import 'local_data_service.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'exercise_main_screen_styled.dart'; // CORREGIDO: Importamos la pantalla de entrenamiento interactiva

class PlanProgressionScreen extends StatefulWidget {
  final TrainingPlan plan;

  const PlanProgressionScreen({Key? key, required this.plan}) : super(key: key);

  @override
  State<PlanProgressionScreen> createState() => _PlanProgressionScreenState();
}

class _PlanProgressionScreenState extends State<PlanProgressionScreen> {
  // Flag para desarrollo: si es true, no hay espera de 24h.
  static const bool _isDevelopmentMode = true;

  late Future<Map<String, dynamic>?> _progressFuture;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadProgress();
  }

  void _loadProgress() {
    _progressFuture = _userId != null
        ? LocalDataService().getPlanProgress(_userId!, widget.plan.id)
        : Future.value(null);
  }

  Future<void> _startSession(DailySession session) async {
    final result = await Navigator.of(context).push<bool>(
      // CORREGIDO: Navegamos a la pantalla de entrenamiento principal y estilizada
      MaterialPageRoute(
        builder: (_) => ExerciseMainScreenStyled(
          session: session,
          planId: widget.plan.id,
        ),
      ),
    );

    // Si el entrenamiento fue completado (devuelve true)
    if (result == true) {
      // Recargamos el progreso para actualizar la UI
      setState(_loadProgress);
    }
  }

  ({DayStatus status, String? availabilityMessage}) _calculateDayStatus({
    required int day,
    required int lastCompletedDay,
    required String? lastCompletedTimestamp,
  }) {
    if (day <= lastCompletedDay) {
      return (status: DayStatus.completed, availabilityMessage: null);
    }
    if (day == lastCompletedDay + 1) {
      if (_isDevelopmentMode || lastCompletedTimestamp == null) {
        return (status: DayStatus.available, availabilityMessage: null);
      }
      final lastDate = DateTime.parse(lastCompletedTimestamp);
      final nextAvailableDate = lastDate.add(const Duration(hours: 24));
      if (DateTime.now().isAfter(nextAvailableDate)) {
        return (status: DayStatus.available, availabilityMessage: null);
      } else {
        final message =
            'Disponible mañana a las ${DateFormat.jm('es').format(nextAvailableDate)}';
        return (
          status: DayStatus.lockedUntilTomorrow,
          availabilityMessage: message
        );
      }
    }
    return (status: DayStatus.locked, availabilityMessage: null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.title),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar el progreso: ${snapshot.error}'));
          }

          final planProgress = snapshot.data ?? {};

          final lastCompletedDay =
              planProgress['lastCompletedDay'] as int? ?? 0;
          final totalDays = widget.plan.dailySessions.length;

          return Column(
            children: [
              _buildProgressHeader(lastCompletedDay, totalDays),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: widget.plan.dailySessions.length,
                  itemBuilder: (context, index) {
                    final session = widget.plan.dailySessions[index];
                    final day = session.day;
                    final lastCompletedTimestamp =
                        planProgress['lastCompletedTimestamp'] as String?;

                    final result = _calculateDayStatus(
                      day: day,
                      lastCompletedDay: lastCompletedDay,
                      lastCompletedTimestamp: lastCompletedTimestamp,
                    );

                    return _DayCard(
                      session: session,
                      status: result.status,
                      availabilityMessage: result.availabilityMessage,
                      onTap: result.status == DayStatus.available
                          ? () => _startSession(session)
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(int completedDays, int totalDays) {
    final progress = totalDays > 0 ? completedDays / totalDays : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.plan.description,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progreso',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
              Text('$completedDays / $totalDays Días',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}

enum DayStatus { available, completed, locked, lockedUntilTomorrow }

class _DayCard extends StatelessWidget {
  final DailySession session;
  final DayStatus status;
  final String? availabilityMessage;
  final VoidCallback? onTap;

  const _DayCard({
    required this.session,
    required this.status,
    this.availabilityMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = status == DayStatus.available;
    final bool isRestDay = session.exercises.isEmpty;

    IconData iconData;
    Color iconColor;
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade200;

    switch (status) {
      case DayStatus.available:
        iconData = isRestDay ? Icons.bedtime_outlined : Icons.play_arrow;
        iconColor = Colors.white;
        cardColor = Theme.of(context).colorScheme.primary;
        borderColor = Theme.of(context).colorScheme.primary;
        break;
      case DayStatus.completed:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case DayStatus.lockedUntilTomorrow:
        iconData = Icons.timer_outlined;
        iconColor = Colors.orange;
        break;
      case DayStatus.locked:
      default:
        iconData = Icons.lock;
        iconColor = Colors.grey.shade400;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isAvailable ? 4 : 1,
      shadowColor: isAvailable
          ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
          : Colors.black12,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: isAvailable
              ? Colors.white.withOpacity(0.2)
              : iconColor.withOpacity(0.1),
          child: Icon(iconData, color: isAvailable ? Colors.white : iconColor),
        ),
        title: Text(
          'Día ${session.day} - Semana ${((session.day - 1) / 7).floor() + 1}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAvailable ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          session.title,
          style: TextStyle(
              color:
                  isAvailable ? Colors.white.withOpacity(0.9) : Colors.black54),
        ),
        trailing: onTap != null
            ? Icon(Icons.chevron_right,
                color: isAvailable ? Colors.white : Colors.grey)
            : null,
        enabled: onTap != null,
      ),
    );
  }
}
