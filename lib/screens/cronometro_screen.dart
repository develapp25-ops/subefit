import 'dart:async';
import 'package:flutter/material.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'local_data_service.dart';

// Persistencia del estado del cronómetro para que siga contando al volver a la app
const _kCronometroStateFile = 'cronometro_state.json';

class CronometroScreen extends StatefulWidget {
  const CronometroScreen({Key? key}) : super(key: key);

  @override
  State<CronometroScreen> createState() => _CronometroScreenState();
}

class _CronometroScreenState extends State<CronometroScreen>
    with WidgetsBindingObserver {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _displayTime = "00:00:00";
  int _offsetMs = 0; // tiempo acumulado previo al inicio del Stopwatch

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
      // Actualizamos cada 100ms para reducir carga y evitar jank
      final ms = _offsetMs + (_stopwatch.isRunning ? _stopwatch.elapsedMilliseconds : 0);
      setState(() {
        _displayTime = _formatTime(ms);
      });
    });
    // Cargar estado previo (si existe)
    _restoreState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _stopwatch.stop();
    // Guardar estado final
    _saveState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Guardar estado para recuperación
      _saveState();
    } else if (state == AppLifecycleState.resumed) {
      // Restaurar por si quedó corriendo en background
      _restoreState();
    }
  }

  Future<void> _saveState() async {
    try {
      final data = {
        'offsetMs': _offsetMs + (_stopwatch.isRunning ? _stopwatch.elapsedMilliseconds : 0),
        'isRunning': _stopwatch.isRunning,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await LocalDataService().writeJsonFile(_kCronometroStateFile, data);
    } catch (e) {
      debugPrint('Error saving cronometro state: $e');
    }
  }

  Future<void> _restoreState() async {
    try {
      final data = await LocalDataService().readJsonFile(_kCronometroStateFile);
      if (data.isEmpty) return;
      final int offset = (data['offsetMs'] as num?)?.toInt() ?? 0;
      final bool running = data['isRunning'] as bool? ?? false;
      final int savedAt = (data['savedAt'] as num?)?.toInt() ?? 0;
      var restoredOffset = offset;
      if (running && savedAt > 0) {
        final now = DateTime.now().millisecondsSinceEpoch;
        restoredOffset = offset + (now - savedAt);
      }
      // Aplicar al estado del cronómetro
      _offsetMs = restoredOffset;
      if (_stopwatch.isRunning) _stopwatch.stop();
      _stopwatch.reset();
      if (running) _stopwatch.start();
      final ms = _offsetMs + (_stopwatch.isRunning ? _stopwatch.elapsedMilliseconds : 0);
      setState(() {
        _displayTime = _formatTime(ms);
      });
    } catch (e) {
      debugPrint('Error restoring cronometro state: $e');
    }
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String hundredsStr = (hundreds % 100).toString().padLeft(2, '0');

    return "$minutesStr:$secondsStr:$hundredsStr";
  }

  void _toggleStopwatch() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
      }
    });
  }

  void _resetStopwatch() {
    _stopwatch.stop();
    _stopwatch.reset();
    setState(() {
      _displayTime = "00:00:00";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Solución: Aplicar el color de fondo oscuro y un AppBar con estilo.
      backgroundColor: SubefitColors.darkBg,
      appBar: AppBar(
        backgroundColor: SubefitColors.darkBg,
        foregroundColor: SubefitColors
            .textWhite, // Asegura que el botón de regreso y título sean blancos
        title: const Text('Cronómetro'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _displayTime,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: SubefitColors.textWhite, // Usar el color del tema
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FloatingActionButton(
                  heroTag: 'reset',
                  onPressed: _resetStopwatch,
                  backgroundColor: SubefitColors.dangerRed,
                  child:
                      const Icon(Icons.refresh, color: SubefitColors.textWhite),
                ),
                FloatingActionButton.large(
                  heroTag: 'start_stop',
                  onPressed: _toggleStopwatch,
                  backgroundColor:
                      _stopwatch.isRunning ? Colors.orange : Colors.green,
                  child: Icon(
                    _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 40,
                    color: SubefitColors.textWhite,
                  ),
                ),
                // Placeholder para mantener el equilibrio
                const SizedBox(width: 66), // Ajustado para el tamaño del FAB
              ],
            ),
          ],
        ),
      ),
    );
  }
}
