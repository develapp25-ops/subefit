import 'package:flutter/material.dart';
import 'predefined_sessions.dart';
import 'exercise_model.dart';

/// Pantalla que muestra y selecciona sesiones de entrenamiento predefinidas
class PredefinedSessionsScreen extends StatefulWidget {
  final Function(DailySession)? onSessionSelected;

  const PredefinedSessionsScreen({
    Key? key,
    this.onSessionSelected,
  }) : super(key: key);

  @override
  State<PredefinedSessionsScreen> createState() =>
      _PredefinedSessionsScreenState();
}

class _PredefinedSessionsScreenState extends State<PredefinedSessionsScreen> {
  late int _selectedSessionIndex;

  @override
  void initState() {
    super.initState();
    _selectedSessionIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesiones Predefinidas'),
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allSessions.length,
              itemBuilder: (context, index) {
                final session = allSessions[index];
                final isSelected = _selectedSessionIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSessionIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD32F2F)
                            : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? const Color(0xFFD32F2F).withValues(alpha: 0.1)
                          : Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Día ${session.day}: ${session.title}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFFD32F2F)
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            session.motivationalQuote,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${session.exercises.length} ejercicios',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: session.exercises
                                .take(3)
                                .map((exercise) => SizedBox(
                                      height: 32,
                                      child: Chip(
                                        label: Text(
                                          exercise.name.length > 15
                                              ? '${exercise.name.substring(0, 15)}...'
                                              : exercise.name,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.grey[200],
                                      ),
                                    ))
                                .toList(),
                          ),
                          if (session.exercises.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+${session.exercises.length - 3} más',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSessionSelected?.call(allSessions[_selectedSessionIndex]);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Comenzar Sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que muestra detalles de una sesión individual
class SessionDetailWidget extends StatelessWidget {
  final DailySession session;

  const SessionDetailWidget({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int totalDurationSeconds = 0;
    int totalPoints = 0;

    for (final exercise in session.exercises) {
      if (exercise.duration != null) {
        totalDurationSeconds += exercise.duration!.inSeconds;
      }
      totalPoints += exercise.points;
    }

    final totalDurationMinutes = (totalDurationSeconds / 60).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              session.motivationalQuote,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatisticCard(
                  label: 'Duración',
                  value: '${totalDurationMinutes} min',
                ),
                _StatisticCard(
                  label: 'Ejercicios',
                  value: '${session.exercises.length}',
                ),
                _StatisticCard(
                  label: 'Puntos',
                  value: '$totalPoints',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Ejercicios:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: session.exercises.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final exercise = session.exercises[index];
                return _ExerciseListItem(exercise: exercise);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatisticCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD32F2F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ExerciseListItem extends StatelessWidget {
  final ExerciseStep exercise;

  const _ExerciseListItem({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exercise.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (exercise.duration != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '⏱ ${exercise.duration!.inSeconds}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              if (exercise.sets > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${exercise.sets} set${exercise.sets > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
