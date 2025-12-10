import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // Descomenta si usas Google Maps

class GPSSessionScreen extends StatelessWidget {
  final String routeName;
  final VoidCallback onConfig;
  final VoidCallback onStartPauseResume;
  final VoidCallback onFinish;
  final VoidCallback onEmergency;
  final VoidCallback onChatIA;
  final bool isRunning;
  final double distanceKm;
  final Duration elapsed;
  final double speedKmh;
  final int calories;

  const GPSSessionScreen({
    Key? key,
    this.routeName = 'Mi Carrera',
    required this.onConfig,
    required this.onStartPauseResume,
    required this.onFinish,
    required this.onEmergency,
    required this.onChatIA,
    this.isRunning = false,
    this.distanceKm = 0.0,
    this.elapsed = Duration.zero,
    this.speedKmh = 0.0,
    this.calories = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 2️⃣ Mapa principal (placeholder)
          Positioned.fill(
            child: Container(
              color: Colors.grey[300],
              child: const Center(
                child: Text('MAPA AQUÍ',
                    style: TextStyle(color: Colors.white38, fontSize: 24)),
              ),
            ),
          ),
          // 1️⃣ Cabecera
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(routeName,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black54),
                    onPressed: onConfig,
                  ),
                ],
              ),
            ),
          ),
          // 3️⃣ Contadores flotantes
          Positioned(
            top: 90,
            right: 16,
            child: _StatsPanel(
              distanceKm: distanceKm,
              elapsed: elapsed,
              speedKmh: speedKmh,
              calories: calories,
            ),
          ),
          // 4️⃣ Botones de control
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onStartPauseResume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRunning
                        ? Colors.orange
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 56),
                  ),
                  child: Text(isRunning ? 'Pausar' : 'Iniciar'),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed:
                      onFinish, // El estilo por defecto ya es rojo con texto blanco
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SubefitColors
                        .dangerRed, // Rojo para una acción destructiva
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 56),
                  ),
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          ),
          // 4️⃣ Botón de emergencia
          Positioned(
            bottom: 120,
            left: 24,
            child: FloatingActionButton(
              backgroundColor: Colors.redAccent,
              onPressed: onEmergency, // Este color ya es apropiado
              child: const Icon(Icons.warning, color: Colors.white),
              tooltip: 'Emergencia',
            ),
          ),
          // 5️⃣ Chat IA (micrófono)
          Positioned(
            bottom: 40,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: SubefitColors.primaryRed,
              onPressed: onChatIA,
              child: const Icon(Icons.mic, color: Colors.black),
              tooltip: 'Chat IA',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final double distanceKm;
  final Duration elapsed;
  final double speedKmh;
  final int calories;
  const _StatsPanel(
      {Key? key,
      required this.distanceKm,
      required this.elapsed,
      required this.speedKmh,
      required this.calories})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final min = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatRow(
              label: 'Distancia', value: '${distanceKm.toStringAsFixed(2)} km'),
          _StatRow(label: 'Tiempo', value: '$min:$sec'),
          _StatRow(
              label: 'Velocidad', value: '${speedKmh.toStringAsFixed(1)} km/h'),
          _StatRow(label: 'Calorías', value: calories.toString()),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({Key? key, required this.label, required this.value})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
