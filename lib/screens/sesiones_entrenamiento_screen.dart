import 'package:flutter/material.dart';
import 'package:subefit/widgets/subefit_colors.dart';

class SesionesEntrenamientoScreen extends StatelessWidget {
  const SesionesEntrenamientoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Sesiones de Entrenamiento'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SessionCard(
            title: 'Rutina Personalizada con IA',
            description:
                'Genera una rutina única basada en tus metas, equipo y progreso actual.',
            icon: Icons.smart_toy_outlined,
            color: SubefitColors.primaryRed,
            onTap: () {
              Navigator.of(context).pushNamed('/rutinas-ia');
            },
          ),
          _SessionCard(
            title: 'Planes de Entrenamiento',
            description:
                'Sigue planes estructurados diseñados por expertos para objetivos a largo plazo.',
            icon: Icons.calendar_today_outlined,
            color: SubefitColors.primaryRed.withOpacity(0.8),
            onTap: () {
              Navigator.of(context).pushNamed('/full-plans');
            },
          ),
          _SessionCard(
            title: 'Entrenamientos Básicos',
            description:
                'Elige entre una variedad de rutinas predefinidas para empezar a entrenar ya.',
            icon: Icons.fitness_center_outlined,
            color: SubefitColors.primaryRed.withOpacity(0.6),
            onTap: () {
              Navigator.of(context).pushNamed('/basic-workouts');
            },
          ),
          _SessionCard(
            title: 'Sesión Libre',
            description:
                'Selecciona tus propios ejercicios y crea tu entrenamiento sobre la marcha.',
            icon: Icons.edit_note_outlined,
            color: SubefitColors.primaryRed.withOpacity(0.4),
            onTap: () {
              // TODO: Navegar a la pantalla de sesión libre cuando esté creada.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Función de Sesión Libre próximamente.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SessionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
