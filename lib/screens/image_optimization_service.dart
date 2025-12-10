import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

/// Servicio para optimizar imágenes antes de subir a Firebase.
class ImageOptimizationService {
  static const int maxWidth = 500;
  static const int maxHeight = 500;
  static const int maxFileSizeKb = 200;

  /// Comprime y redimensiona una imagen desde File.
  /// Retorna Uint8List comprimido o null si hay error.
  static Future<Uint8List?> optimizeImageFromFile(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return optimizeImageBytes(bytes);
    } catch (e) {
      debugPrint('Error reading image file: $e');
      return null;
    }
  }

  /// Comprime y redimensiona Uint8List.
  static Future<Uint8List?> optimizeImageBytes(Uint8List bytes) async {
    try {
      // Decodificar imagen
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('Failed to decode image');
        return null;
      }

      // Redimensionar manteniendo aspecto
      img.Image resized = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        interpolation: img.Interpolation.linear,
      );

      // Codificar a JPG con compresión
      var compressed = img.encodeJpg(resized, quality: 75);

      // Validar tamaño
      if (compressed.length > maxFileSizeKb * 1024) {
        // Si aún es muy grande, reducir calidad más
        compressed = img.encodeJpg(resized, quality: 50);
        debugPrint('Reduced quality to 50 due to size constraints');
      }

      debugPrint(
        'Image optimized: ${bytes.length ~/ 1024}KB -> ${compressed.length ~/ 1024}KB',
      );
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return null;
    }
  }

  /// Valida que la imagen sea válida (formato, tamaño).
  static bool isValidImageFormat(File file) {
    final name = file.path.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.gif');
  }

  /// Obtiene el tamaño de un archivo en KB.
  static Future<int> getFileSizeKb(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return bytes.length ~/ 1024;
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }
}
