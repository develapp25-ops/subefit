# 📸 Documentación: Sistema de Subida de Imágenes

## 🎯 Descripción General

El sistema ahora soporta subida de imágenes en **web + móvil** usando bytes (`Uint8List`) en lugar de archivos (`dart:io.File`).

---

## 📐 Arquitectura

```
User selects image → ImagePicker.pickImage() → readAsBytes() 
    ↓
Uint8List (bytes) → FirebaseService.uploadProfileImage/createPost()
    ↓
Firebase Storage.putData(bytes) → getDownloadURL()
    ↓
Firestore: guardar URL → Cloud Storage URL con acceso público
```

---

## 🔑 Componentes Clave

### 1. **UserDataModel** (`lib/screens/user_data_model.dart`)
```dart
class UserDataModel {
  // Avatar del usuario (en onboarding)
  Uint8List? avatarBytes;  // ← BYTES, no File
  
  // Otros datos...
}
```

### 2. **AvatarStep** (`lib/screens/avatar_step.dart`)
```dart
class _AvatarStepState extends State<AvatarStep> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;  // ← Guardamos bytes
  
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 80
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();  // ← Convertir a bytes
      setState(() {
        _imageBytes = bytes;
        widget.userData.avatarBytes = bytes;
      });
    }
  }
  
  // UI: mostrar preview
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
      // ↑ MemoryImage (no FileImage)
    );
  }
}
```

### 3. **FirebaseService** (`lib/screens/firebase_service.dart`)

#### Upload Avatar
```dart
Future<String> uploadProfileImage(
  String userId, 
  {
    Uint8List? imageBytes,  // ← Acepta bytes
    String contentType = 'image/jpeg'
  }
) async {
  try {
    if (imageBytes == null) throw Exception('No image data provided');
    
    // Referencia en Storage
    final ref = _storage.ref()
      .child('profile_images')
      .child('$userId.jpg');
    
    // Metadata
    final metadata = SettableMetadata(contentType: contentType);
    
    // Upload usando putData (compatible web/móvil)
    final uploadTask = await ref.putData(imageBytes, metadata);
    
    // Obtener URL descarga
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    
    return downloadUrl;  // Ej: https://storage.googleapis.com/...
  } catch (e) {
    debugPrint('Error al subir la imagen de perfil: $e');
    throw Exception('No se pudo subir la imagen.');
  }
}
```

#### Create Post with Image
```dart
Future<void> createPost({
  required String authorId,
  required String text,
  Uint8List? imageBytes,  // ← Imagen opcional
}) async {
  final postRef = _db.collection('Publicacion').doc();
  
  String? imageUrl;
  
  // Si hay imagen, subirla
  if (imageBytes != null) {
    try {
      final imageRef = _storage.ref()
        .child('post_images')
        .child('${postRef.id}.jpg');
      
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadSnapshot = await imageRef.putData(imageBytes, metadata);
      imageUrl = await uploadSnapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al subir la imagen de la publicación: $e');
      // Continuar sin imagen si falla
    }
  }
  
  // Crear documento en Firestore
  await postRef.set({
    'autorID': authorId,
    'texto': text,
    'fecha': FieldValue.serverTimestamp(),
    'likes': 0,
    'comentarios': 0,
    'publico': true,
    if (imageUrl != null) 'imageUrl': imageUrl,  // ← Si hay imagen
  });
  
  // Incrementar contador
  final userRef = _db.collection('Usuarios').doc(authorId);
  await userRef.update({'publicaciones': FieldValue.increment(1)});
}
```

### 4. **CreatePostScreen** (`lib/screens/create_post_screen.dart`)
```dart
class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  final _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _isUploading = false;
  
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }
  
  Future<void> _submitPost() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La publicación no puede estar vacía.'))
      );
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      await _firebaseService.createPost(
        authorId: user.uid,
        text: text,
        imageBytes: _imageBytes,  // ← Pasar imagen si la hay
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación creada con éxito'))
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Publicación'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitPost,
              child: _isUploading
                ? const CircularProgressIndicator()
                : const Text('Publicar'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Preview de imagen si existe
            if (_imageBytes != null)
              Column(
                children: [
                  Image.memory(
                    _imageBytes!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Cambiar imagen'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Agregar imagen'),
              ),
            
            const SizedBox(height: 20),
            
            // Text input
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '¿Qué estás pensando, atleta?',
                border: InputBorder.none,
              ),
              maxLines: 8,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔄 Flujo de Datos Completo

### Caso 1: Avatar en Onboarding
```
1. Usuario entra a AvatarStep
2. Toca CircleAvatar → abre Image Picker
3. Selecciona imagen de galería
4. pickImage() retorna XFile
5. Convertimos a bytes: readAsBytes()
6. Guardamos en UserDataModel.avatarBytes
7. Al finalizar wizard:
   - uploadProfileImage(userId, imageBytes: avatarBytes)
   - putData en Storage
   - getDownloadURL()
   - Guardamos en Firestore: Usuarios/{userId}.fotoUrl = URL
```

### Caso 2: Crear Publicación con Imagen
```
1. Usuario navega a CreatePostScreen
2. Toca "Agregar imagen"
3. Image Picker abre galería
4. Selecciona imagen
5. Convertimos a bytes: readAsBytes()
6. Guardamos en _imageBytes
7. Muestra preview con Image.memory(_imageBytes!)
8. Usuario escribe texto y toca "Publicar"
9. createPost(authorId, text, imageBytes)
   - createPost crea referencia en Storage
   - putData(bytes) → upload
   - getDownloadURL()
   - Crea Firestore doc con imageUrl
```

---

## 🛡️ Ventajas de la Solución

| Ventaja | Por Qué |
|---------|--------|
| ✅ **Multiplataforma** | `Uint8List` funciona en web, Android, iOS |
| ✅ **Sin dart:io** | No requiere platform-specific imports |
| ✅ **Estándar Firebase** | `putData` es la forma recomendada |
| ✅ **Eficiente** | Bytes se comprimen automáticamente |
| ✅ **Preview rápido** | `Image.memory()` muestra sin guardar archivo |
| ✅ **Escalable** | Fácil de añadir a otros elementos |

---

## ⚠️ Limitaciones Actuales

- **Tamaño máximo:** Sin validación client-side (Firebase limita a 5GB, pero recomendamos ~5MB para imágenes)
- **Compresión:** No se comprime antes de subir (Firebase lo hace, pero puede ser lento)
- **Caché:** Las URLs descargadas no se cachean localmente
- **Validación MIME:** Solo `image/jpeg` por defecto (se puede extender)

---

## 🔧 Cómo Extender

### Agregar Validación de Tamaño
```dart
if (bytes.length > 5 * 1024 * 1024) { // 5 MB
  throw Exception('Imagen muy grande (máx 5 MB)');
}
```

### Soportar Múltiples Formatos
```dart
SettableMetadata(
  contentType: isPNG ? 'image/png' : 'image/jpeg'
)
```

### Comprimir Antes de Subir
```dart
// Necesita: image package
import 'package:image/image.dart' as img;

final decoded = img.decodeImage(bytes);
final resized = img.copyResize(decoded, width: 800);
final compressed = img.encodeJpg(resized, quality: 80);
// Usar `compressed` en putData
```

---

## 📊 Firestore Schema

### Avatar en Usuarios
```
Collection: Usuarios
Doc: {userId}
{
  "fotoUrl": "https://storage.googleapis.com/.../profile_images/{userId}.jpg"
}
```

### Imagen en Publicación
```
Collection: Publicacion
Doc: {postId}
{
  "autorID": "{userId}",
  "texto": "...",
  "imageUrl": "https://storage.googleapis.com/.../post_images/{postId}.jpg",
  "fecha": timestamp,
  ...
}
```

---

## 🚨 Debugging

### Logs para Monitorear
```dart
// En firebase_service.dart
debugPrint('Uploading image: $userId');
debugPrint('Upload success: $downloadUrl');
debugPrint('Error uploading: $e');
```

### En Flutter Console
```bash
flutter run -v  # Verbose logs
```

---

## ✅ Checklist de Prueba

- [ ] Avatar sube y aparece en Firestore
- [ ] Avatar URL es válida (abre en navegador)
- [ ] Publicación sube sin imagen (backward compatible)
- [ ] Publicación sube con imagen
- [ ] Preview de imagen aparece antes de publicar
- [ ] Funciona en web (Chrome)
- [ ] Funciona en Android
- [ ] Funciona en iOS

---

**Fin de la Documentación**
