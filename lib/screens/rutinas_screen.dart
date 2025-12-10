import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/subefit_colors.dart';
import 'local_auth_service.dart';
import 'workout_list_screen.dart'; // Importamos la nueva pantalla de lista de ejercicios

class RutinasScreen extends StatelessWidget {
  final void Function(String)? onNavigate;
  const RutinasScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secciones de Entrenamiento'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Selecciona una categoría para ver los ejercicios',
                  style: TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _CategoryCard(
                    title: 'Fuerza',
                    icon: Icons.fitness_center,
                    exerciseCount: 8,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          const WorkoutListScreen(category: 'Fuerza'),
                    )),
                  ),
                  _CategoryCard(
                    title: 'Resistencia',
                    icon: Icons.directions_run,
                    exerciseCount: 6,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          const WorkoutListScreen(category: 'Resistencia'),
                    )),
                  ),
                  _CategoryCard(
                    title: 'Cardio',
                    icon: Icons.favorite,
                    exerciseCount: 5,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          const WorkoutListScreen(category: 'Cardio'),
                    )),
                  ),
                  _CategoryCard(
                    title: 'Flexibilidad',
                    icon: Icons.self_improvement,
                    exerciseCount: 7,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          const WorkoutListScreen(category: 'Flexibilidad'),
                    )),
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

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int exerciseCount;

  const _CategoryCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.exerciseCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SubefitColors.primaryRed.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: SubefitColors.primaryRed.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: SubefitColors.primaryRed),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 4),
            Text('$exerciseCount ejercicios',
                style: const TextStyle(color: Colors.black54, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
