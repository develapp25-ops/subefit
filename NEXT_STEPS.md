# Guía Rápida: Próximos Pasos para Subefit

## 🎯 Trabajo Completado

✅ Subida de imágenes funcional en web + móvil  
✅ Limpieza de archivos corruptos  
✅ Firebase Storage configurado  
✅ GitHub Actions CI/CD listo  
✅ Análisis estático completado  

---

## 🚀 Para Probar Ahora Mismo

### 1. Habilitar Firebase Storage Rules
```
1. Ve a: https://console.firebase.google.com
2. Proyecto: subefit-427cc
3. Storage → Rules
4. Reemplaza con:

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}

5. Publica
```

### 2. Ejecutar la App
```bash
# Para Android/iOS
flutter run

# Para Web
flutter run -d chrome
```

### 3. Probar Flujo Completo
- **Registro** → Llenar datos → **Avatar** (selecciona imagen) → Completar  
- **Social** → **Crear Publicación** → "Agregar imagen" → Publica

---

## 📝 Tareas para la Próxima Semana

### Alta Prioridad
- [ ] **Challenge Model:** Crear `lib/models/challenge_model.dart` o actualizar imports  
- [ ] **Colores faltantes:** Añadir `accentCyan` y `textWhite70` a `SubefitColors`  
- [ ] **Tests unitarios:** Para `FirebaseService` (upload functions)

### Media Prioridad
- [ ] Reemplazar `withOpacity()` → `.withValues()` en toda la app  
- [ ] Actualizar Radio Button deprecations  
- [ ] Comprimir imágenes antes de subir (opcional)

### Baja Prioridad
- [ ] Cacheo de imágenes descargadas  
- [ ] Optimizar tamaño de bundle  
- [ ] Documentación de API

---

## 🔒 Seguridad Checklist

- [ ] Revisa reglas de Firestore (¿solo usuarios autenticados pueden leer/escribir?)
- [ ] Revisa reglas de Storage (arriba)
- [ ] Configura rate limiting en Firebase
- [ ] Valida tamaño de archivo en client (máx 5 MB recomendado)

---

## 📊 Métricas Actuales

- **Errores de análisis:** 0 críticos
- **Warnings:** ~300 (la mayoría deprecations y imports no existentes)
- **Cobertura de tests:** Sin datos (necesita test suite)
- **CI/CD:** ✅ Activo en `.github/workflows/flutter_analyze.yml`

---

## 🆘 Si Algo Falla

### Error: "Firebase Storage not enabled"
→ Ve a Console → Storage → Crea bucket si no existe

### Error: "Permission denied" al subir
→ Chequea reglas de Storage (sección arriba)

### Error: "dart:io not available"
→ No debería ocurrir; si pasa, verifica imports en files

### Error: Image Picker no funciona en web
→ Añade a `web/index.html` dentro de `<head>`:
```html
<script src="https://cdn.jsdelivr.net/npm/file_picker_web/dist/file_picker_web.js"></script>
```

---

## 📚 Referencias

- [Flutter Image Picker](https://pub.dev/packages/image_picker)
- [Firebase Storage Flutter](https://firebase.google.com/docs/storage/start)
- [Flutter Web](https://flutter.dev/docs/deployment/web)

---

**¡Listo para empezar!** 🚀
