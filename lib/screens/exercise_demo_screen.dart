import 'package:flutter/material.dart';

class ExerciseDemoScreen extends StatefulWidget {
  final String exerciseName;
  final String videoUrl;
  final String audioUrl;
  final String summaryText;
  final String seriesReps;
  final String precautions;
  final String breathingTips;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  final VoidCallback onPause;
  final VoidCallback onPlay;
  final VoidCallback onRepeatAudio;

  const ExerciseDemoScreen({
    Key? key,
    required this.exerciseName,
    required this.videoUrl,
    required this.audioUrl,
    required this.summaryText,
    required this.seriesReps,
    required this.precautions,
    required this.breathingTips,
    required this.onNext,
    required this.onRestart,
    required this.onPause,
    required this.onPlay,
    required this.onRepeatAudio,
  }) : super(key: key);

  @override
  State<ExerciseDemoScreen> createState() => _ExerciseDemoScreenState();
}

class _ExerciseDemoScreenState extends State<ExerciseDemoScreen> {
  bool isPlaying = false;
  bool isPaused = false;
  int seconds = 0;
  late final Stopwatch stopwatch;

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
  }

  void _togglePlayPause() {
    setState(() {
      if (isPlaying) {
        isPaused = true;
        isPlaying = false;
        stopwatch.stop();
        widget.onPause();
      } else {
        isPaused = false;
        isPlaying = true;
        stopwatch.start();
        widget.onPlay();
      }
    });
  }

  void _restart() {
    setState(() {
      isPlaying = false;
      isPaused = false;
      stopwatch.reset();
      widget.onRestart();
    });
  }

  @override
  void dispose() {
    stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.exerciseName),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF00E5FF)),
            onPressed: widget.onRepeatAudio,
            tooltip: 'Repetir audio',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video/animación (placeholder)
            Container(
              height: 200,
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.play_circle_fill,
                    size: 80, color: Color(0xFF00E5FF)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.summaryText,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Series y repeticiones: ${widget.seriesReps}',
                style: const TextStyle(color: Color(0xFF00E5FF))),
            const SizedBox(height: 8),
            Text('Precauciones: ${widget.precautions}',
                style: const TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 8),
            Text('Consejos de respiración: ${widget.breathingTips}',
                style: const TextStyle(color: Colors.greenAccent)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white, size: 32),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.restart_alt,
                      color: Colors.white, size: 32),
                  onPressed: _restart,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next,
                      color: Colors.white, size: 32),
                  onPressed: widget.onNext,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Chronometer(stopwatch: stopwatch),
          ],
        ),
      ),
    );
  }
}

class _Chronometer extends StatefulWidget {
  final Stopwatch stopwatch;
  const _Chronometer({Key? key, required this.stopwatch}) : super(key: key);

  @override
  State<_Chronometer> createState() => _ChronometerState();
}

class _ChronometerState extends State<_Chronometer> {
  late final Ticker _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration d) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = widget.stopwatch.elapsed;
    final min = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Center(
      child: Text('$min:$sec',
          style: const TextStyle(
              fontSize: 32,
              color: Color(0xFF00FF94),
              fontWeight: FontWeight.bold)),
    );
  }
}

class Ticker {
  final void Function(Duration) onTick;
  late final Stopwatch _sw;
  bool _running = false;
  Ticker(this.onTick);
  void start() {
    _running = true;
    _sw = Stopwatch()..start();
    _tick();
  }

  void _tick() async {
    while (_running) {
      await Future.delayed(const Duration(seconds: 1));
      onTick(_sw.elapsed);
    }
  }

  void dispose() {
    _running = false;
  }
}
