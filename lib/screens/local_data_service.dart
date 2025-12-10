import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:subefit/screens/local_auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'exercise_model.dart';

/// Servicio para gestionar el almacenamiento y la recuperación de datos locales en formato JSON.
///
/// Este servicio centraliza toda la lógica de lectura y escritura de archivos,
/// proporcionando una capa de abstracción para el resto de la aplicación.
///
/// Archivos gestionados:
/// - `users.json`: Almacena la lista de usuarios registrados localmente.
/// - `app_data_{userId}.json`: Almacena todos los datos específicos de un usuario
///   (puntos, niveles, historial, etc.).
class LocalDataService {
  // Singleton para asegurar una única instancia del servicio.
  static final LocalDataService _instance = LocalDataService._internal();
  factory LocalDataService() => _instance;
  LocalDataService._internal();

  /// Obtiene la ruta del directorio de documentos de la aplicación.
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Obtiene una referencia a un archivo JSON específico.
  Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  /// Lee el contenido de un archivo JSON.
  ///
  /// Devuelve un mapa decodificado si el archivo existe, o el [defaultValue] si no.
  Future<Map<String, dynamic>> readJsonFile(String fileName,
      {Map<String, dynamic> defaultValue = const {}}) async {
    // --- Implementación para la Web ---
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final contents = prefs.getString(fileName);
      if (contents == null) return defaultValue;
      debugPrint('readJsonFile (web): $fileName contents: $contents');
      return json.decode(contents) as Map<String, dynamic>;
    }

    // --- Implementación para Móvil/Escritorio ---
    try {
      final file = await _getLocalFile(fileName);
      if (!await file.exists()) {
        return defaultValue;
      }
      final contents = await file.readAsString();
      debugPrint('readJsonFile: $fileName contents: $contents');
      return json.decode(contents) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error al leer el archivo $fileName: $e');
      return defaultValue;
    }
  }

  /// Escribe un mapa de datos en un archivo JSON.
  ///
  /// Codifica el [data] a una cadena JSON y lo guarda en el archivo especificado.
  Future<void> writeJsonFile(String fileName, Map<String, dynamic> data) async {
    // --- Implementación para la Web ---
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data);
      await prefs.setString(fileName, jsonString);
      debugPrint('writeJsonFile (web): $fileName data: $jsonString');
      return;
    }
    // --- Implementación para Móvil/Escritorio ---
    try {
      final file = await _getLocalFile(fileName);
      final jsonString = json.encode(data);
      await file.writeAsString(jsonString);
      debugPrint('writeJsonFile: $fileName data: $jsonString');
    } catch (e) {
      debugPrint('Error al escribir en el archivo $fileName: $e');
    }
  }

  // --- Métodos específicos para datos de usuario ---

  /// Obtiene el nombre del archivo de datos para un usuario específico.
  String _userDataFileName(String userId) => 'app_data_$userId.json';

  /// Carga todos los datos de un usuario específico.
  Future<Map<String, dynamic>> loadUserData(String userId) async {
    return await readJsonFile(
      _userDataFileName(userId),
      defaultValue: {
        // Datos de perfil
        'weight': 70.0,
        'isProfileComplete': false, // Nuevo flag para el setup inicial
        'height': 175.0,
        'goals': 'Mejorar condición física',
        // Gamificación
        'points': {'fuerza': 0, 'resistencia': 0, 'flexibilidad': 0},
        'level': 1,
        'challengeLevel': 1,
        'difficultyFactor': 0.5,
        'history': [],
        'streak': 0,
        'lastWorkoutDate': null,
        'totalPoints': 0,
        // 'followers': 0, // Desactivado temporalmente
        'purchased_items': [], // NUEVO: Para la tienda
        // Configuración
        'settings': {
          'language': 'es',
          'voiceGender': 'Femenino',
          'theme': 'dark',
          'notifications': true,
          'tts_enabled': true,
          'units': 'metric'
        },
        // Otros
        'gps_routes': [], 'daily_goals': {}, 'training_plans_progress': {},
      },
      // Nuevo: Progreso de los planes de entrenamiento
    );
  }

  /// Guarda todos los datos de un usuario específico.
  Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    await writeJsonFile(_userDataFileName(userId), data);
  }

  /// Restablece el progreso del usuario a los valores iniciales.
  Future<void> resetUserProgress(String userId) async {
    final userData = await loadUserData(userId);

    // Claves a restablecer
    userData['points'] = {'fuerza': 0, 'resistencia': 0, 'flexibilidad': 0};
    userData['level'] = 1;
    userData['challengeLevel'] = 1;
    userData['history'] = [];
    userData['streak'] = 0;
    userData['lastWorkoutDate'] = null;
    userData['totalPoints'] = 0;
    // userData['followers'] = 0; // Desactivado temporalmente
    userData['gps_routes'] = [];
    userData['daily_goals'] = {};

    await saveUserData(userId, userData);
  }

  /// Actualiza una clave específica dentro de los datos de un usuario.
  ///
  /// Ejemplo: `updateUserKey('user123', 'level', 2)`
  Future<void> updateUserKey(String userId, String key, dynamic value) async {
    final userData = await loadUserData(userId);
    userData[key] = value;
    await saveUserData(userId, userData);
  }

  /// Carga los datos del usuario y calcula el nivel de desafío actual.
  Future<Map<String, dynamic>> loadAndProcessUserData(String userId) async {
    final userData = await loadUserData(userId);
    final lastWorkoutStr = userData['lastWorkoutDate'] as String?;
    final now = DateTime.now();
    int daysSinceWorkout = 0;

    if (lastWorkoutStr != null) {
      final lastWorkoutDate = DateTime.tryParse(lastWorkoutStr);
      if (lastWorkoutDate != null) {
        daysSinceWorkout = now.difference(lastWorkoutDate).inDays;
      }
    }
    userData['challengeLevel'] = (userData['level'] ?? 1) +
        (daysSinceWorkout > 1
            ? (daysSinceWorkout * (userData['difficultyFactor'] ?? 0.5)).round()
            : 0);
    return userData;
  }

  /// Añade un elemento a una lista dentro de los datos de un usuario.
  ///
  /// Ejemplo: `addUserListItem('user123', 'history', {'exercise': 'push-ups', 'reps': 10})`
  Future<void> addUserListItem(
      String userId, String listKey, dynamic item) async {
    final userData = await loadUserData(userId);
    if (userData[listKey] is List) {
      (userData[listKey] as List).add(item);
      await saveUserData(userId, userData);
    }
  }

  /// Actualiza la racha y los puntos del usuario después de un entrenamiento.
  Future<void> updateUserWorkoutData(String userId, int pointsEarned) async {
    final userData = await loadUserData(userId);
    final lastWorkoutStr = userData['lastWorkoutDate'] as String?;
    final now = DateTime.now();
    DateTime? lastWorkoutDate;

    if (lastWorkoutStr != null) {
      lastWorkoutDate = DateTime.tryParse(lastWorkoutStr);
    }

    int currentStreak = userData['streak'] ?? 0;

    if (lastWorkoutDate == null || now.difference(lastWorkoutDate).inDays > 1) {
      currentStreak = 1; // Se rompió la racha o es el primer entreno
    } else if (now.difference(lastWorkoutDate).inDays == 1) {
      currentStreak++; // Continúa la racha
    }

    userData['streak'] = currentStreak;
    userData['totalPoints'] = (userData['totalPoints'] ?? 0) + pointsEarned;
    userData['lastWorkoutDate'] = now.toIso8601String();

    // --- NUEVO: Lógica de Gamificación de Seguidores ---
    // Otorga seguidores basados en los puntos ganados (ej: 1 seguidor por cada 10 puntos)
    // userData['followers'] = (userData['followers'] ?? 0) + (pointsEarned / 10).round(); // Desactivado temporalmente
    await saveUserData(userId, userData);
  }

  /// Añade una entrada al historial de entrenamientos del usuario.
  Future<void> logWorkoutInHistory(
      String userId, Duration duration, int points, List<String> exercises,
      [DateTime? startTime]) async {
    final workoutSummary = {
      'date': (startTime ?? DateTime.now()).toIso8601String(),
      'duration': duration.inSeconds,
      'points': points,
      'exercises': exercises,
    };
    final userData = await loadUserData(userId);
    if (userData['history'] is! List) {
      userData['history'] = [];
    }
    (userData['history'] as List).add(workoutSummary);
    await saveUserData(userId, userData);
  }

  /// Permite al usuario comprar seguidores con puntos.
  /// Devuelve `true` si la compra fue exitosa, `false` si no.
  Future<bool> purchaseFollowers(
      String userId, int followersToGain, int pointCost) async {
    final userData = await loadUserData(userId);
    final currentPoints = userData['totalPoints'] ?? 0;

    if (currentPoints < pointCost) {
      return false; // Puntos insuficientes
    }

    userData['totalPoints'] = currentPoints - pointCost;
    // userData['followers'] = (userData['followers'] ?? 0) + followersToGain; // Desactivado temporalmente
    await saveUserData(userId, userData);
    return true;
  }

  /// Obtiene el perfil de un usuario específico desde el archivo `users.json`.
  /// Devuelve un objeto `LocalUser` o `null` si no se encuentra.
  Future<LocalUser?> getUserProfile(String userId) async {
    try {
      final usersData = await readJsonFile('users.json');
      final usersList = (usersData['users'] as List<dynamic>?) ?? [];
      final userJson =
          usersList.firstWhere((u) => u['id'] == userId, orElse: () => null);
      return userJson != null ? LocalUser.fromJson(userJson) : null;
    } catch (e) {
      debugPrint('Error al obtener el perfil del usuario $userId: $e');
      return null;
    }
  }

  /// Marca una sesión diaria de un plan como completada.
  Future<void> completeDailySession(
      String userId, String planId, int day) async {
    final userData = await loadUserData(userId);
    final plansProgress =
        userData['training_plans_progress'] as Map<String, dynamic>? ?? {};

    plansProgress[planId] = {
      'lastCompletedDay': day,
      'lastCompletedTimestamp': DateTime.now().toIso8601String(),
    };

    userData['training_plans_progress'] = plansProgress;
    await saveUserData(userId, userData);
  }

  /// Obtiene el progreso de un plan de entrenamiento específico.
  Future<Map<String, dynamic>?> getPlanProgress(
      String userId, String planId) async {
    final userData = await loadUserData(userId);
    final plansProgress = userData['training_plans_progress'];
    if (plansProgress is Map) {
      final planData = plansProgress[planId];
      if (planData is Map) {
        return Map<String, dynamic>.from(planData);
      }
    }
    return null;
  }

  // --- Métodos para Sesiones Interrumpidas ---

  /// Guarda el estado de una sesión de entrenamiento interrumpida.
  Future<void> saveInterruptedSession(
      String userId, Map<String, dynamic> sessionState) async {
    final fileName = 'interrupted_session_$userId.json';
    await writeJsonFile(fileName, sessionState);
  }

  /// Carga el estado de una sesión de entrenamiento interrumpida.
  /// Devuelve `null` si no hay ninguna sesión guardada.
  Future<Map<String, dynamic>?> loadInterruptedSession(String userId) async {
    final fileName = 'interrupted_session_$userId.json';
    final data = await readJsonFile(fileName, defaultValue: {});
    return data.isNotEmpty ? data : null;
  }

  /// Limpia el archivo de la sesión de entrenamiento interrumpida.
  Future<void> clearInterruptedSession(String userId) async {
    final fileName = 'interrupted_session_$userId.json';
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(fileName);
    } else {
      try {
        final file = await _getLocalFile(fileName);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error al limpiar la sesión interrumpida: $e');
      }
    }
  }
}

// --- Métodos para la librería de ejercicios ---

/// Carga la lista completa de ejercicios desde el archivo JSON en assets.
Future<List<Exercise>> loadExercises() async {
  try {
    final jsonString =
        await rootBundle.loadString('assets/data/exercises.json');
    final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;
    final exercisesList = jsonResponse['exercises'] as List;
    return exercisesList.map((data) => Exercise.fromJson(data)).toList();
  } catch (e) {
    print('Error al cargar los ejercicios: $e');
    return [];
  }
}
