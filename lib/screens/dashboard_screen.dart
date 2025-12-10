import 'package:flutter/material.dart';
import '../widgets/subefit_button.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(String)? onNavigate;
  const DashboardScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Simulación de datos (luego se integrarán sensores reales)
  int pasos = 0;
  double distancia = 0.0; // en km
  double calorias = 0.0;
  int segundos = 0;
  late final int pesoUsuario = 70; // TODO: cargar desde Firestore
  late final double largoPaso = 0.75; // metros
  late final double met = 8.0; // correr por defecto
  bool entrenando = false;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  void _iniciarEntrenamiento() {
    setState(() {
      entrenando = true;
      _stopwatch.start();
    });
    _tick();
  }

  void _detenerEntrenamiento() {
    setState(() {
      entrenando = false;
      _stopwatch.stop();
    });
  }

  void _tick() async {
    if (!entrenando) return;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || !entrenando) return;
    setState(() {
      segundos = _stopwatch.elapsed.inSeconds;
      pasos += 2; // Simulación: 2 pasos por segundo
      distancia = pasos * largoPaso / 1000;
      calorias = met * pesoUsuario * (segundos / 3600);
    });
    _tick();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A192F), Color(0xFF00111A), Color(0xFF000000)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00FF94)],
                ).createShader(rect),
                child: const Text(
                  'Dashboard',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              _metricTile('Pasos', pasos.toString(), Icons.directions_walk),
              _metricTile(
                  'Distancia', '${distancia.toStringAsFixed(2)} km', Icons.map),
              _metricTile('Calorías', '${calorias.toStringAsFixed(0)} kcal',
                  Icons.local_fire_department),
              _metricTile('Tiempo', _formatTime(segundos), Icons.timer),
              const Spacer(),
              if (!entrenando)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _iniciarEntrenamiento,
                  child: const Text('Iniciar entrenamiento'),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _detenerEntrenamiento,
                  child: const Text('Detener entrenamiento'),
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SubefitButton(
                  label: '¡Probar pantalla de ejercicio nueva!',
                  emoji: '🏋️',
                  isPrimary: true,
                  onPressed: () => widget.onNavigate?.call('/ejercicio-styled'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return Card(
        color: Colors.black.withOpacity(0.7),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
            leading: Icon(icon, color: const Color(0xFF00E5FF), size: 32),
            title: Text(label, style: const TextStyle(color: Colors.white70)),
            trailing: Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold))));
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final ss = s % 60;
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }
}
