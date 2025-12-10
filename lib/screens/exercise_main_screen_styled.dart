import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:subefit/screens/exercise_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:subefit/screens/local_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

/// Enum para controlar el estado general de la sesión de entrenamiento.
import 'tts_service.dart';

enum SessionState {
  initial, // Antes de que la sesión comience
  running, // Sesión activa, realizando un ejercicio
  paused, // Sesión pausada por el usuario
  resting, // En período de descanso entre sets o ejercicios
  completed, // Sesión finalizada
}

class ExerciseMainScreenStyled extends StatefulWidget {
  final DailySession session;
  final String?
      planId; // Opcional: si esta sesión es parte de un plan de entrenamiento

  const ExerciseMainScreenStyled({
    Key? key,
    required this.session,
    this.planId,
  }) : super(key: key);

  @override
  State<ExerciseMainScreenStyled> createState() =>
      _ExerciseMainScreenStyledState();
}

class _ExerciseMainScreenStyledState extends State<ExerciseMainScreenStyled> {
  SessionState _sessionState = SessionState.initial;
  int _currentExerciseIndex = 0;
  int _currentSet = 1; // Para ejercicios basados en repeticiones/sets

  // Servicio de Texto a Voz
  final TtsService _ttsService = TtsService();

  // Temporizadores
  Timer? _globalTimer;
  Duration _elapsedGlobalTime = Duration.zero;
  DateTime? _sessionStartTime; // Para registrar el inicio real de la sesión

  Timer? _restTimer;
  Duration _elapsedRestTime = Duration.zero;
  final Duration _defaultRestDuration =
      const Duration(seconds: 45); // Tiempo de descanso predeterminado

  // Estadísticas de la sesión
  int _exercisesCompletedCount = 0;
  int _totalSetsCompleted = 0;
  int _totalRepsCompleted = 0;
  double _estimatedCalories = 0.0; // Estimación de calorías (simplificada)
  double _userWeight =
      70.0; // Peso del usuario, cargado desde LocalDataService para cálculo de calorías

  // Detección de inactividad (para futuras funciones de IA)
  Timer? _inactivityTimer;
  final Duration _inactivityThreshold = const Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _checkForInterruptedSession();
    _loadUserWeight();
  }

  /// Carga el peso del usuario desde el servicio de datos local.
  Future<void> _loadUserWeight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await LocalDataService().loadUserData(user.uid);
      if (mounted)
        setState(
            () => _userWeight = (data['weight'] as num?)?.toDouble() ?? 70.0);
    }
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _ttsService.stop();
    _restTimer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // --- Gestión de Sesión Interrumpida ---

  /// Comprueba si existe una sesión interrumpida y pregunta al usuario si desea continuar.
  Future<void> _checkForInterruptedSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final savedState =
        await LocalDataService().loadInterruptedSession(user.uid);
    if (savedState != null && savedState['sessionId'] == widget.session.title) {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Sesión en Progreso'),
          content: const Text(
              'Detectamos una sesión sin terminar. ¿Deseas continuar desde donde la dejaste?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                LocalDataService().clearInterruptedSession(
                    user.uid); // Limpia la sesión guardada
              },
              child: const Text('Empezar de Nuevo'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restoreSessionState(savedState);
                _ttsService.speak('Retomamos desde donde lo dejaste. ¡Vamos!');
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }
  }

  /// Guarda el estado actual de la sesión para poder reanudarla más tarde.
  Future<void> _saveSessionState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _sessionState == SessionState.initial ||
        _sessionState == SessionState.completed) return;

    final state = {
      'sessionId': widget.session.title,
      'sessionState': _sessionState.index,
      'currentExerciseIndex': _currentExerciseIndex,
      'currentSet': _currentSet,
      'elapsedGlobalTimeSeconds': _elapsedGlobalTime.inSeconds,
      'sessionStartTime': _sessionStartTime?.toIso8601String(),
      'elapsedRestTimeSeconds': _elapsedRestTime.inSeconds,
      'exercisesCompletedCount': _exercisesCompletedCount,
      'totalSetsCompleted': _totalSetsCompleted,
      'totalRepsCompleted': _totalRepsCompleted,
      'estimatedCalories': _estimatedCalories,
    };
    await LocalDataService().saveInterruptedSession(user.uid, state);
  }

  /// Restaura el estado de la sesión desde un mapa de datos guardado.
  void _restoreSessionState(Map<String, dynamic> savedState) {
    setState(() {
      _sessionState = SessionState.values[savedState['sessionState'] ?? 0];
      _currentExerciseIndex = savedState['currentExerciseIndex'] ?? 0;
      _currentSet = savedState['currentSet'] ?? 1;

      // Restaura el tiempo global
      final startTimeStr = savedState['sessionStartTime'] as String?;
      if (startTimeStr != null) {
        _sessionStartTime = DateTime.tryParse(startTimeStr);
        _elapsedGlobalTime = DateTime.now().difference(_sessionStartTime!);
      } else {
        _elapsedGlobalTime =
            Duration(seconds: savedState['elapsedGlobalTimeSeconds'] ?? 0);
      }

      _elapsedRestTime =
          Duration(seconds: savedState['elapsedRestTimeSeconds'] ?? 0);

      // Restaura estadísticas
      _exercisesCompletedCount = savedState['exercisesCompletedCount'] ?? 0;
      _totalSetsCompleted = savedState['totalSetsCompleted'] ?? 0;
      _totalRepsCompleted = savedState['totalRepsCompleted'] ?? 0;
      _estimatedCalories =
          (savedState['estimatedCalories'] as num?)?.toDouble() ?? 0.0;
    });

    // Reanuda los temporizadores según el estado restaurado
    if (_sessionState == SessionState.running ||
        _sessionState == SessionState.resting) {
      _startGlobalTimer();
    }
    if (_sessionState == SessionState.resting &&
        _elapsedRestTime.inSeconds > 0) {
      _startRestTimer();
    } else if (_sessionState == SessionState.resting) {
      // Si el tiempo de descanso era 0, pasa al siguiente ejercicio
      _moveToNextExercise();
    }
  }

  // --- Gestión de Temporizadores ---

  /// Inicia el temporizador global de la sesión.
  void _startGlobalTimer() {
    _sessionStartTime ??=
        DateTime.now(); // Establece la hora de inicio solo una vez
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionState == SessionState.running ||
          _sessionState == SessionState.resting) {
        setState(() {
          _elapsedGlobalTime = DateTime.now().difference(_sessionStartTime!);
        });
      }
    });
    _resetInactivityTimer();
  }

  /// Pausa el temporizador global.
  void _pauseGlobalTimer() {
    _globalTimer?.cancel();
    _inactivityTimer
        ?.cancel(); // También cancela el temporizador de inactividad
  }

  /// Inicia el temporizador de descanso.
  void _startRestTimer() {
    _restTimer
        ?.cancel(); // Cancela cualquier temporizador de descanso existente
    _elapsedRestTime =
        _defaultRestDuration; // Inicia desde la duración de descanso predeterminada
    _sessionState = SessionState.resting;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_elapsedRestTime.inSeconds > 0) {
        setState(() {
          // Anuncio de cuenta regresiva
          if (_elapsedRestTime.inSeconds == 10) {
            _ttsService.speak('10 segundos para el siguiente ejercicio.');
          }
          _elapsedRestTime = _elapsedRestTime - const Duration(seconds: 1);
        });
      } else {
        _restTimer?.cancel();
        _moveToNextExercise(); // Pasa al siguiente ejercicio cuando termina el descanso
      }
    });
    _resetInactivityTimer();
  }

  /// Pausa el temporizador de descanso.
  void _pauseRestTimer() {
    _restTimer?.cancel();
  }

  /// Reinicia el temporizador de inactividad.
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityThreshold, () {
      if (_sessionState == SessionState.running ||
          _sessionState == SessionState.resting) {
        _pauseSession(); // Pausa automáticamente si hay inactividad
        _showInactivityPrompt(); // Muestra un mensaje al usuario
      }
    });
  }

  /// Muestra un diálogo al usuario cuando se detecta inactividad.
  void _showInactivityPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Deseas pausar la sesión?'),
        content: const Text('Parece que has estado inactivo por un tiempo.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeSession(); // Reanuda si el usuario descarta el diálogo
            },
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // La sesión ya está pausada por _pauseSession()
            },
            child: const Text('Pausar'),
          ),
        ],
      ),
    );
  }

  // --- Control de Sesión ---

  /// Inicia la sesión de entrenamiento.
  void _startSession() {
    setState(() {
      _sessionState = SessionState.running;
      _currentExerciseIndex = 0;
      _currentSet = 1;
      _exercisesCompletedCount = 0;
      _totalSetsCompleted = 0;
      _totalRepsCompleted = 0;
      _estimatedCalories = 0.0;
      _elapsedGlobalTime = Duration.zero;
      _sessionStartTime = DateTime.now();
    });
    _startGlobalTimer();

    // --- VOZ IA INICIAL ---
    final firstExercise = widget.session.exercises.first;
    _ttsService.speak(
        'Comencemos tu entrenamiento. Tienes ${widget.session.exercises.length} ejercicios en total. Empezaremos con ${firstExercise.name}. Prepara tu posición.');
    _speakExerciseInstructions(firstExercise);

    _saveSessionState();
  }

  /// Pausa la sesión de entrenamiento.
  void _pauseSession() {
    setState(() {
      _sessionState = SessionState.paused;
    });
    _pauseGlobalTimer();
    _pauseRestTimer();
    _ttsService.stop();
    _saveSessionState();
  }

  /// Reanuda la sesión de entrenamiento.
  void _resumeSession() {
    setState(() {
      _sessionState = SessionState.running;
    });
    _startGlobalTimer();
    // Si estaba en descanso y aún queda tiempo, reanuda el descanso
    if (_elapsedRestTime.inSeconds > 0 &&
        _currentExerciseIndex < widget.session.exercises.length) {
      _startRestTimer();
    }
    _saveSessionState();
  }

  /// Marca el ejercicio actual (o set) como completado.
  void _completeExercise() {
    final currentExercise = widget.session.exercises[_currentExerciseIndex];
    _resetInactivityTimer(); // Reinicia el timer con cada acción
    // Actualiza las estadísticas para el set/duración completado
    _totalSetsCompleted++; // Un set (o un ejercicio cronometrado) se considera completado
    _totalRepsCompleted += (int.tryParse(currentExercise.reps ?? '0') ??
        0); // Añade repeticiones si aplica

    // Estimación simple de calorías (muy básica, necesita mejora para precisión)
    // METs * peso (kg) * duración (horas)
    // Asumiendo un valor MET promedio para ejercicio general (ej. 5 METs)
    final met = 5.0;
    final exerciseDuration = currentExercise.duration?.inSeconds.toDouble() ??
        45.0; // Por defecto 45s si es por repeticiones
    _estimatedCalories += (met * _userWeight * (exerciseDuration / 3600));

    // Comprueba si hay más sets para el ejercicio actual o si se pasa al siguiente ejercicio
    if (currentExercise.sets > 1 && _currentSet < currentExercise.sets) {
      setState(() {
        _currentSet++;
      });
      // --- VOZ IA: ANUNCIO DE DESCANSO ENTRE SERIES ---
      _ttsService.speak(
          'Serie completada. Descansa ${_defaultRestDuration.inSeconds} segundos.');
      _startRestTimer(); // Inicia el descanso después de un set
    } else {
      // Todos los sets para este ejercicio están hechos, pasa al siguiente ejercicio
      _exercisesCompletedCount++; // Incrementa el contador de ejercicios únicos completados

      // --- VOZ IA: ANUNCIO DE EJERCICIO COMPLETADO ---
      _ttsService.speak('¡Excelente trabajo! Ejercicio completado.');
      _moveToNextExercise();
    }
    _saveSessionState();
  }

  /// Reinicia el ejercicio actual (vuelve al primer set).
  void _repeatExercise() {
    setState(() {
      _currentSet = 1;
    });
    _resetInactivityTimer();
  }

  /// Salta al siguiente ejercicio de la lista.
  void _skipExercise() {
    _resetInactivityTimer();
    _moveToNextExercise();
  }

  /// Avanza al siguiente ejercicio o finaliza la sesión si no hay más.
  void _moveToNextExercise() {
    _elapsedRestTime = Duration.zero; // Reinicia el tiempo de descanso

    if (_currentExerciseIndex < widget.session.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1; // Reinicia el set para el nuevo ejercicio
        _sessionState = SessionState
            .running; // Asegura que el estado sea 'running' después del descanso
        _restTimer?.cancel(); // Detiene el timer de descanso al moverse

        // --- VOZ IA: ANUNCIO Y DESCRIPCIÓN DEL NUEVO EJERCICIO ---
        final newExercise = widget.session.exercises[_currentExerciseIndex];
        _ttsService.speak('Pasamos al siguiente: ${newExercise.name}.');
        _speakExerciseInstructions(newExercise);
      });
    } else {
      _finishSession(); // Todos los ejercicios completados
    }
    _saveSessionState();
  }

  /// La IA describe el ejercicio actual.
  void _speakExerciseInstructions(ExerciseStep exercise) {
    String instruction = '';
    if (exercise.reps != null) {
      instruction =
          'Vamos a hacer ${exercise.sets} series de ${exercise.reps} repeticiones. ${exercise.description}';
    } else if (exercise.duration != null) {
      instruction =
          'Este ejercicio es por tiempo: ${exercise.duration!.inSeconds} segundos. ${exercise.description}';
    }
    _ttsService.speak(instruction);
  }

  /// Salta el período de descanso actual.
  void _skipRest() {
    _resetInactivityTimer();
    _restTimer?.cancel();
    _moveToNextExercise();
  }

  /// Finaliza la sesión de entrenamiento, guarda los datos y muestra el resumen.
  Future<void> _finishSession() async {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    _inactivityTimer?.cancel();

    setState(() {
      _sessionState = SessionState.completed;
    });

    // --- VOZ IA: RESUMEN FINAL ---
    final durationMinutes = _elapsedGlobalTime.inMinutes;
    final summarySpeech =
        'Entrenamiento completado. Duración: $durationMinutes minutos. Completaste $_exercisesCompletedCount ejercicios y $_totalSetsCompleted series totales. ¡Excelente progreso!';
    _ttsService.speak(summarySpeech);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Cálculo de puntos de ejemplo (puedes ajustar esta lógica)
      final pointsEarned = (_exercisesCompletedCount * 10) +
          (_totalRepsCompleted ~/ 5) +
          (_totalSetsCompleted * 2);
      await LocalDataService().logWorkoutInHistory(
        user.uid,
        _elapsedGlobalTime,
        pointsEarned,
        widget.session.exercises.map((e) => e.name).toList(),
        _sessionStartTime,
      );
      await LocalDataService().updateUserWorkoutData(user.uid, pointsEarned);

      // Si es parte de un plan, marca la sesión diaria como completada
      if (widget.planId != null) {
        await LocalDataService()
            .completeDailySession(user.uid, widget.planId!, widget.session.day);
      }

      // Limpia la sesión interrumpida guardada, ya que esta se ha completado.
      await LocalDataService().clearInterruptedSession(user.uid);
    }
  }

  // --- Constructores de UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Si la sesión está en curso o pausada, pide confirmación antes de salir
            if (_sessionState != SessionState.initial &&
                _sessionState != SessionState.completed) {
              _showExitConfirmationDialog();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          // Botón para activar/desactivar la voz
          IconButton(
            icon: Icon(_ttsService.isVoiceEnabled
                ? Icons.volume_up_outlined
                : Icons.volume_off_outlined),
            tooltip:
                _ttsService.isVoiceEnabled ? 'Silenciar guía' : 'Activar guía',
            onPressed: () {
              setState(() {
                _ttsService.toggleVoice(!_ttsService.isVoiceEnabled);
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Construye el cuerpo de la pantalla según el estado actual de la sesión.
  Widget _buildBody() {
    switch (_sessionState) {
      case SessionState.initial:
        return _buildInitialScreen();
      case SessionState.running:
        return _buildRunningScreen();
      case SessionState.paused:
        return _buildPausedScreen();
      case SessionState.resting:
        return _buildRestingScreen();
      case SessionState.completed:
        return _buildCompletedScreen();
    }
  }

  /// Pantalla inicial antes de comenzar el entrenamiento.
  Widget _buildInitialScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.session.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.session.motivationalQuote,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ejercicios: ${widget.session.exercises.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duración estimada: ~${_calculateEstimatedDuration().inMinutes} min',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: widget.session.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.session.exercises[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: SubefitColors.primaryRed.withOpacity(0.1),
                    child: Text('${index + 1}',
                        style:
                            const TextStyle(color: SubefitColors.primaryRed)),
                  ),
                  title: Text(exercise.name),
                  subtitle: Text(exercise.description),
                  trailing: Text(exercise.displayDurationOrReps()),
                );
              },
            ),
          ),
          ElevatedButton.icon(
            onPressed: _startSession,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Comenzar Sesión'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: SubefitColors.primaryRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Pantalla principal durante la ejecución del entrenamiento.
  Widget _buildRunningScreen() {
    final currentExercise = widget.session.exercises[_currentExerciseIndex];
    final totalExercises = widget.session.exercises.length;
    final progress = (_exercisesCompletedCount) / totalExercises;

    // CORRECCIÓN: Se usa un ListView para evitar errores de desbordamiento (lona amarilla y negra)
    // en pantallas pequeñas, permitiendo el scroll si el contenido es muy alto.
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildGlobalTimer(),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                    SubefitColors.primaryRed),
              ),
              const SizedBox(height: 8),
              Text(
                'Progreso: $_exercisesCompletedCount de $totalExercises (${(progress * 100).toInt()}%)',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  currentExercise.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 16),
                if (currentExercise.type != null) ...[
                  Text(
                    currentExercise.type!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  currentExercise.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[800]),
                ),
                const SizedBox(height: 24),
                if (currentExercise.reps != null)
                  Text(
                    'Serie $_currentSet de ${currentExercise.sets} | ${currentExercise.reps} repeticiones',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  )
                else if (currentExercise.duration != null)
                  Text(
                    'Tiempo estimado: ${currentExercise.duration!.inSeconds} segundos',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                // CORRECCIÓN: Se elimina el Spacer y se usa un SizedBox para evitar errores de overflow.
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _completeExercise,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Completado'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: SubefitColors.primaryRed,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _repeatExercise,
                        icon: const Icon(Icons.replay),
                        label: const Text('Repetir'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          foregroundColor: SubefitColors.primaryRed,
                          side:
                              const BorderSide(color: SubefitColors.primaryRed),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _skipExercise,
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Saltar'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          foregroundColor: SubefitColors.darkGrey,
                          side: BorderSide(color: Colors.grey.shade400),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildBottomControlButtons(),
      ],
    );
  }

  /// Pantalla que se muestra durante el período de descanso.
  Widget _buildRestingScreen() {
    final nextExercise =
        _currentExerciseIndex + 1 < widget.session.exercises.length
            ? widget.session.exercises[_currentExerciseIndex + 1]
            : null;

    // CORRECCIÓN: Se usa un ListView para evitar errores de desbordamiento.
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildGlobalTimer(),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '¡Tiempo de Descanso!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_elapsedRestTime.inSeconds}s',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: SubefitColors.primaryRed),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Descansá y preparate para el siguiente ejercicio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                // CORRECCIÓN: Se elimina el Spacer y se usa un SizedBox.
                const SizedBox(height: 24),
                if (nextExercise != null) ...[
                  const Text(
                    'Próximo ejercicio:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextExercise.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    nextExercise.displayDurationOrReps(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24), // Espacio antes del botón
                ],
                ElevatedButton.icon(
                  onPressed: _skipRest,
                  icon: const Icon(Icons.fast_forward),
                  label: const Text('Saltar Descanso'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: SubefitColors.darkGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomControlButtons(),
      ],
    );
  }

  /// Pantalla que se muestra cuando la sesión está pausada.
  Widget _buildPausedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pause_circle_filled,
              size: 100, color: SubefitColors.primaryRed),
          const SizedBox(height: 24),
          const Text(
            'Sesión Pausada',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Tiempo transcurrido: ${_formatDuration(_elapsedGlobalTime)}',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _resumeSession,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Reanudar Sesión'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 60),
              backgroundColor: SubefitColors.primaryRed,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showExitConfirmationDialog,
            icon: const Icon(Icons.stop),
            label: const Text('Finalizar Sesión'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(200, 50),
              foregroundColor: SubefitColors.darkGrey,
              side: BorderSide(color: Colors.grey.shade400),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// Pantalla de resumen que se muestra al finalizar el entrenamiento.
  Widget _buildCompletedScreen() {
    final totalExercises = widget.session.exercises.length;
    // Cálculo de puntos de ejemplo (debe coincidir con la lógica en _finishSession)
    final pointsEarned = (_exercisesCompletedCount * 10) +
        (_totalRepsCompleted ~/ 5) +
        (_totalSetsCompleted * 2);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 80, color: SubefitColors.primaryRed),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Entrenamiento completado! ✅',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryRow(
                      'Duración total:', _formatDuration(_elapsedGlobalTime)),
                  _buildSummaryRow('Ejercicios completados:',
                      '$_exercisesCompletedCount de $totalExercises'),
                  _buildSummaryRow('Series totales:', '$_totalSetsCompleted'),
                  _buildSummaryRow(
                      'Repeticiones totales:', '$_totalRepsCompleted'),
                  _buildSummaryRow('Calorías estimadas:',
                      '${_estimatedCalories.toStringAsFixed(0)} kcal'),
                  _buildSummaryRow('Puntos ganados:', '$pointsEarned pts'),
                  _buildSummaryRow(
                      'Fecha y hora:',
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(_sessionStartTime ?? DateTime.now())),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Botón "Repetir entrenamiento"
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra la pantalla de resumen
              // Navega de nuevo a la pantalla de sesión con la misma rutina para repetirla
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => ExerciseMainScreenStyled(
                    session: widget.session, planId: widget.planId),
              ));
            },
            icon: const Icon(Icons.replay),
            label: const Text('Repetir Entrenamiento'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor:
                  SubefitColors.darkGrey, // Un color diferente para destacar
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // CORREGIDO: Navega a la pantalla de inicio (dashboard) y elimina todas las rutas anteriores.
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/dashboard', (route) => false);
            },
            icon: const Icon(Icons.home), // Icono más genérico para "volver"
            label: const Text('Volver al Inicio'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: SubefitColors.primaryRed,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra la pantalla de resumen
              // TODO: Implementar navegación a la pantalla de historial si existe
            },
            icon: const Icon(Icons.history),
            label: const Text('Ver Historial'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: SubefitColors.darkGrey,
              side: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar el temporizador global.
  Widget _buildGlobalTimer() {
    return Text(
      'Tiempo total: ${_formatDuration(_elapsedGlobalTime)}',
      style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: SubefitColors.darkGrey),
    );
  }

  /// Botones de control inferiores (Pausar y Finalizar).
  Widget _buildBottomControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _pauseSession,
              icon: const Icon(Icons.pause),
              label: const Text('Pausar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SubefitColors.darkGrey,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showExitConfirmationDialog,
              icon: const Icon(Icons.stop),
              label: const Text('Finalizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SubefitColors.dangerRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fila para mostrar un dato en el resumen final.
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Formatea una duración a un string HH:MM:SS o MM:SS.
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  /// Calcula la duración estimada total del entrenamiento.
  Duration _calculateEstimatedDuration() {
    Duration total = Duration.zero;
    for (var exercise in widget.session.exercises) {
      total += exercise.duration ??
          const Duration(
              seconds:
                  45); // Por defecto 45s por ejercicio si es por repeticiones
      if (exercise.sets > 1) {
        total += _defaultRestDuration *
            (exercise.sets - 1); // Añade descanso entre sets
      }
    }
    return total;
  }

  /// Muestra un diálogo de confirmación antes de finalizar la sesión.
  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Finalizar sesión?'),
        content:
            const Text('Si finalizas ahora, el progreso actual se guardará.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
              _finishSession();
            },
            child: const Text('Finalizar',
                style: TextStyle(color: SubefitColors.dangerRed)),
          ),
        ],
      ),
    );
  }
}
