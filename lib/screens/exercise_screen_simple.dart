import 'dart:async';
import 'package:flutter/material.dart';
import 'package:subefit/screens/exercise_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/local_data_service.dart';

enum SimpleWorkoutPhase { start, workout, rest, results }

class ExerciseScreenSimple extends StatefulWidget {
  final DailySession session;

  const ExerciseScreenSimple({Key? key, required this.session})
      : super(key: key);

  @override
  State<ExerciseScreenSimple> createState() => _ExerciseScreenSimpleState();
}

class _ExerciseScreenSimpleState extends State<ExerciseScreenSimple> {
  SimpleWorkoutPhase _currentPhase = SimpleWorkoutPhase.start;
  int _currentExerciseIndex = 0;

  // Timers
  Timer? _countdownTimer;
  Timer? _totalTimeTimer;

  // Session data
  Duration _currentCountdown = Duration.zero;
  Duration _totalTime = Duration.zero;
  int _totalPoints = 0;

  static const Duration _restDuration = Duration(seconds: 20);

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
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _totalTimeTimer?.cancel();
    super.dispose();
  }

  void _startWorkout() {
    setState(() {
      _currentPhase = SimpleWorkoutPhase.workout;
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
    if (exercise.duration > Duration.zero) {
      _startCountdown(exercise.duration, _onExerciseComplete);
    } else {
      // For rep-based exercises, no countdown. User proceeds manually.
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
    setState(() {
      _totalPoints += _currentExercise.points;
    });

    if (_currentExerciseIndex < widget.session.exercises.length - 1) {
      // More exercises left, go to rest
      setState(() {
        _currentPhase = SimpleWorkoutPhase.rest;
      });
      _startCountdown(_restDuration, _moveToNextExercise);
    } else {
      // Last exercise finished
      _finishWorkout();
    }
  }

  void _moveToNextExercise() {
    // Solución: Cancelar el temporizador de descanso actual para evitar que se ejecute de nuevo.
    _countdownTimer?.cancel();
    setState(() {
      _currentExerciseIndex++;
      _currentPhase = SimpleWorkoutPhase.workout;
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
        _currentPhase = SimpleWorkoutPhase.results;
      });
    }
  }

  void _resetAndRestart() {
    setState(() {
      _currentExerciseIndex = 0;
      _totalTime = Duration.zero;
      _totalPoints = 0;
      _currentPhase = SimpleWorkoutPhase.start;
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
      appBar: AppBar(
        title: Text(_currentPhase == SimpleWorkoutPhase.start
            ? widget.session.title
            : _currentExercise.name),
        centerTitle: true,
        actions: [
          if (_currentPhase != SimpleWorkoutPhase.start &&
              _currentPhase != SimpleWorkoutPhase.results)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Salir',
            )
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentPhase) {
      case SimpleWorkoutPhase.start:
        return _buildStartScreen();
      case SimpleWorkoutPhase.workout:
        return _buildWorkoutScreen();
      case SimpleWorkoutPhase.rest:
        return _buildRestScreen();
      case SimpleWorkoutPhase.results:
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
            onPressed: _startWorkout,
            child: const Text('Empezar Sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutScreen() {
    final exercise = _currentExercise;
    final isTimeBased = exercise.duration > Duration.zero;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Text(
            'Ejercicio ${_currentExerciseIndex + 1} de ${widget.session.exercises.length}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
          ),
          const Spacer(flex: 1),
          // Instructions
          Text(
            exercise.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          // Main Counter
          Text(
            isTimeBased
                ? _formatDuration(_currentCountdown)
                : '${exercise.reps ?? 0}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
          if (!isTimeBased)
            Text('Repeticiones',
                style: Theme.of(context).textTheme.headlineSmall),
          const Spacer(flex: 2),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onExerciseComplete,
              child: Text(isTimeBased ? 'Saltar' : 'Hecho'),
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressFooter(),
        ],
      ),
    );
  }

  Widget _buildRestScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Descanso',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(flex: 1),
          Text(
            '💪 ¡Excelente! Prepárate para el siguiente.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Text(
            _formatDuration(_currentCountdown),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: SubefitColors.secondaryOrange),
          ),
          const SizedBox(height: 12),
          if (_nextExercise != null)
            Text(
              'Siguiente: ${_nextExercise!.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _moveToNextExercise,
              child: const Text('Saltar Descanso'),
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressFooter(),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final calories = _totalPoints * 2; // Simple estimation

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
            onPressed: () =>
                Navigator.of(context).pop(true), // Pop and indicate success
            child: const Text('Guardar y Salir'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _resetAndRestart,
            child: const Text('Repetir Sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressFooter() {
    final progress =
        (_currentExerciseIndex + 1) / widget.session.exercises.length;
    final calories = _totalPoints * 2; // Simple estimation

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tiempo: ${_formatDuration(_totalTime)}'),
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
