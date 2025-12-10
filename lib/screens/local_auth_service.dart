import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subefit/screens/local_data_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

/// Excepción personalizada para errores de autenticación.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Modelo para representar un usuario local.
class LocalUser {
  final String id;
  final String email;
  final String
      hashedPassword; // En un caso real, esto debería ser un hash seguro.
  String? displayName;
  String? photoUrl;
  final bool isAnonymous;

  LocalUser({
    required this.id,
    required this.email,
    required this.hashedPassword,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'hashedPassword': hashedPassword,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'isAnonymous': isAnonymous,
      };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
        id: json['id'],
        email: json['email'],
        hashedPassword: json['hashedPassword'],
        displayName: json['displayName'],
        photoUrl: json['photoUrl'],
        isAnonymous: json['isAnonymous'] ?? false,
      );
}

/// Servicio para gestionar la autenticación local de usuarios.
///
/// Reemplaza la funcionalidad de FirebaseAuth para un entorno sin conexión.
/// Utiliza `LocalDataService` para persistir la información de los usuarios.
class LocalAuthService extends ChangeNotifier {
  // NOTA: Se asume que LocalDataService está disponible o se creará.
  final LocalDataService _dataService = LocalDataService();
  LocalUser? _currentUser;

  LocalUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  LocalAuthService() {
    _loadCurrentUser();
  }

  /// Carga el usuario actual desde SharedPreferences al iniciar la app.
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    if (userId != null) {
      final usersData = await _dataService.readJsonFile('users.json');
      final usersList = (usersData['users'] as List<dynamic>?) ?? [];
      final userJson =
          usersList.firstWhere((u) => u['id'] == userId, orElse: () => null);
      if (userJson != null) {
        _currentUser = LocalUser.fromJson(userJson);
        notifyListeners();
      }
    }
  }

  /// Inicia sesión con correo y contraseña.
  Future<bool> login(String email, String password) async {
    final usersData = await _dataService.readJsonFile('users.json');
    final usersList = (usersData['users'] as List<dynamic>?) ?? [];
    final userJson = usersList.firstWhere(
        (u) =>
            u['email'] == email &&
            u['hashedPassword'] == password, // Simplificado: sin hashing real
        orElse: () => null);

    if (userJson != null) {
      _currentUser = LocalUser.fromJson(userJson);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', _currentUser!.id);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Registra un nuevo usuario.
  Future<LocalUser?> register(String email, String password, String displayName,
      [String? photoUrl]) async {
    final usersData = await _dataService.readJsonFile('users.json');
    // Si 'users' no existe, creamos una lista vacía para evitar un error de null.
    final usersList = (usersData['users'] as List<dynamic>?) ?? [];

    if (usersList.any((u) => u['email'] == email)) {
      throw AuthException('El correo ya está en uso.');
    }

    final newUser = LocalUser(
      id: const Uuid().v4(),
      email: email,
      hashedPassword: password, // Simplificado: sin hashing real
      displayName: displayName,
      photoUrl: photoUrl,
    );

    usersList.add(newUser.toJson());
    await _dataService.writeJsonFile('users.json', {'users': usersList});

    // Después de registrar, iniciamos sesión automáticamente con el nuevo usuario.
    _currentUser = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', _currentUser!.id);
    notifyListeners();
    return newUser;
  }

  /// Actualiza el nombre de un usuario.
  Future<void> updateUserDisplayName(
      String userId, String newDisplayName) async {
    final usersData = await _dataService.readJsonFile('users.json');
    final usersList = (usersData['users'] as List<dynamic>);

    final userIndex = usersList.indexWhere((u) => u['id'] == userId);
    if (userIndex != -1) {
      usersList[userIndex]['displayName'] = newDisplayName;
      await _dataService.writeJsonFile('users.json', {'users': usersList});

      // Si el usuario actualizado es el actual, actualizamos la instancia en memoria.
      if (_currentUser?.id == userId) {
        _currentUser?.displayName = newDisplayName;
        notifyListeners();
      }
    }
  }

  /// Inicia sesión con una cuenta de Google y la registra localmente.
  ///
  /// En web, espera un `idToken` para decodificar. En móvil, usa el flujo estándar.
  Future<LocalUser?> signInWithGoogle({String? idToken}) async {
    try {
      GoogleSignInAccount? googleUser;
      Map<String, dynamic>? tokenPayload;

      if (idToken != null) {
        // --- Flujo Web ---
        // Decodificamos el token JWT para obtener los datos del usuario.
        // Esto evita hacer una llamada extra a la API de Google.
        final parts = idToken.split('.');
        if (parts.length != 3) throw AuthException('Token de Google inválido.');

        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final resp = utf8.decode(base64Url.decode(normalized));
        tokenPayload = json.decode(resp);
      } else {
        // --- Flujo Móvil ---
        googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null; // El usuario canceló
      }

      // Extraemos los datos del usuario, ya sea del token (web) o del objeto (móvil).
      final userId = tokenPayload?['sub'] ?? googleUser!.id;
      final userEmail = tokenPayload?['email'] ?? googleUser!.email;
      final userName = tokenPayload?['name'] ?? googleUser?.displayName;
      final userPhoto = tokenPayload?['picture'] ?? googleUser?.photoUrl;

      if (userId == null || userEmail == null) {
        throw AuthException(
            'No se pudo obtener la información del usuario de Google.');
      }

      // Comprobar si el usuario ya existe localmente
      final usersData = await _dataService
          .readJsonFile('users.json', defaultValue: {'users': []});
      final usersList = (usersData['users'] as List<dynamic>);
      // Usamos la variable `userId` que ya contiene el ID correcto tanto para web como para móvil.
      var userJson =
          usersList.firstWhere((u) => u['id'] == userId, orElse: () => null);

      if (userJson == null) {
        // Si no existe, lo creamos
        final newUser = LocalUser(
          // El ID de Google es un identificador único y estable para el usuario.
          id: userId,
          email: userEmail,
          hashedPassword: '', // No se necesita para login con Google
          displayName: userName,
          photoUrl: userPhoto,
        );
        usersList.add(newUser.toJson());
        await _dataService.writeJsonFile('users.json', {'users': usersList});
        _currentUser = newUser;
      } else {
        _currentUser = LocalUser.fromJson(userJson);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', _currentUser!.id);
      notifyListeners();
      return _currentUser;
    } catch (e) {
      // Si el usuario cierra el popup en móvil, GoogleSignIn devuelve null, no lanza excepción.
      // En web, si el usuario cierra, no se llama al callback.
      // Este catch es para errores reales.
      debugPrint('Login con Google cancelado o fallido: $e');
      if (e is AuthException)
        rethrow; // Re-lanzamos nuestras excepciones personalizadas.
      return null;
    }
  }

  /// Cierra la sesión del usuario actual.
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    notifyListeners();
  }
}
