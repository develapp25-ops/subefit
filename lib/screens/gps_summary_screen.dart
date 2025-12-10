import 'package:flutter/material.dart';

class GPSSummaryScreen extends StatelessWidget {
  final double distanceKm;
  final Duration elapsed;
  final double avgPace;
  final int calories;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final String iaFeedback;
  final VoidCallback onFinish;

  const GPSSummaryScreen({
    Key? key,
    required this.distanceKm,
    required this.elapsed,
    required this.avgPace,
    required this.calories,
    required this.onSave,
    required this.onShare,
    required this.iaFeedback,
    required this.onFinish,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final min = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Resumen de tu ruta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onFinish,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _SummaryRow(
                label: 'Distancia total',
                value: '${distanceKm.toStringAsFixed(2)} km'),
            _SummaryRow(label: 'Tiempo total', value: '$min:$sec'),
            _SummaryRow(
                label: 'Ritmo medio',
                value: '${avgPace.toStringAsFixed(2)} min/km'),
            _SummaryRow(label: 'Calorías', value: calories.toString()),
            const SizedBox(height: 32),
            Text('Feedback de IA:',
                style: TextStyle(
                    color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(iaFeedback, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF94),
                    foregroundColor: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onFinish,
              child: const Text('Finalizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({Key? key, required this.label, required this.value})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
