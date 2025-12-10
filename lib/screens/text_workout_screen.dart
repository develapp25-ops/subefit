import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exercise_model.dart';
import 'package:subefit/screens/local_data_service.dart';
import 'package:subefit/widgets/subefit_colors.dart';

class TextWorkoutScreen extends StatefulWidget {
  final DailySession session;
  final String planId;

  const TextWorkoutScreen({
    Key? key,
    required this.session,
    required this.planId,
  }) : super(key: key);

  @override
  State<TextWorkoutScreen> createState() => _TextWorkoutScreenState();
}

class _TextWorkoutScreenState extends State<TextWorkoutScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  late int _remainingTime;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    if (widget.session.exercises.isNotEmpty) {
      _startStep(_currentIndex);
    }
  }

  void _startStep(int index) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _remainingTime = widget.session.exercises[index].duration?.inSeconds ?? 0;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (!mounted) {
        // Verificación de seguridad
        timer.cancel();
        return;
      }

      if (_remainingTime > 0)
        setState(() => _remainingTime--);
      else
        _nextStep();
    });
  }

  void _nextStep() {
    if (_currentIndex < widget.session.exercises.length - 1) {
      _startStep(_currentIndex + 1);
    } else {
      _timer?.cancel(); // Detenemos el timer antes de finalizar
      _finishWorkout();
    }
  }

  void _togglePause() {
    if (!mounted) return;
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _finishWorkout() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await LocalDataService()
          .completeDailySession(userId, widget.planId, widget.session.day);
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¡Entrenamiento Completado!'),
          content: Text(
              '¡Felicidades! Has completado la sesión del día ${widget.session.day}.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                Navigator.of(context).pop(
                    true); // Regresa de la pantalla de entrenamiento con 'true'
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.session.title)),
        body: const Center(
            child: Text('Este es un día de descanso. ¡Disfrútalo!')),
      );
    }

    final currentStep = widget.session.exercises[_currentIndex];
    final totalSteps = widget.session.exercises.length;
    final progress = (_currentIndex + 1) / totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Barra de progreso
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paso ${_currentIndex + 1} de $totalSteps',
                        style: const TextStyle(color: Colors.grey)),
                    Text('${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),

            // Tarjeta del ejercicio
            Expanded(
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentStep.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 64, fontWeight: FontWeight.w300),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentStep.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black54, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Botones de control
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_isPaused ? 'Reanudar' : 'Pausar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _isPaused
                          ? Colors.green
                          : Colors
                              .orange), // CORREGIDO: Usando colores estándar
                ),
                OutlinedButton(
                  onPressed: _nextStep,
                  child: const Text('Saltar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
