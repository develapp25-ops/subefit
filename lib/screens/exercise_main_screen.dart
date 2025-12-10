import 'package:flutter/material.dart';
import 'exercise_emergency_button.dart';

class ExerciseMainScreen extends StatefulWidget {
  final String exerciseName;
  final String instructorName;
  final String avatarUrl;
  final String videoUrl;
  final String summaryText;
  final String seriesReps;
  final String precautions;
  final String breathingTips;
  final VoidCallback onNext;
  final VoidCallback onRepeat;
  final VoidCallback onChatIA;
  final VoidCallback onShowInstructions;
  final VoidCallback onEmergency;
  final VoidCallback onProfile;
  final VoidCallback onHistory;
  final VoidCallback onPause;
  final VoidCallback onPlay;
  final VoidCallback onRestart;
  final VoidCallback onRepeatAudio;
  final bool isPlaying;
  final int completedSets;
  final int totalSets;
  final Duration elapsed;
  final String? userFeeling;
  final VoidCallback onCheckin;

  const ExerciseMainScreen({
    Key? key,
    required this.exerciseName,
    required this.instructorName,
    required this.avatarUrl,
    required this.videoUrl,
    required this.summaryText,
    required this.seriesReps,
    required this.precautions,
    required this.breathingTips,
    required this.onNext,
    required this.onRepeat,
    required this.onChatIA,
    required this.onShowInstructions,
    required this.onEmergency,
    required this.onProfile,
    required this.onHistory,
    required this.onPause,
    required this.onPlay,
    required this.onRestart,
    required this.onRepeatAudio,
    required this.isPlaying,
    required this.completedSets,
    required this.totalSets,
    required this.elapsed,
    this.userFeeling,
    required this.onCheckin,
  }) : super(key: key);

  @override
  State<ExerciseMainScreen> createState() => _ExerciseMainScreenState();
}

class _ExerciseMainScreenState extends State<ExerciseMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Bar
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(widget.avatarUrl),
                        backgroundColor: Colors.grey[900],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.exerciseName,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text(widget.instructorName,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble,
                            color: Color(0xFF00E5FF)),
                        onPressed: widget.onChatIA,
                        tooltip: 'Chat IA',
                      ),
                      IconButton(
                        icon: const Icon(Icons.person, color: Colors.white),
                        onPressed: widget.onProfile,
                        tooltip: 'Perfil',
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.white),
                        onPressed: widget.onHistory,
                        tooltip: 'Historial',
                      ),
                    ],
                  ),
                ),
              ),
              // Video y controles
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_circle_fill,
                            size: 100, color: Color(0xFF00E5FF)),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.white),
                        onPressed: widget.onRepeatAudio,
                        tooltip: 'Repetir audio',
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                                widget.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 32),
                            onPressed: widget.isPlaying
                                ? widget.onPause
                                : widget.onPlay,
                          ),
                          IconButton(
                            icon: const Icon(Icons.restart_alt,
                                color: Colors.white, size: 32),
                            onPressed: widget.onRestart,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _Chronometer(elapsed: widget.elapsed),
                    ),
                  ],
                ),
              ),
              // Indicaciones y consejos
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.summaryText,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Series y repeticiones: ${widget.seriesReps}',
                        style: const TextStyle(color: Color(0xFF00E5FF))),
                    const SizedBox(height: 8),
                    Text('Precauciones: ${widget.precautions}',
                        style: const TextStyle(color: Colors.orangeAccent)),
                    const SizedBox(height: 8),
                    Text('Consejos de respiración: ${widget.breathingTips}',
                        style: const TextStyle(color: Colors.greenAccent)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.onShowInstructions,
                      child: const Text('Ver instrucciones completas',
                          style: TextStyle(color: Color(0xFF00E5FF))),
                    ),
                  ],
                ),
              ),
              // Progreso e interacción IA
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: widget.completedSets / widget.totalSets,
                        backgroundColor: Colors.grey[800],
                        color: const Color(0xFF00FF94),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${widget.completedSets}/${widget.totalSets}',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: widget.onRepeat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[850],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                      ),
                      child: const Text('Repetir'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: widget.onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(120, 48),
                      ),
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
              ),
              // Check-in y chat IA
              if (widget.userFeeling != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.mood, color: Color(0xFF00FF94)),
                      const SizedBox(width: 8),
                      Text('Te sientes: ${widget.userFeeling}',
                          style: const TextStyle(color: Colors.white)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: widget.onCheckin,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Actualizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[850],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // Footer
              Container(
                color: Colors.grey[900],
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history, color: Color(0xFF00E5FF)),
                      onPressed: widget.onHistory,
                      tooltip: 'Historial',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble,
                          color: Color(0xFF00E5FF)),
                      onPressed: widget.onChatIA,
                      tooltip: 'Chat IA',
                    ),
                    IconButton(
                      icon: const Icon(Icons.person, color: Color(0xFF00E5FF)),
                      onPressed: widget.onProfile,
                      tooltip: 'Perfil',
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Botón de emergencia SIEMPRE visible
          ExerciseEmergencyButton(
            onPressed: widget.onEmergency,
            showLocation: true,
          ),
        ],
      ),
    );
  }
}

class _Chronometer extends StatelessWidget {
  final Duration elapsed;
  const _Chronometer({Key? key, required this.elapsed}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final min = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$min:$sec',
          style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF00FF94),
              fontWeight: FontWeight.bold)),
    );
  }
}
