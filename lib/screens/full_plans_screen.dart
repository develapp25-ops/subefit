import 'package:flutter/material.dart';
import 'package:subefit/screens/exercise_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:subefit/screens/rutinas_ia_screen.dart';
import 'package:subefit/screens/plan_progression_screen.dart';

class FullPlansScreen extends StatelessWidget {
  /// Lista opcional de planes generados por IA para mostrar.
  final List<TrainingPlan>? generatedPlans;

  const FullPlansScreen({Key? key, this.generatedPlans}) : super(key: key);

  // Lista de planes de entrenamiento definidos estáticamente
  // Helper para crear sesiones de descanso
  static DailySession _createRestDay(int day, String quote) {
    return DailySession(
        day: day,
        title: 'Descanso',
        motivationalQuote: quote,
        exercises: const []);
  }

  // CORREGIDO: Se han rellenado los planes de entrenamiento con datos realistas y funcionales.
  static final List<TrainingPlan> _trainingPlans = [
    TrainingPlan(
      id: 'fuerza_01',
      title: 'Plan de Fuerza (Cuerpo Completo)',
      description:
          'Gana fuerza y tonificación en 4 semanas. Ideal para principiantes e intermedios.',
      level: 'Principiante → Intermedio',
      durationWeeks: 4,
      icon: Icons.fitness_center,
      color: SubefitColors.primaryRed, // Usando un color existente
      dailySessions: List.generate(28, (index) {
        // 4 semanas
        final day = index + 1;
        final dayOfWeek = day % 7;

        switch (dayOfWeek) {
          case 1: // Lunes
            return DailySession(
                day: day,
                title: 'Full Body - Fuerza Base',
                motivationalQuote: 'Construye tu base, ladrillo a ladrillo.',
                exercises: const [
                  ExerciseStep(
                      name: 'Calentamiento',
                      description:
                          '5 min de saltos de tijera y movilidad articular.',
                      duration: Duration(minutes: 5)),
                  ExerciseStep(
                      name: 'Sentadillas con peso corporal',
                      description: 'Espalda recta, baja profundo.',
                      sets: 3,
                      reps: '12'),
                  ExerciseStep(
                      name: 'Lagartijas (Push-ups)',
                      description:
                          'Apoya rodillas si es necesario. Controla la bajada.',
                      sets: 3,
                      reps: '10'),
                  ExerciseStep(
                      name: 'Remo con mancuerna o banda',
                      description: 'Contrae la espalda en cada repetición.',
                      sets: 3,
                      reps: '12'),
                  ExerciseStep(
                      name: 'Plancha Abdominal',
                      description: 'Mantén el cuerpo recto como una tabla.',
                      sets: 3,
                      duration: Duration(seconds: 45)),
                  ExerciseStep(
                      name: 'Enfriamiento',
                      description:
                          'Estiramientos suaves de los músculos trabajados.',
                      duration: Duration(minutes: 5)),
                ]);
          case 2: // Martes
            return DailySession(
                day: day,
                title: 'Cardio Ligero y Core',
                motivationalQuote: 'Un corazón fuerte te lleva más lejos.',
                exercises: const [
                  ExerciseStep(
                      name: 'Trote ligero en el sitio',
                      description: 'Eleva las rodillas.',
                      duration: Duration(minutes: 5)),
                  ExerciseStep(
                      name: 'Crunches',
                      description: 'No tires del cuello, usa el abdomen.',
                      sets: 3,
                      reps: '15'),
                  ExerciseStep(
                      name: 'Elevación de piernas',
                      description: 'Mantén la espalda baja pegada al suelo.',
                      sets: 3,
                      reps: '15'),
                  ExerciseStep(
                      name: 'Jumping Jacks',
                      description: 'Mantén un ritmo constante.',
                      sets: 4,
                      duration: Duration(seconds: 45)),
                ]);
          case 3: // Miércoles
            return _createRestDay(
                day, 'El descanso es donde ocurre la magia del crecimiento.');
          case 4: // Jueves
            return DailySession(
                day: day,
                title: 'Tren Inferior',
                motivationalQuote: 'Tus piernas son tu motor. ¡Enciéndelo!',
                exercises: const [
                  ExerciseStep(
                      name: 'Calentamiento',
                      description: 'Sentadillas sin peso y zancadas.',
                      duration: Duration(minutes: 5)),
                  ExerciseStep(
                      name: 'Zancadas (Lunges)',
                      description: 'Alterna piernas, mantén el equilibrio.',
                      sets: 3,
                      reps: '10'),
                  ExerciseStep(
                      name: 'Puente de Glúteos',
                      description: 'Aprieta los glúteos en la cima.',
                      sets: 3,
                      reps: '15'),
                  ExerciseStep(
                      name: 'Elevación de talones',
                      description: 'Trabaja tus pantorrillas.',
                      sets: 3,
                      reps: '20'),
                ]);
          case 5: // Viernes
            return DailySession(
                day: day,
                title: 'Tren Superior',
                motivationalQuote: 'Define tu silueta, esculpe tu fuerza.',
                exercises: const [
                  ExerciseStep(
                      name: 'Calentamiento',
                      description: 'Círculos de brazos y rotaciones.',
                      duration: Duration(minutes: 5)),
                  ExerciseStep(
                      name: 'Press de hombros con mancuernas',
                      description: 'Controla el movimiento, no uses impulso.',
                      sets: 3,
                      reps: '12'),
                  ExerciseStep(
                      name: 'Curl de Bíceps',
                      description: 'Mantén los codos pegados al cuerpo.',
                      sets: 3,
                      reps: '12'),
                  ExerciseStep(
                      name: 'Fondos en silla o banco',
                      description: 'Trabaja tus tríceps.',
                      sets: 3,
                      reps: '10'),
                ]);
          case 6: // Sábado
            return DailySession(
                day: day,
                title: 'Reto Funcional',
                motivationalQuote: '¡Demuestra de qué estás hecho!',
                exercises: const [
                  ExerciseStep(
                      name: 'Burpees',
                      description: 'Combina sentadilla, lagartija y salto.',
                      sets: 5,
                      reps: '8'),
                  ExerciseStep(
                      name: 'Mountain Climbers',
                      description: 'Ritmo rápido y constante.',
                      sets: 4,
                      duration: Duration(seconds: 40)),
                ]);
          case 0: // Domingo
          default:
            return _createRestDay(day,
                'Recupera, reflexiona y prepárate para la próxima semana.');
        }
      }),
    ),
    TrainingPlan(
      id: 'flexibilidad_01',
      title: 'Plan de Elasticidad / Flexibilidad',
      description: 'Mejora tu movilidad y rango de movimiento en 3 semanas.',
      level: 'Todos los niveles',
      durationWeeks: 3,
      icon: Icons.self_improvement,
      color: Colors.cyan, // Usando un color estándar
      dailySessions: List.generate(21, (index) {
        // 3 semanas
        final day = index + 1;
        final dayOfWeek = day % 7;

        switch (dayOfWeek) {
          case 1: // Lunes
          case 4: // Jueves
            return DailySession(
                day: day,
                title: 'Estiramiento de Piernas y Espalda',
                motivationalQuote: 'Libera la tensión y encuentra tu espacio.',
                exercises: const [
                  ExerciseStep(
                      name: 'Respiración Inicial',
                      description:
                          'Siéntate cómodamente y concéntrate en tu respiración.',
                      duration: Duration(minutes: 2)),
                  ExerciseStep(
                      name: 'Gato-Vaca',
                      description:
                          'A cuatro patas, arquea y redondea tu espalda al ritmo de tu respiración.',
                      duration: Duration(seconds: 90)),
                  ExerciseStep(
                      name: 'Estiramiento Isquiotibial Sentado',
                      description:
                          'Estira una pierna y flexiona el torso hacia ella. Sostén 30s por lado.',
                      duration: Duration(seconds: 70)),
                  ExerciseStep(
                      name: 'Torsión de Columna Acostado',
                      description:
                          'Lleva una rodilla hacia el lado opuesto. Sostén 30s por lado.',
                      duration: Duration(seconds: 70)),
                  ExerciseStep(
                      name: 'Postura del Niño',
                      description:
                          'Relaja tu espalda y hombros, respirando profundamente.',
                      duration: Duration(seconds: 90)),
                ]);
          case 2: // Martes
          case 5: // Viernes
            return DailySession(
                day: day,
                title: 'Movilidad de Hombros y Cadera',
                motivationalQuote: 'La fluidez es una forma de fuerza.',
                exercises: const [
                  ExerciseStep(
                      name: 'Círculos de brazos',
                      description:
                          'Grandes y controlados, hacia adelante y atrás.',
                      duration: Duration(seconds: 60)),
                  ExerciseStep(
                      name: 'Estiramiento de mariposa',
                      description:
                          'Junta las plantas de los pies y acerca los talones.',
                      duration: Duration(seconds: 60)),
                  ExerciseStep(
                      name: 'Postura de la paloma',
                      description:
                          'Excelente para abrir la cadera. 45s por lado.',
                      duration: Duration(seconds: 100)),
                ]);
          default: // Miércoles, Sábado, Domingo
            return _createRestDay(
                day, 'La flexibilidad se gana con práctica y paciencia.');
        }
      }),
    ),
    TrainingPlan(
      id: 'cardio_01',
      title: 'Plan de Pérdida de peso / Cardio',
      description:
          'Quema grasa y mejora tu resistencia cardiovascular en 4 semanas.',
      level: 'Principiante → Intermedio',
      durationWeeks: 4,
      icon: Icons.local_fire_department,
      color: Colors.orange, // Usando un color estándar
      dailySessions: List.generate(28, (index) {
        // 4 semanas
        final day = index + 1;
        final dayOfWeek = day % 7;

        switch (dayOfWeek) {
          case 1: // Lunes
          case 5: // Viernes
            return DailySession(
                day: day,
                title: 'Cardio Intenso (HIIT)',
                motivationalQuote: 'Supera tus límites, un intervalo a la vez.',
                exercises: const [
                  ExerciseStep(
                      name: 'Calentamiento',
                      description: 'Trote ligero y saltos.',
                      duration: Duration(minutes: 5)),
                  ExerciseStep(
                      name: 'Jumping Jacks',
                      description: '30s de trabajo, 15s de descanso.',
                      sets: 4,
                      duration: Duration(seconds: 30)),
                  ExerciseStep(
                      name: 'Rodillas al pecho (High Knees)',
                      description: '30s de trabajo, 15s de descanso.',
                      sets: 4,
                      duration: Duration(seconds: 30)),
                  ExerciseStep(
                      name: 'Burpees',
                      description: '20s de trabajo, 20s de descanso.',
                      sets: 4,
                      duration: Duration(seconds: 20)),
                  ExerciseStep(
                      name: 'Enfriamiento',
                      description: 'Caminata y estiramientos.',
                      duration: Duration(minutes: 5)),
                ]);
          case 3: // Miércoles
            return DailySession(
                day: day,
                title: 'Cardio Moderado',
                motivationalQuote: 'Constancia sobre intensidad.',
                exercises: const [
                  ExerciseStep(
                      name: 'Trote o caminata rápida',
                      description: 'Mantén un ritmo que te permita hablar.',
                      duration: Duration(minutes: 25)),
                ]);
          case 2: // Martes
          case 4: // Jueves
          case 6: // Sábado
          case 0: // Domingo
          default:
            return _createRestDay(day,
                'Tu corazón también necesita descansar para fortalecerse.');
        }
      }),
    ),
    TrainingPlan(
      id: 'resistencia_01',
      title: 'Plan de Resistencia / Mixto',
      description:
          'Aumenta tu resistencia general y energía con este plan de 4 semanas.',
      level: 'Todos los niveles',
      durationWeeks: 4,
      icon: Icons.battery_charging_full,
      color: Colors.green, // Usando un color estándar
      dailySessions: List.generate(28, (index) {
        // 4 semanas
        final day = index + 1;
        final dayOfWeek = day % 7;

        switch (dayOfWeek) {
          case 1: // Lunes
          case 4: // Jueves
            return DailySession(
                day: day,
                title: 'Circuito de Resistencia',
                motivationalQuote: 'Más repeticiones, más aguante.',
                exercises: const [
                  ExerciseStep(
                      name: 'Calentamiento',
                      description: 'Movilidad general.',
                      duration: Duration(minutes: 5)),
                  ExerciseStep(
                      name: 'Sentadillas',
                      description: 'Controla el tempo, no la velocidad.',
                      sets: 4,
                      reps: '15'),
                  ExerciseStep(
                      name: 'Flexiones Inclinadas',
                      description: 'Usa una silla o pared para facilitar.',
                      sets: 4,
                      reps: '12'),
                  ExerciseStep(
                      name: 'Plancha con toque de hombro',
                      description: 'Mantén la cadera estable.',
                      sets: 4,
                      reps: '20'),
                ]);
          case 2: // Martes
          case 5: // Viernes
            return DailySession(
                day: day,
                title: 'Cardio de Larga Duración',
                motivationalQuote: 'La mente se rinde antes que el cuerpo.',
                exercises: const [
                  ExerciseStep(
                      name: 'Carrera suave o Elíptica',
                      description: 'Mantén un ritmo constante por 30 minutos.',
                      duration: Duration(minutes: 30)),
                ]);
          default: // Miércoles, Sábado, Domingo
            return _createRestDay(day,
                'La resistencia se construye tanto en el esfuerzo como en la recuperación.');
        }
      }),
    ),
    TrainingPlan(
      id: 'core_01',
      title: 'Plan de Core Intenso',
      description:
          'Fortalece tu abdomen y espalda baja para una mejor postura y rendimiento en 4 semanas.',
      level: 'Intermedio',
      durationWeeks: 4,
      icon: Icons.shield_outlined,
      color: SubefitColors.primaryRed,
      dailySessions: List.generate(28, (index) {
        // 4 semanas
        final day = index + 1;
        final dayOfWeek = day % 7;

        switch (dayOfWeek) {
          case 1: // Lunes
          case 3: // Miércoles
          case 5: // Viernes
            return DailySession(
                day: day,
                title: 'Abdomen y Oblicuos',
                motivationalQuote:
                    'Un core fuerte es la base de todo movimiento.',
                exercises: const [
                  ExerciseStep(
                      name: 'Calentamiento',
                      description:
                          'Rotaciones de torso y elevaciones de rodillas.',
                      duration: Duration(minutes: 3)),
                  ExerciseStep(
                      name: 'Crunches',
                      description:
                          'Eleva tu torso superior sin forzar el cuello.',
                      sets: 3,
                      reps: '20'),
                  ExerciseStep(
                      name: 'Plancha Lateral',
                      description: 'Mantén la cadera elevada. 30s por lado.',
                      sets: 3,
                      duration: Duration(seconds: 70)),
                  ExerciseStep(
                      name: 'Elevación de Piernas',
                      description:
                          'Acostado, levanta las piernas rectas sin arquear la espalda.',
                      sets: 3,
                      reps: '15'),
                  ExerciseStep(
                      name: 'Russian Twists',
                      description: 'Gira el torso de lado a lado.',
                      sets: 3,
                      reps: '20'),
                ]);
          default: // Días de descanso
            return _createRestDay(
                day, 'El descanso repara y fortalece tu centro.');
        }
      }),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Combinamos los planes estáticos con los generados por IA (si existen)
    final allPlans = [
      if (generatedPlans != null) ...generatedPlans!,
      ..._trainingPlans,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes de Entrenamiento'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const RutinasIaScreen()));
        },
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Crear Plan con IA'),
        backgroundColor: SubefitColors.primaryRed,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allPlans.length,
        itemBuilder: (context, index) {
          final plan = allPlans[index];
          return _PlanCard(
            // Usamos el mismo widget de tarjeta
            plan: plan,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlanProgressionScreen(plan: plan),
              ));
            },
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final TrainingPlan plan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      // Añadimos un borde de color para los planes generados
      shape: plan.id.startsWith('ia_') || plan.id.startsWith('local_')
          ? RoundedRectangleBorder(
              side: const BorderSide(color: SubefitColors.primaryRed, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.id.startsWith('ia_') ||
                  plan.id
                      .startsWith('local_')) // Etiqueta para planes generados
                Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 16, color: plan.color),
                    const SizedBox(width: 4),
                    Text('PLAN PERSONALIZADO',
                        style: TextStyle(
                            color: plan.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const Spacer(),
                  ],
                ),
              Icon(plan.icon, size: 32, color: plan.color),
              const SizedBox(height: 8),
              Text(plan.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(plan.description,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.bar_chart, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(plan.level, style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  const Icon(Icons.timer_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${plan.durationWeeks} semanas',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
