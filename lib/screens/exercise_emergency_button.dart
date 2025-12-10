import 'package:flutter/material.dart';

class ExerciseEmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool showLocation;
  const ExerciseEmergencyButton(
      {Key? key, required this.onPressed, this.showLocation = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.warning, color: Colors.white),
        label: Text(showLocation ? 'Emergencia (GPS)' : 'Emergencia'),
        onPressed: onPressed,
      ),
    );
  }
}
