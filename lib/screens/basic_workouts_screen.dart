import 'package:flutter/material.dart';
import 'package:subefit/screens/exercise_model.dart';
import 'package:subefit/screens/exercise_main_screen_styled.dart';
import 'package:subefit/widgets/subefit_colors.dart';

class BasicWorkoutsScreen extends StatelessWidget {
  const BasicWorkoutsScreen({Key? key}) : super(key: key);

  // Lista de sesiones de entrenamiento predefinidas
  static final List<DailySession> _basicSessions = [
    DailySession(
      day: 1,
      title: '🔥 Full Body (30 min)',
      motivationalQuote: 'Un entrenamiento completo para un día completo.',
      exercises: const [
        // Added type for each exercise
        const ExerciseStep(
            name: 'Burpees',
            description:
                'Desde pie, baja a plancha, realiza flexión, vuelve a posición de pie y salta explosivamente. Mantén ritmo constante.',
            duration: Duration(seconds: 45),
            type: 'Cardio'),
        const ExerciseStep(
            name: 'Sentadillas',
            description:
                'Pies al ancho de hombros, espalda recta. Flexiona rodillas y baja cadera hasta 90°, luego sube controlando. Mantén abdomen activo.',
            duration: Duration(seconds: 45),
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Lagartijas',
            description:
                'Colócate boca abajo, manos al ancho de hombros, codos apuntando ligeramente hacia afuera. Mantén cuerpo recto, baja el pecho hasta casi tocar el suelo y sube controlando el movimiento.',
            reps: '15',
            duration: Duration(seconds: 45),
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Plancha dinámica',
            description: 'Alterna entre plancha de codos y manos.',
            duration: Duration(seconds: 45),
            type: 'Core'),
        const ExerciseStep(
            name: 'Mountain climbers',
            description:
                'Posición de plancha frontal, lleva rodillas al pecho alternando rápidamente sin levantar caderas, abdomen firme.',
            duration: Duration(seconds: 45),
            type: 'Cardio'),
        const ExerciseStep(
            name: 'Puente de glúteos',
            description:
                'Acostado boca arriba, pies apoyados, rodillas flexionadas. Eleva cadera contrayendo glúteos hasta formar línea recta hombros-cadera. Baja controladamente.',
            duration: Duration(seconds: 45),
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Jumping jacks',
            description:
                'De pie, salta abriendo piernas y brazos al mismo tiempo, regresa al centro y repite.',
            duration: Duration(seconds: 45),
            type: 'Cardio'),
        const ExerciseStep(
            name: 'Plancha final',
            description: 'Mantén la posición de plancha frontal.',
            duration: Duration(seconds: 60),
            type: 'Core'),
      ],
    ),
    DailySession(
      day: 2,
      title: '💪 Fuerza (20 min)',
      motivationalQuote: 'Construye la fuerza que te llevará a la cima.',
      exercises: const [
        // Added type for each exercise
        const ExerciseStep(
            name: 'Lagartijas',
            description:
                'Colócate boca abajo, manos al ancho de hombros, codos apuntando ligeramente hacia afuera. Mantén cuerpo recto, baja el pecho hasta casi tocar el suelo y sube controlando el movimiento.',
            reps: '12',
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Sentadillas',
            description:
                'Pies al ancho de hombros, espalda recta. Flexiona rodillas y baja cadera hasta 90°, luego sube controlando. Mantén abdomen activo.',
            reps: '15',
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Puente de glúteos',
            description:
                'Acostado boca arriba, pies apoyados, rodillas flexionadas. Eleva cadera contrayendo glúteos hasta formar línea recta hombros-cadera. Baja controladamente.',
            reps: '20',
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Zancadas',
            description:
                'Da un paso largo hacia adelante, flexiona ambas rodillas hasta formar ángulo de 90°. Mantén torso recto y vuelve al inicio. Alterna piernas.',
            reps: '20',
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Plancha',
            description:
                'Apoya antebrazos y puntas de pies, cuerpo recto de pies a cabeza, abdomen contraído. Mantén la posición.',
            duration: Duration(seconds: 45),
            type: 'Core'),
        const ExerciseStep(
            name: 'Superman',
            description: 'Acostado boca abajo, eleva brazos y piernas.',
            reps: '15',
            type: 'Fuerza'),
      ],
    ),
    DailySession(
      day: 3,
      title: '🧘‍♂️ Core & Abdomen (20 min)',
      motivationalQuote: 'Un core fuerte es la base de todo movimiento.',
      exercises: const [
        // Added type for each exercise
        const ExerciseStep(
            name: 'Abdominales bicicleta',
            description:
                'Acostado, manos detrás de cabeza, lleva codo derecho a rodilla izquierda y viceversa alternando, torso elevado.',
            duration: Duration(seconds: 45),
            type: 'Core'),
        const ExerciseStep(
            name: 'Elevaciones de piernas',
            description:
                'Acostado, piernas estiradas, eleva juntas hasta formar ángulo de 90° y baja sin tocar suelo, controlando movimiento.',
            duration: Duration(seconds: 45),
            type: 'Core'),
        const ExerciseStep(
            name: 'Plancha lateral',
            description: '30s por cada lado.',
            duration: Duration(seconds: 60),
            type: 'Core'),
        const ExerciseStep(
            name: 'Russian twists',
            description:
                'Sentado, rodillas flexionadas, pies en suelo. Gira torso de lado a lado tocando suelo con manos, abdomen firme.',
            duration: Duration(seconds: 45),
            type: 'Core'),
        const ExerciseStep(
            name: 'Flutter kicks',
            description:
                'Acostado boca arriba, piernas extendidas, alterna movimiento arriba-abajo, abdomen firme.',
            duration: Duration(seconds: 45),
            type: 'Core'),
        const ExerciseStep(
            name: 'Hollow hold',
            description:
                'Acostado, brazos y piernas elevadas, abdomen contraído, espalda baja pegada al suelo, sostén posición.',
            duration: Duration(seconds: 30),
            type: 'Core'),
      ],
    ),
    DailySession(
      day: 4,
      title: '💨 Cardio (15-25 min)',
      motivationalQuote: 'Siente tu corazón latir, siente la vida.',
      exercises: const [
        // Added type for each exercise
        const ExerciseStep(
            name: 'Jumping jacks',
            description:
                'De pie, salta abriendo piernas y brazos al mismo tiempo, regresa al centro y repite.',
            duration: Duration(seconds: 50),
            type: 'Cardio'),
        const ExerciseStep(
            name: 'Burpees',
            description:
                'Desde pie, baja a plancha, realiza flexión, vuelve a posición de pie y salta explosivamente. Mantén ritmo constante.',
            duration: Duration(seconds: 50),
            type: 'Cardio'),
        const ExerciseStep(
            name: 'Skaters',
            description:
                'Salta lateralmente de un pie al otro imitando patinaje, equilibrio y abdomen activo.',
            duration: Duration(seconds: 50),
            type: 'Cardio'),
        const ExerciseStep(
            name: 'Rodillas altas',
            description:
                'Corre en el lugar elevando rodillas hasta el pecho de forma alternada, brazos coordinados.',
            duration: Duration(seconds: 50),
            type: 'Cardio'),
        const ExerciseStep(
            name: 'Jump squats',
            description:
                'Baja en sentadilla normal y al subir, impulsa tu cuerpo saltando lo más alto posible, aterriza suavemente y repite.',
            duration: Duration(seconds: 50),
            type: 'Cardio'),
        const ExerciseStep(
            name: 'Sprint en el lugar',
            description: 'Corre al máximo.',
            duration: Duration(seconds: 30),
            type: 'Cardio'),
      ],
    ),
    DailySession(
      day: 5,
      title: '🍑 Glúteos & Piernas (25 min)',
      motivationalQuote: 'Piernas fuertes te llevan a lugares altos.',
      exercises: const [
        // Added type for each exercise
        const ExerciseStep(
            name: 'Sentadilla sumo',
            description:
                'Piernas abiertas, pies ligeramente hacia afuera. Baja cadera manteniendo espalda recta y rodillas alineadas, sube controladamente.',
            reps: '15',
            duration: Duration(seconds: 45),
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Puente de glúteos',
            description:
                'Acostado boca arriba, pies apoyados, rodillas flexionadas. Eleva cadera contrayendo glúteos hasta formar línea recta hombros-cadera. Baja controladamente.',
            reps: '20',
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Donkey kicks',
            description:
                'A cuatro apoyos, eleva pierna flexionada hacia arriba manteniendo cadera estable, baja controlando. 15 por lado.',
            reps: '30',
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Side leg raises',
            description:
                'Acostado de lado, eleva y baja pierna superior controlando movimiento, abdomen activo, cadera estable. 15 por lado.',
            reps: '30',
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Zancadas',
            description:
                'Da un paso largo hacia adelante, flexiona ambas rodillas hasta formar ángulo de 90°. Mantén torso recto y vuelve al inicio. Alterna piernas. 12 por lado.',
            reps: '24',
            type: 'Fuerza'),
        const ExerciseStep(
            name: 'Pulse lunges',
            description:
                'Pequeños rebotes en posición de zancada. 20s por lado.',
            duration: Duration(seconds: 40),
            type: 'Fuerza'),
      ],
    ),
    DailySession(
      day: 6,
      title: '🧘 Flexibilidad & Movilidad (15 min)',
      motivationalQuote: 'Fluye con tu cuerpo, libera tu mente.',
      exercises: const [
        // Added type for each exercise
        const ExerciseStep(
            name: 'Cat-cow',
            description:
                'A cuatro apoyos, arquea espalda hacia arriba (gato) y luego baja cadera elevando torso (vaca), respira profundo.',
            duration: Duration(seconds: 60),
            type: 'Movilidad'),
        const ExerciseStep(
            name: 'Standing leg swings',
            description:
                'De pie, balancea pierna adelante-atrás alternando, torso estable, abdomen activo. 30s por lado.',
            duration: Duration(seconds: 60),
            type: 'Movilidad'),
        const ExerciseStep(
            name: 'Arm swings',
            description:
                'De pie, brazos cruzando frente al cuerpo y hacia atrás alternadamente, torso estable.',
            duration: Duration(seconds: 45),
            type: 'Movilidad'),
        const ExerciseStep(
            name: 'Good morning',
            description:
                'De pie, pies al ancho de hombros, manos detrás de cabeza. Inclina torso hacia adelante manteniendo espalda recta, regresa erguido.',
            duration: Duration(seconds: 60),
            type: 'Movilidad'),
        const ExerciseStep(
            name: 'Child’s pose',
            description:
                'De rodillas, inclina torso hacia adelante apoyando frente en suelo, brazos extendidos o relajados al costado, respira profundo.',
            duration: Duration(seconds: 90),
            type: 'Movilidad'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamientos Básicos'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _basicSessions.length,
        itemBuilder: (context, index) {
          final session = _basicSessions[index];
          return _WorkoutCard(
            session: session,
            onTap: () {
              // Se pasa planId como null ya que no son parte de un plan específico
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ExerciseMainScreenStyled(session: session),
              ));
            },
          );
        },
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final DailySession session;
  final VoidCallback onTap;

  const _WorkoutCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Extraer el emoji del título para usarlo como ícono
    final iconString = session.title.split(' ').first;
    final totalDuration = session.exercises.fold<Duration>(
      Duration.zero,
      (prev, element) =>
          prev +
          (element.duration ??
              const Duration(seconds: 45)), // Asumir 45s si es por reps
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(iconString, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                session.title.substring(iconString.length).trim(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                session.motivationalQuote,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '~${totalDuration.inMinutes} min',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  const Icon(Icons.fitness_center,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${session.exercises.length} ejercicios',
                    style: const TextStyle(color: Colors.grey),
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
