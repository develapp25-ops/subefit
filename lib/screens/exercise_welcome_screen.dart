import 'package:flutter/material.dart';

class ExerciseWelcomeScreen extends StatelessWidget {
  final String exerciseName;
  final String instructorName;
  final String introPhrase;
  final String avatarUrl;
  final VoidCallback onStart;
  final VoidCallback onShowInstructions;
  final VoidCallback? onRequestCamera;
  final VoidCallback? onRequestMic;
  final VoidCallback? onRequestLocation;

  const ExerciseWelcomeScreen({
    Key? key,
    required this.exerciseName,
    required this.instructorName,
    required this.introPhrase,
    required this.avatarUrl,
    required this.onStart,
    required this.onShowInstructions,
    this.onRequestCamera,
    this.onRequestMic,
    this.onRequestLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 56,
                backgroundImage: NetworkImage(avatarUrl),
                backgroundColor: Colors.grey[900],
              ),
              const SizedBox(height: 16),
              Text(
                instructorName,
                style: const TextStyle(fontSize: 20, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00FF94)],
                ).createShader(rect),
                child: Text(
                  exerciseName,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                introPhrase,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: onStart,
                label: const Text('Comenzar'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onShowInstructions,
                child: const Text('Ver instrucciones completas',
                    style: TextStyle(color: Color(0xFF00E5FF))),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onRequestCamera != null)
                    _PermissionButton(
                      icon: Icons.camera_alt,
                      label: 'Cámara',
                      onPressed: onRequestCamera!,
                    ),
                  if (onRequestMic != null)
                    _PermissionButton(
                      icon: Icons.mic,
                      label: 'Micrófono',
                      onPressed: onRequestMic!,
                    ),
                  if (onRequestLocation != null)
                    _PermissionButton(
                      icon: Icons.location_on,
                      label: 'Ubicación',
                      onPressed: onRequestLocation!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _PermissionButton(
      {Key? key,
      required this.icon,
      required this.label,
      required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[850],
          minimumSize: const Size(48, 40),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
