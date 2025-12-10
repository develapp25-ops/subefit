import 'package:flutter_tts/flutter_tts.dart';

enum TtsVoiceGender {
  Femenino,
  Masculino,
}

/// Servicio para gestionar la funcionalidad de Texto a Voz (Text-to-Speech).
///
/// Encapsula la instancia de FlutterTts y proporciona métodos simples para
/// hablar, detener y configurar el motor de voz.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  late final FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isVoiceEnabled = true; // Por defecto, la voz está activada

  TtsService._internal() {
    _flutterTts = FlutterTts();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("es-ES");
    // CORREGIDO: Se aumenta la velocidad de la voz a un valor más natural.
    // 0.5 es muy lento, 1.0 es normal. 0.8 es un buen punto intermedio.
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isInitialized = true;
  }

  /// Activa o desactiva la guía por voz.
  void toggleVoice(bool isEnabled) {
    _isVoiceEnabled = isEnabled;
    if (!_isVoiceEnabled) {
      stop(); // Si se desactiva, detiene cualquier locución actual.
    }
  }

  bool get isVoiceEnabled => _isVoiceEnabled;

  /// Convierte un texto a voz si la funcionalidad está activada.
  Future<void> speak(String text) async {
    if (_isInitialized && _isVoiceEnabled && text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  /// Detiene la locución actual.
  Future<void> stop() async => await _flutterTts.stop();

  /// Establece la voz preferida por el usuario.
  /// Esta es una implementación de ejemplo. En una app real, se guardarían las preferencias.
  void setVoice(String userId, TtsVoiceGender gender) {
    // Lógica para cambiar la voz. FlutterTts tiene opciones para seleccionar voces.
  }
}
