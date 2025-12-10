import 'dart:async';
import 'package:flutter/material.dart';
import 'package:subefit/screens/exercise_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/local_data_service.dart';

enum InteractiveWorkoutPhase { start, workout, rest, results }

class ExerciseScreenInteractive extends StatefulWidget {
  final DailySession session;

  const ExerciseScreenInteractive({Key? key, required this.session})
      : super(key: key);

  @override
  State<ExerciseScreenInteractive> createState() =>
      _ExerciseScreenInteractiveState();
}

class _ExerciseScreenInteractiveState extends State<ExerciseScreenInteractive> {
  InteractiveWorkoutPhase _currentPhase = InteractiveWorkoutPhase.start;
  int _currentExerciseIndex = 0;

  Timer? _countdownTimer;
  Timer? _totalTimeTimer;

  Duration _currentCountdown = Duration.zero;
  Duration _totalTime = Duration.zero;
  int _totalPoints = 0;
  int _currentReps = 0;

  Duration _restDuration = const Duration(seconds: 20);

  ExerciseStep get _currentExercise =>
      widget.session.exercises[_currentExerciseIndex];
  ExerciseStep? get _nextExercise {
    if (_currentExerciseIndex + 1 < widget.session.exercises.length) {
      return widget.session.exercises[_currentExerciseIndex + 1];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.session.exercises.isEmpty) {
      // Handle empty session case
      Future.microtask(() => Navigator.of(context).pop());
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _totalTimeTimer?.cancel();
    super.dispose();
  }

  void _startWorkout() {
    setState(() {
      _currentPhase = InteractiveWorkoutPhase.workout;
      _totalTime = Duration.zero;
      _totalPoints = 0;
      _currentExerciseIndex = 0;
    });
    _startTotalTimer();
    _setupCurrentExercise();
  }

  void _startTotalTimer() {
    _totalTimeTimer?.cancel();
    _totalTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _totalTime += const Duration(seconds: 1);
      });
    });
  }

  void _setupCurrentExercise() {
    final exercise = _currentExercise;
    setState(() {
      _currentReps = exercise.reps ?? 0;
    });
    if (exercise.duration > Duration.zero) {
      _startCountdown(exercise.duration, _onExerciseComplete);
    } else {
      _countdownTimer?.cancel();
      setState(() {
        _currentCountdown = Duration.zero;
      });
    }
  }

  void _startCountdown(Duration duration, VoidCallback onFinish) {
    _countdownTimer?.cancel();
    setState(() {
      _currentCountdown = duration;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentCountdown.inSeconds > 0) {
        setState(() {
          _currentCountdown -= const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
        onFinish();
      }
    });
  }

  void _onExerciseComplete() {
    _countdownTimer?.cancel();
    setState(() {
      _totalPoints += _currentExercise.points;
    });

    if (_currentExerciseIndex < widget.session.exercises.length - 1) {
      setState(() {
        _currentPhase = InteractiveWorkoutPhase.rest;
      });
      _startCountdown(_restDuration, _moveToNextExercise);
    } else {
      _finishWorkout();
    }
  }

  void _moveToNextExercise() {
    _countdownTimer?.cancel();
    setState(() {
      _currentExerciseIndex++;
      _currentPhase = InteractiveWorkoutPhase.workout;
    });
    _setupCurrentExercise();
  }

  Future<void> _finishWorkout() async {
    _countdownTimer?.cancel();
    _totalTimeTimer?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final dataService = LocalDataService();
      final exerciseNames =
          widget.session.exercises.map((e) => e.name).toList();
      await dataService.updateUserWorkoutData(user.uid, _totalPoints);
      await dataService.logWorkoutInHistory(
          user.uid, _totalTime, _totalPoints, exerciseNames);
    }

    if (mounted) {
      setState(() {
        _currentPhase = InteractiveWorkoutPhase.results;
      });
    }
  }

  void _resetAndRestart() {
    setState(() {
      _currentExerciseIndex = 0;
      _totalTime = Duration.zero;
      _totalPoints = 0;
      _currentPhase = InteractiveWorkoutPhase.start;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _buildBody(),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    bool showActions = _currentPhase != InteractiveWorkoutPhase.start &&
        _currentPhase != InteractiveWorkoutPhase.results;
    return AppBar(
      title: Text(
        _currentPhase == InteractiveWorkoutPhase.start
            ? widget.session.title
            : _currentExercise.name,
      ),
      centerTitle: true,
      actions: showActions
          ? [
              IconButton(
                  icon: const Icon(Icons.pause_circle_outline),
                  onPressed: () {/* Pausar sesión */}),
              IconButton(
                  icon: const Icon(Icons.stop_circle_outlined),
                  onPressed: _finishWorkout),
            ]
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentPhase) {
      case InteractiveWorkoutPhase.start:
        return _buildStartScreen();
      case InteractiveWorkoutPhase.workout:
        return _buildWorkoutScreen();
      case InteractiveWorkoutPhase.rest:
        return _buildRestScreen();
      case InteractiveWorkoutPhase.results:
        return _buildResultsScreen();
    }
  }

  Widget _buildStartScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.session.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(widget.session.motivationalQuote,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade600)),
          const Spacer(),
          ElevatedButton(
              onPressed: _startWorkout, child: const Text('Empezar Sesión')),
        ],
      ),
    );
  }

  Widget _buildWorkoutScreen() {
    final exercise = _currentExercise;
    final isTimeBased = exercise.duration > Duration.zero;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Panel Central
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(isTimeBased ? 'TIEMPO' : 'REPETICIONES',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => setState(() => isTimeBased
                            ? _currentCountdown -= const Duration(seconds: 5)
                            : _currentReps--)),
                    Text(
                      isTimeBased
                          ? _formatDuration(_currentCountdown)
                          : '$_currentReps',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => isTimeBased
                            ? _currentCountdown += const Duration(seconds: 5)
                            : _currentReps++)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Reiniciar'),
                        onPressed: _setupCurrentExercise),
                    const SizedBox(width: 16),
                    TextButton.icon(
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text('Saltar'),
                        onPressed: _onExerciseComplete),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Botón principal de acción
        ElevatedButton(
          onPressed: _onExerciseComplete,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('HECHO', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 24),
        // Información del ejercicio
        _InfoCard(
          icon: Icons.comment_outlined,
          title: 'Consejos Técnicos',
          content: exercise.description,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.psychology_outlined,
          title: 'Motivación',
          content: '¡Siente el progreso, no el cansancio!',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatChip(
                    label: 'Músculo', value: 'Pecho')), // Dato de ejemplo
            const SizedBox(width: 12),
            Expanded(
                child: _StatChip(
                    label: 'Dificultad', value: 'Media')), // Dato de ejemplo
          ],
        ),
        const SizedBox(height: 24),
        _buildProgressFooter(),
      ],
    );
  }

  Widget _buildRestScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('DESCANSAR',
              style: TextStyle(
                  fontSize: 16, color: Colors.grey, letterSpacing: 2)),
          const SizedBox(height: 16),
          Text(
            _formatDuration(_currentCountdown),
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => setState(
                    () => _currentCountdown += const Duration(seconds: 10)),
                child: const Text('+10 seg'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _moveToNextExercise,
                child: const Text('Saltar Descanso'),
              ),
            ],
          ),
          const Spacer(),
          if (_nextExercise != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SIGUIENTE:',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(_nextExercise!.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(_nextExercise!.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          const Spacer(),
          _buildProgressFooter(),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final calories = _totalPoints * 2;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('✅\n¡Sesión Completada!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          _ResultRow(label: 'Tiempo Total', value: _formatDuration(_totalTime)),
          _ResultRow(label: 'Calorías Estimadas', value: '$calories kcal'),
          _ResultRow(label: 'Puntos Ganados', value: '$_totalPoints EXP'),
          const Spacer(),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar y Salir')),
          const SizedBox(height: 12),
          OutlinedButton(
              onPressed: _resetAndRestart, child: const Text('Repetir Sesión')),
        ],
      ),
    );
  }

  Widget _buildProgressFooter() {
    final progress =
        (_currentExerciseIndex + 1) / widget.session.exercises.length;
    final calories = _totalPoints * 2;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PROGRESO', style: Theme.of(context).textTheme.labelSmall),
            Text(
                '${(_currentExerciseIndex + 1)} de ${widget.session.exercises.length}'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tiempo Total: ${_formatDuration(_totalTime)}'),
            Text('Calorías: $calories kcal'),
          ],
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  const _InfoCard(
      {required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blueGrey.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(content, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Text(label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
