# ⚡ QUICK START - Comienza en 5 minutos

> Si quieres empezar a implementar YA, sin leer todo, aquí está lo mínimo que necesitas

---

## 🎬 Quieres: Implementar Vista Previa de Ejercicios

**Tiempo total: 6.5 horas**  
**Impacto: +40% engagement**  
**Dificultad: Media**

---

## 📋 PASOS EN ORDEN

### PASO 1: Instala dependencias (5 min)
```bash
cd /home/estevan/Escritorio/subefit
flutter pub add video_player cached_network_image shimmer
flutter pub get
```

### PASO 2: Copia los componentes (15 min)
Abre `EXERCISE_PREVIEW_GUIDE.md` y copia:

1. **ExerciseVideoPlayer** → `lib/widgets/exercise_video_player.dart`
2. **ExerciseStepsCarousel** → `lib/widgets/exercise_steps_carousel.dart`
3. **ExerciseDetailScreen** → `lib/screens/exercise_detail_screen.dart`

*Todo el código ya está ahí. Solo copiar-pegar.*

### PASO 3: Actualiza Exercise Model (20 min)
En `lib/screens/exercise_model.dart`, agrega esto:

```dart
class Exercise {
  final String id;
  final String name;
  final String description;
  final String imageUrl;           // ← NUEVO
  final String? videoUrl;          // ← NUEVO
  final String? gifUrl;            // ← NUEVO
  final List<String> targetMuscles; // ← NUEVO
  final String difficulty;          // ← NUEVO: principiante|intermedio|avanzado
  final Duration duration;
  final int? reps;
  final int points;
  final List<ExerciseStep> steps; // ← NUEVO (copiar de guide)
  final List<String> warnings;    // ← NUEVO: advertencias
  
  // ... resto igual ...
}

// Agrega esta clase:
class ExerciseStep {
  final int position;
  final String description;
  final String imageUrl;
  
  ExerciseStep({
    required this.position,
    required this.description,
    required this.imageUrl,
  });
}
```

### PASO 4: Integra en tu app (15 min)
En `lib/screens/workout_list_screen.dart`, cambia:

**DE:**
```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => ExerciseMainScreenStyled(/* ... */),
));
```

**A:**
```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => ExerciseDetailScreen(
    exercise: exercise,
    onStartWorkout: () {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ExerciseMainScreenStyled(/* ... */),
      ));
    },
  ),
));
```

### PASO 5: Sube imágenes a Firebase Storage (1 hora)
1. Ve a: https://console.firebase.google.com
2. Click: Storage → Create bucket (si no existe)
3. Sube carpeta: `exercises/` con imágenes

```
gs://subefit-427cc.appspot.com/
└── exercises/
    ├── pushup.jpg
    ├── squat.jpg
    ├── plank.jpg
    └── ...
```

### PASO 6: Actualiza Firebase con datos nuevos (1 hora)
En Firestore, edita cada ejercicio:

```
exercises/pushup/
  ├── name: "Flexiones"
  ├── description: "Empuja tu cuerpo hacia arriba..."
  ├── imageUrl: "gs://subefit-427cc.appspot.com/exercises/pushup.jpg"
  ├── videoUrl: "https://..."  // opcional
  ├── difficulty: "principiante"
  ├── targetMuscles: ["pecho", "tríceps", "hombros"]
  ├── warnings: [
      "No bloquees los codos",
      "Si sientes dolor, para"
    ]
  └── steps: [
      {position: 1, description: "Acuéstate boca abajo...", imageUrl: "..."},
      {position: 2, description: "Baja lentamente...", imageUrl: "..."}
    ]
```

### PASO 7: Prueba en web (15 min)
```bash
flutter run -d chrome
```

1. Navega a una rutina
2. Haz click en un ejercicio
3. Deberías ver el tutorial completo

### PASO 8: Prueba en mobile (15 min)
```bash
flutter run  # Android/iOS
```

---

## ✅ CHECKLIST

- [ ] `flutter pub add video_player cached_network_image shimmer`
- [ ] Creé `lib/widgets/exercise_video_player.dart`
- [ ] Creé `lib/widgets/exercise_steps_carousel.dart`
- [ ] Creé `lib/screens/exercise_detail_screen.dart`
- [ ] Actualicé `lib/screens/exercise_model.dart`
- [ ] Integré en `workout_list_screen.dart`
- [ ] Subí imágenes a Firebase Storage
- [ ] Actualicé datos en Firestore (ejercicios)
- [ ] Probé en web (`flutter run -d chrome`)
- [ ] Probé en mobile (`flutter run`)
- [ ] Sin errores en `flutter analyze`

---

## 🐛 Si hay errores

**Error: "ExerciseVideoPlayer not found"**
```
→ Revisá que creaste lib/widgets/exercise_video_player.dart
→ Revisá imports en exercise_detail_screen.dart
```

**Error: "Video no se reproduce"**
```
→ Revisá que la URL en Firebase es correcta
→ Prueba con una URL de video pública (YouTube)
```

**Error: "El video es muy grande"**
```
→ Comprime el video: ffmpeg -i input.mp4 -vcodec h264 -acodec aac output.mp4
→ O usa GIF en lugar de video
```

---

## 📊 RESULTADO ESPERADO

**Antes:**
```
Usuario clickea "Flexiones"
        ↓
[Plantalla de ejercicio] ← Solo números
Usuario: "¿Cómo se hace?"
        ↓
Abandona la sesión ❌
```

**Después:**
```
Usuario clickea "Flexiones"
        ↓
[Pantalla de tutorial] 
  • Video demo (30 seg)
  • Paso 1: Posición inicial (foto)
  • Paso 2: Bajada (foto)
  • Paso 3: Subida (foto)
  • Advertencias: "No bloquees codos"
  • Músculos: Pecho, Tríceps, Hombros
  • [Botón] Empezar Ejercicio
        ↓
Usuario ahora ENTIENDE
        ↓
Completa toda la sesión ✅
```

---

## 🚀 SIGUIENTE

Una vez funcione, tienes 2 opciones:

**Opción A:** Sistema de Progresión (siguiente feature)
- Tracking de pesos/reps
- Gráficas de progreso
- Personal Records
- Tiempo: 6.5h

**Opción B:** Gamificación
- Niveles (1-100)
- Badges de logros
- Rachas 🔥
- Tiempo: 7h

---

## 📞 ¿NECESITAS AYUDA?

1. Error en código → Lee `EXERCISE_PREVIEW_GUIDE.md` (sección completa)
2. Error en Firebase → Lee `NEXT_STEPS.md` (sección Storage Rules)
3. Error de dependencias → Ejecuta `flutter pub get`

---

**¿Listo para empezar?** 🚀

Siguiente comando:
```bash
flutter pub add video_player cached_network_image shimmer
```

¡Dale! 💪
