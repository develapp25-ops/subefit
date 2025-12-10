# 🚀 GUÍA DE PRUEBA - Vista Previa de Ejercicios

**Fecha:** 28 de noviembre de 2025  
**Estado:** ✅ IMPLEMENTACIÓN COMPLETADA

---

## 📋 Qué se implementó

- ✅ 3 componentes Flutter nuevos
- ✅ 18 imágenes generadas automáticamente
- ✅ Integración en workout_list_screen.dart
- ✅ 0 errores críticos (flutter analyze: OK)

---

## 🎯 Cómo probar

### OPCIÓN A: Probar en WEB (más rápido)

```bash
cd /home/estevan/Escritorio/subefit
flutter run -d chrome
```

**Pasos:**
1. La app abre en Chrome
2. Haz login (email + password)
3. Ve al menú → "Rutinas"
4. Elige una categoría (ej: "Fuerza")
5. **CLICKEA UN EJERCICIO** (ej: "Flexiones")
6. **¡VERÁS EL TUTORIAL!** 🎬

**Qué deberías ver:**
- Pantalla con imagen del ejercicio
- Nombre "Flexiones"
- Badge "Principiante"
- Tiempo: 30s | Reps: 10 | Pecho
- Descripción del ejercicio
- Sección "Técnica Correcta" con 3 pasos
- Paso 1: Posición inicial (imagen)
- Botones: Anterior | Siguiente
- Sección de "Advertencias de Seguridad"
- Botón rojo "Empezar Ejercicio"

---

### OPCIÓN B: Probar en MOBILE (Android/iOS)

```bash
cd /home/estevan/Escritorio/subefit
flutter run
```

**Lo mismo que en web, pero en tu teléfono**

---

## 🧪 Checklist de Verificación

Mientras pruebas, verifica esto:

### Navegación
- [ ] Clickea "Rutinas" → Ves categorías
- [ ] Clickea categoría → Ves lista de ejercicios
- [ ] Clickea ejercicio → Se abre tutorial

### Pantalla de Tutorial
- [ ] Ves imagen del ejercicio arriba
- [ ] Ves nombre del ejercicio
- [ ] Ves dificultad (coloreada)
- [ ] Ves chips: tiempo, reps, músculos
- [ ] Ves descripción

### Pasos Paso a Paso
- [ ] Ves "Paso 1 de 3"
- [ ] Ves imagen del paso
- [ ] Botón "Anterior" está deshabilitado (paso 1)
- [ ] Presiona "Siguiente" → Paso 2
- [ ] Ves diferente imagen
- [ ] Presiona "Siguiente" → Paso 3
- [ ] Presiona "Anterior" → Vuelve a Paso 2
- [ ] Botón "Siguiente" deshabilitado en paso 3

### Advertencias
- [ ] Ves sección "⚠️ Advertencias de Seguridad"
- [ ] Ves 3 advertencias específicas para el ejercicio
- [ ] Están en una tarjeta roja/rosa

### Acción
- [ ] Presiona "Empezar Ejercicio"
- [ ] Se cierra tutorial
- [ ] Comienza sesión normal de entrenamiento

---

## 🐛 Posibles Problemas y Soluciones

### Problema: No veo las imágenes
**Solución:**
```bash
# Limpia el caché
flutter clean
flutter pub get
flutter run -d chrome
```

### Problema: "Image not found" error
**Significa:** La ruta no coincide con el nombre del ejercicio
**Solución:**
- Verifica: `assets/exercises/flexiones_step1.png` existe
- Si el ejercicio se llama "Flexiones de pecho", no encontrará "flexiones de pecho_step1.png"

### Problema: Los botones no funcionan
**Solución:**
```bash
# Reconstruye la app
flutter clean
flutter run -d chrome
```

### Problema: Crash al clickear un ejercicio
**Solución:**
```bash
# Revisa los logs
flutter logs

# O con más detalle
flutter run -d chrome -v
```

---

## 📊 Verificación Técnica

Antes de probar, verifica:

```bash
# 1. Errores de compilación
cd /home/estevan/Escritorio/subefit
flutter analyze

# Debe mostrar: 0 errors

# 2. Imágenes existen
ls -la assets/exercises/ | wc -l

# Debe mostrar: más de 18 (archivos + . y ..)

# 3. Archivos creados
ls -la lib/widgets/exercise_*.dart
ls -la lib/screens/exercise_detail_screen.dart

# Deben existir los 3 archivos
```

---

## 🎬 Screencast: Cómo se ve

Cuando hagas click en un ejercicio:

```
┌──────────────────────────────────┐
│ ← Flexiones                      │
├──────────────────────────────────┤
│ ┌────────────────────────────┐  │
│ │   [Imagen: Flexiones]      │  │
│ │   400x500px                │  │
│ └────────────────────────────┘  │
│                                  │
│ Flexiones     [Principiante]    │
│                                  │
│ ⏱ 30s | 📋 10 reps | 💪 Pecho  │
│                                  │
│ DESCRIPCIÓN                     │
│ Empuja tu cuerpo hacia arriba   │
│                                  │
│ TÉCNICA CORRECTA (PASO A PASO)  │
│ ─────────────────────────────   │
│ Paso 1 de 3                     │
│ [Imagen: inicio]                │
│ "Acuéstate boca abajo..."       │
│ [Anterior] [Siguiente]          │
│                                  │
│ ⚠️ ADVERTENCIAS DE SEGURIDAD     │
│ • No bloquees los codos         │
│ • Mantén cuerpo recto           │
│ • Controla la respiración       │
│                                  │
│       [EMPEZAR EJERCICIO]       │
└──────────────────────────────────┘
```

---

## 📝 Ejercicios Disponibles para Probar

Con imágenes incluidas:
- Flexiones (3 pasos)
- Sentadillas (3 pasos)
- Planchas (3 pasos)
- Burpees (3 pasos)
- Abdominales (3 pasos)
- Dominadas (3 pasos)

---

## ✅ Resumen

| Componente | Estado | Ubicación |
|-----------|--------|-----------|
| ExerciseVideoPlayer | ✅ Listo | lib/widgets/ |
| ExerciseStepsCarousel | ✅ Listo | lib/widgets/ |
| ExerciseDetailScreen | ✅ Listo | lib/screens/ |
| Integración | ✅ Listo | workout_list_screen.dart |
| Imágenes | ✅ 18 creadas | assets/exercises/ |
| Compilación | ✅ OK | 0 errores |

---

## 🎯 Siguientes Pasos (Después de Probar)

1. **Si todo funciona:**
   - Agregar más imágenes para otros ejercicios
   - Crear componente para editar advertencias desde Firebase
   - Agregar videos en lugar de solo imágenes

2. **Si hay problemas:**
   - Ejecuta `flutter doctor`
   - Revisa `flutter logs`
   - Limpia con `flutter clean`

---

**¡Listo para probar!** 🚀

Comando para empezar:
```bash
cd /home/estevan/Escritorio/subefit && flutter run -d chrome
```

Luego: Login → Rutinas → Elige categoría → Clickea ejercicio → ¡VES EL TUTORIAL!
