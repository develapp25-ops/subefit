# 🎬 GUÍA: Implementar Vista Previa de Ejercicios

## 📌 Objetivo
Cuando un usuario selecciona un ejercicio, ver:
1. **Video/GIF** de demostración
2. **Pasos** de la técnica correcta
3. **Advertencias** de seguridad
4. **Músculos** que trabajan
5. **Dificultad** y tiempo

Antes de presionar "Empezar Ejercicio"

---

## 🏗️ ARQUITECTURA

```
ExerciseDetailScreen
├── Video/GIF Player (YouTube, local, Giphy)
├── Info Card (músculos, tiempo, dificultad)
├── Steps (paso a paso)
├── Warnings (cuidados)
├── AI Coach (IA recomienda)
└── [Botón] Empezar
```

---

## 📁 ARCHIVOS A CREAR/MODIFICAR

### 1. **Actualizar Exercise Model**
```
lib/screens/exercise_model.dart
```

**Agregar campos:**
```dart
class Exercise {
  final String id;
  final String name;
  final String description;
  final String imageUrl;  // ← NUEVO: foto estática
  final String? videoUrl; // ← NUEVO: video demo
  final String? gifUrl;   // ← NUEVO: gif animado
  final List<String> targetMuscles; // ← NUEVO: pecho, espalda, etc
  final String difficulty; // NUEVO: principiante, intermedio, avanzado
  final Duration duration;
  final int? reps;
  final int points;
  final List<ExerciseStep> steps; // ← NUEVO: paso a paso
  final List<String> warnings; // ← NUEVO: precauciones
}

// NUEVO: Modelo de pasos
class ExerciseStep {
  final int position;
  final String description;
  final String imageUrl; // foto de la posición
}
```

### 2. **Crear ExerciseDetailScreen**
```
lib/screens/exercise_detail_screen.dart
```

**Estructura básica:**
```dart
class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  
  const ExerciseDetailScreen({
    required this.exercise,
    Key? key,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  int _currentStep = 0;
  bool _showSteps = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // 1. Video/GIF
            _buildMediaSection(),
            
            // 2. Nombre y dificultad
            _buildHeaderSection(),
            
            // 3. Músculos y tiempo
            _buildInfoCards(),
            
            // 4. Pasos
            _buildStepsSection(),
            
            // 5. Advertencias
            _buildWarningsSection(),
            
            // 6. Botones
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}
```

### 3. **Crear VideoPlayer Component**
```
lib/widgets/exercise_video_player.dart
```

**Opciones:**
- **Local**: reproducir MP4 descargado
- **YouTube**: video_player + youtube_player_flutter
- **Remote URL**: video_player (HTTP)
- **GIF**: Image.network con CachedNetworkImage

**Recomendación:** Usar `video_player` + fallback a GIF

```dart
class ExerciseVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final String? gifUrl;
  final String imageUrl; // fallback estático

  const ExerciseVideoPlayer({
    this.videoUrl,
    this.gifUrl,
    required this.imageUrl,
    Key? key,
  }) : super(key: key);

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  late VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    if (widget.videoUrl != null) {
      _videoController = VideoPlayerController.network(widget.videoUrl!)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si hay video, reproducir
    if (_videoController?.value.isInitialized ?? false) {
      return GestureDetector(
        onTap: () => setState(() {
          _isPlaying ? _videoController!.pause() : _videoController!.play();
          _isPlaying = !_isPlaying;
        }),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            if (!_isPlaying)
              Positioned.fill(
                child: Center(
                  child: Icon(Icons.play_circle,
                      size: 80, color: Colors.white.withOpacity(0.7)),
                ),
              ),
          ],
        ),
      );
    }
    
    // Fallback a GIF
    if (widget.gifUrl != null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[300],
        ),
        child: Image.network(
          widget.gifUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress != null ? const CircularProgressIndicator() : child,
        ),
      );
    }
    
    // Fallback a imagen estática
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[300],
      ),
      child: Image.network(
        widget.imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
```

### 4. **Crear StepsCarousel Component**
```
lib/widgets/exercise_steps_carousel.dart
```

**Para mostrar paso a paso:**
```dart
class ExerciseStepsCarousel extends StatefulWidget {
  final List<ExerciseStep> steps;

  const ExerciseStepsCarousel({
    required this.steps,
    Key? key,
  }) : super(key: key);

  @override
  State<ExerciseStepsCarousel> createState() => _ExerciseStepsCarouselState();
}

class _ExerciseStepsCarouselState extends State<ExerciseStepsCarousel> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final step = widget.steps[_currentStep];

    return Column(
      children: [
        Text(
          'Paso ${_currentStep + 1} de ${widget.steps.length}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[200],
          ),
          child: Image.network(
            step.imageUrl,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: _currentStep > 0
                  ? () => setState(() => _currentStep--)
                  : null,
              child: const Text('← Anterior'),
            ),
            ElevatedButton(
              onPressed: _currentStep < widget.steps.length - 1
                  ? () => setState(() => _currentStep++)
                  : null,
              child: const Text('Siguiente →'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## 🔥 DEPENDENCIAS A AGREGAR EN pubspec.yaml

```yaml
dependencies:
  video_player: ^2.8.0
  cached_network_image: ^3.3.0
  youtube_player_flutter: ^9.0.0  # opcional
  shimmer: ^3.0.0  # loading effect
```

```bash
flutter pub add video_player cached_network_image shimmer
```

---

## 📊 DATOS EN FIREBASE

### Estructura recomendada:

```
exercises/
├── {exerciseId}/
│   ├── name: "Flexiones"
│   ├── description: "Empuja tu cuerpo hacia arriba..."
│   ├── imageUrl: "gs://bucket/exercises/pushup.jpg"
│   ├── videoUrl: "gs://bucket/videos/pushup.mp4"
│   ├── gifUrl: "https://media.giphy.com/..."
│   ├── difficulty: "principiante"
│   ├── duration: 30
│   ├── reps: 10
│   ├── targetMuscles: ["pecho", "tríceps", "hombros"]
│   ├── warnings: [
│       "No bloquees los codos",
│       "Controla la respiración",
│       "Si sientes dolor en articulaciones, para"
│     ]
│   └── steps/
│       ├── step_1/
│       │   ├── position: 1
│       │   ├── description: "Posición inicial: acuéstate boca abajo..."
│       │   └── imageUrl: "gs://..."
│       ├── step_2/
│       │   ├── position: 2
│       │   ├── description: "Baja lentamente..."
│       │   └── imageUrl: "gs://..."
│       └── step_3/
│           ├── position: 3
│           ├── description: "Sube completamente..."
│           └── imageUrl: "gs://..."
```

---

## 🚀 IMPLEMENTACIÓN PASO A PASO

### Paso 1: Actualizar Exercise Model (30 min)
```dart
// lib/screens/exercise_model.dart
class Exercise {
  // ... fields existentes ...
  final String imageUrl;
  final String? videoUrl;
  final String? gifUrl;
  final List<String> targetMuscles;
  final String difficulty;
  final List<ExerciseStep> steps;
  final List<String> warnings;
  
  // Constructor actualizado
  Exercise({
    required this.id,
    // ... otros campos ...
    required this.imageUrl,
    this.videoUrl,
    this.gifUrl,
    required this.targetMuscles,
    required this.difficulty,
    required this.steps,
    required this.warnings,
  });
  
  // Factory para Firebase
  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name: data['name'] ?? 'Ejercicio',
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'],
      gifUrl: data['gifUrl'],
      targetMuscles: List<String>.from(data['targetMuscles'] ?? []),
      difficulty: data['difficulty'] ?? 'intermedio',
      steps: (data['steps'] as List?)?.map((s) => 
        ExerciseStep.fromMap(s)
      ).toList() ?? [],
      warnings: List<String>.from(data['warnings'] ?? []),
      // ... otros campos ...
    );
  }
}

class ExerciseStep {
  final int position;
  final String description;
  final String imageUrl;
  
  ExerciseStep({
    required this.position,
    required this.description,
    required this.imageUrl,
  });
  
  factory ExerciseStep.fromMap(Map<String, dynamic> map) {
    return ExerciseStep(
      position: map['position'] ?? 0,
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
```

### Paso 2: Crear ExerciseDetailScreen (1 hora)
```dart
// lib/screens/exercise_detail_screen.dart
// (Ver código completo abajo)
```

### Paso 3: Crear VideoPlayer Widget (30 min)
```dart
// lib/widgets/exercise_video_player.dart
// (Ver código completo arriba)
```

### Paso 4: Crear StepsCarousel Widget (30 min)
```dart
// lib/widgets/exercise_steps_carousel.dart
// (Ver código completo arriba)
```

### Paso 5: Integrar en WorkoutListScreen (15 min)
```dart
// lib/screens/workout_list_screen.dart

// Cambiar esto:
// Navigator.of(context).push(MaterialPageRoute(
//   builder: (_) => ExerciseMainScreenStyled(...),
// ));

// Por esto:
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => ExerciseDetailScreen(
    exercise: exercise,
    onStartWorkout: () {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ExerciseMainScreenStyled(...),
      ));
    },
  ),
));
```

---

## 💻 CÓDIGO COMPLETO: ExerciseDetailScreen

```dart
// lib/screens/exercise_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'exercise_model.dart';
import '../widgets/exercise_video_player.dart';
import '../widgets/exercise_steps_carousel.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onStartWorkout;

  const ExerciseDetailScreen({
    required this.exercise,
    required this.onStartWorkout,
    Key? key,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Video/GIF
            ExerciseVideoPlayer(
              imageUrl: widget.exercise.imageUrl,
              videoUrl: widget.exercise.videoUrl,
              gifUrl: widget.exercise.gifUrl,
            ),
            const SizedBox(height: 24),

            // Nombre y dificultad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(widget.exercise.difficulty),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.exercise.difficulty,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Músculos y tiempo
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  icon: Icons.timer,
                  label: '${widget.exercise.duration}s',
                ),
                if (widget.exercise.reps != null)
                  _buildInfoChip(
                    icon: Icons.repeat,
                    label: '${widget.exercise.reps} reps',
                  ),
                ...widget.exercise.targetMuscles.map(
                  (muscle) => _buildInfoChip(
                    icon: Icons.fitness_center,
                    label: muscle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Descripción
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.exercise.description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pasos
            if (widget.exercise.steps.isNotEmpty) ...[
              const Text(
                'Técnica Correcta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ExerciseStepsCarousel(
                    steps: widget.exercise.steps,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Advertencias
            if (widget.exercise.warnings.isNotEmpty) ...[
              const Text(
                'Advertencias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.exercise.warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(warning),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Botón Empezar
            ElevatedButton(
              onPressed: widget.onStartWorkout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: SubefitColors.primaryRed,
              ),
              child: const Text(
                'Empezar Ejercicio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'principiante':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
```

---

## ✅ CHECKLIST IMPLEMENTACIÓN

- [ ] Agregar dependencias (video_player, cached_network_image)
- [ ] Actualizar Exercise model con campos nuevos
- [ ] Crear ExerciseVideoPlayer widget
- [ ] Crear ExerciseStepsCarousel widget
- [ ] Crear ExerciseDetailScreen
- [ ] Subir imágenes a Firebase Storage
- [ ] Actualizar ejercicios en Firebase con URLs
- [ ] Agregar steps y warnings a ejercicios en Firebase
- [ ] Integrar ExerciseDetailScreen en WorkoutListScreen
- [ ] Probar en web y mobile
- [ ] Agregar loading states
- [ ] Optimizar imágenes (thumbnails, compresión)

---

## 📌 NOTAS

**Próximas mejoras:**
- [ ] Análisis de forma con AI (pose detection)
- [ ] Video player con velocidad variable (0.5x, 1x, 1.5x, 2x)
- [ ] Descargar videos para offline
- [ ] Sistema de favoritos de ejercicios
- [ ] Compartir tutorial con amigos
- [ ] Comentarios/preguntas en ejercicios

