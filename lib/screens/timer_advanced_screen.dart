import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'local_data_service.dart';

// Modelos para los modos de entrenamiento
enum TimerMode { stopwatch, tabata, hiit, pomodoro, custom }

class TimerPreset {
  final TimerMode mode;
  final String name;
  final String description;
  final int workDurationSec;
  final int restDurationSec;
  final int cycles;
  final IconData icon;

  const TimerPreset({
    required this.mode,
    required this.name,
    required this.description,
    required this.workDurationSec,
    required this.restDurationSec,
    required this.cycles,
    required this.icon,
  });

  /// Calcula el tiempo total del entrenamiento en segundos
  int getTotalDuration() {
    if (mode == TimerMode.stopwatch) return 0;
    final cycleDuration = workDurationSec + restDurationSec;
    return cycleDuration * cycles;
  }
}

// Presets predefinidos
const kTabataPreset = TimerPreset(
  mode: TimerMode.tabata,
  name: 'Tabata',
  description: '20s trabajo / 10s descanso x 8',
  workDurationSec: 20,
  restDurationSec: 10,
  cycles: 8,
  icon: Icons.fire_truck_outlined,
);

const kHIITPreset = TimerPreset(
  mode: TimerMode.hiit,
  name: 'HIIT',
  description: '30s trabajo / 30s descanso x 10',
  workDurationSec: 30,
  restDurationSec: 30,
  cycles: 10,
  icon: Icons.flash_on_outlined,
);

const kPomodoroPreset = TimerPreset(
  mode: TimerMode.pomodoro,
  name: 'Pomodoro Fitness',
  description: '25 min trabajo / 5 min descanso',
  workDurationSec: 1500,
  restDurationSec: 300,
  cycles: 1,
  icon: Icons.schedule_outlined,
);

class TimerAdvancedScreen extends StatefulWidget {
  final TimerPreset? initialPreset;

  const TimerAdvancedScreen({Key? key, this.initialPreset}) : super(key: key);

  @override
  State<TimerAdvancedScreen> createState() => _TimerAdvancedScreenState();
}

class _TimerAdvancedScreenState extends State<TimerAdvancedScreen>
    with WidgetsBindingObserver {
  late TimerPreset _currentPreset;
  late Timer _timer;
  final FlutterTts _tts = FlutterTts();

  // Estado del cronómetro
  int _currentSeconds = 0;
  int _currentCycle = 1;
  bool _isRunning = false;
  bool _isWorkPhase = true; // true: trabajo, false: descanso
  int _completedCycles = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPreset = widget.initialPreset ?? kTabataPreset;
    _currentSeconds = _currentPreset.workDurationSec;
    _setupTts();
    _restoreState();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _saveState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveState();
    } else if (state == AppLifecycleState.resumed) {
      _restoreState();
    }
  }

  Future<void> _saveState() async {
    try {
      final data = {
        'mode': _currentPreset.mode.toString(),
        'currentSeconds': _currentSeconds,
        'currentCycle': _currentCycle,
        'isRunning': _isRunning,
        'isWorkPhase': _isWorkPhase,
        'completedCycles': _completedCycles,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await LocalDataService().writeJsonFile('timer_state.json', data);
    } catch (e) {
      debugPrint('Error saving timer state: $e');
    }
  }

  Future<void> _restoreState() async {
    try {
      final data = await LocalDataService().readJsonFile('timer_state.json');
      if (data.isEmpty) return;
      final savedAt = (data['savedAt'] as num?)?.toInt() ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final isRunning = data['isRunning'] as bool? ?? false;

      var currentSeconds = (data['currentSeconds'] as num?)?.toInt() ?? _currentPreset.workDurationSec;

      // Si estaba corriendo, restar tiempo transcurrido
      if (isRunning && savedAt > 0) {
        final elapsed = (now - savedAt) ~/ 1000;
        currentSeconds = (currentSeconds - elapsed).clamp(0, currentSeconds);
      }

      setState(() {
        _currentSeconds = currentSeconds;
        _currentCycle = (data['currentCycle'] as num?)?.toInt() ?? 1;
        _isWorkPhase = data['isWorkPhase'] as bool? ?? true;
        _completedCycles = (data['completedCycles'] as num?)?.toInt() ?? 0;

        if (isRunning && currentSeconds > 0) {
          _startTimer();
        }
      });
    } catch (e) {
      debugPrint('Error restoring timer state: $e');
    }
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        setState(() => _currentSeconds--);

        // Anuncio final (últimos 3 segundos)
        if (_currentSeconds <= 3 && _currentSeconds > 0) {
          _speak('$_currentSeconds segundos');
        }
      } else {
        // Fin de la fase actual
        _handlePhaseComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer.cancel();
    setState(() {
      _currentSeconds = _currentPreset.workDurationSec;
      _currentCycle = 1;
      _isRunning = false;
      _isWorkPhase = true;
      _completedCycles = 0;
    });
    _saveState();
  }

  void _handlePhaseComplete() {
    if (_isWorkPhase) {
      // Completó la fase de trabajo
      _speak('Descanso');
      setState(() {
        _isWorkPhase = false;
        _currentSeconds = _currentPreset.restDurationSec;
      });
      Future.delayed(const Duration(seconds: 1), _startTimer);
    } else {
      // Completó la fase de descanso
      _completedCycles++;
      if (_completedCycles >= _currentPreset.cycles) {
        // ¡Fin de todo!
        _speak('¡Entrenamiento completado!');
        setState(() => _isRunning = false);
        _timer.cancel();
        _showCompletionDialog();
      } else {
        // Siguiente ciclo
        _speak('Siguiente ciclo: trabajo');
        setState(() {
          _isWorkPhase = true;
          _currentSeconds = _currentPreset.workDurationSec;
          _currentCycle++;
        });
        Future.delayed(const Duration(seconds: 1), _startTimer);
      }
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¡Excelente!'),
        content: Text(
          'Completaste $_completedCycles ciclos de ${_currentPreset.name}.\n¡Buen trabajo!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              _resetTimer();
              Navigator.pop(context);
            },
            child: const Text('Repetir'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final phaseLabel = _isWorkPhase ? 'TRABAJO' : 'DESCANSO';
    final phaseColor = _isWorkPhase ? Colors.red : Colors.green;

    return Scaffold(
      backgroundColor: SubefitColors.darkBg,
      appBar: AppBar(
        backgroundColor: SubefitColors.darkBg,
        foregroundColor: SubefitColors.textWhite,
        title: Text(_currentPreset.name),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Modo actual
              Chip(
                label: Text(_currentPreset.description),
                backgroundColor: phaseColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 30),
              // Círculo grande con tiempo
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: phaseColor.withValues(alpha: 0.2),
                  border: Border.all(color: phaseColor, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(_currentSeconds),
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: SubefitColors.textWhite,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        phaseLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: phaseColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Información de ciclos
              Text(
                'Ciclo $_currentCycle de ${_currentPreset.cycles}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _completedCycles / _currentPreset.cycles,
                minHeight: 6,
                backgroundColor: Colors.grey.shade700,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 40),
              // Botones de control
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'reset_timer',
                    onPressed: _resetTimer,
                    backgroundColor: SubefitColors.dangerRed,
                    child: const Icon(Icons.refresh, color: SubefitColors.textWhite),
                  ),
                  FloatingActionButton.large(
                    heroTag: 'play_pause_timer',
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    backgroundColor: _isRunning ? Colors.orange : Colors.green,
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: SubefitColors.textWhite,
                    ),
                  ),
                  const SizedBox(width: 66),
                ],
              ),
              const SizedBox(height: 40),
              // Selector de presets
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetButton(kTabataPreset),
                  _buildPresetButton(kHIITPreset),
                  _buildPresetButton(kPomodoroPreset),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(TimerPreset preset) {
    final isSelected = _currentPreset.mode == preset.mode;
    return ElevatedButton.icon(
      onPressed: _isRunning ? null : () {
        setState(() {
          _currentPreset = preset;
          _resetTimer();
        });
      },
      icon: Icon(preset.icon),
      label: Text(preset.name),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade700,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade600,
      ),
    );
  }
}
