import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, ChangeNotifier, debugPrint;
import 'firebase_service.dart'; // Importamos el servicio de Firebase

/// Servicio para gestionar la autenticación con Firebase.
///
/// Centraliza toda la lógica de registro, inicio de sesión y cierre de sesión
/// utilizando FirebaseAuth y GoogleSignIn.
class FirebaseAuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseService _firebaseService =
      FirebaseService(); // Instancia del servicio de Firestore

  FirebaseAuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Stream para escuchar los cambios en el estado de autenticación.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actualmente autenticado.
  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  /// Inicia sesión o se registra utilizando una cuenta de Google.
  Future<User?> signInWithGoogle() async {
    try {
      // Inicia el flujo de inicio de sesión de Google.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // Si el usuario cancela, googleUser será nulo.
      if (googleUser == null) {
        return null;
      }

      // Obtenemos los detalles de autenticación de la solicitud.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Creamos una credencial de Firebase con los tokens de Google.
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Inicia sesión en Firebase con la credencial.
      final userCredential = await _auth.signInWithCredential(credential);

      // Usamos la información de la credencial para saber si es un usuario nuevo.
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Si es un usuario nuevo, inicializamos su perfil en Firestore.
      if (isNewUser && userCredential.user != null) {
        await _initializeFirestoreProfile(userCredential.user!,
            displayName: userCredential.user!.displayName,
            email: userCredential.user!.email);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthExceptionMessage(e.code);
    } catch (e) {
      throw 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }

  /// Registra un nuevo usuario con correo y contraseña.
  Future<User?> createUserWithEmailAndPassword(
      String username, String email, String password) async {
    try {
      // 1. Comprobar si el nombre de usuario ya existe
      final usernameExists =
          await _firebaseService.checkUsernameExists(username);
      if (usernameExists) {
        throw 'Este nombre de usuario ya está en uso. Por favor, elige otro.';
      }

      // 2. Crear el usuario en Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Si el usuario se crea correctamente, inicializamos su perfil en Firestore con el nombre de usuario.
      if (userCredential.user != null) {
        // ¡IMPORTANTE! Actualizamos el perfil de Firebase Auth con el nombre de usuario.
        // Esto asegura que `currentUser.displayName` no sea nulo después del login.
        await userCredential.user!.updateDisplayName(username);

        await _initializeFirestoreProfile(userCredential.user!,
            displayName: username, email: email);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthExceptionMessage(e.code);
    } catch (e) {
      throw 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }

  /// Inicia sesión con correo y contraseña.
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // CORREGIDO: Se utiliza la función de mensajes amigables para dar feedback correcto al usuario.
      throw _getFriendlyAuthExceptionMessage(e.code);
    }
  }

  /// Obtiene el email de un usuario a partir de su nombre de usuario.
  Future<String?> getEmailFromUsername(String username) async {
    try {
      final userProfile =
          await _firebaseService.getUserProfileByUsername(username);
      if (userProfile == null) {
        // Si no se encuentra el perfil, lanzamos una excepción clara.
        throw 'No se encontró un usuario con ese nombre. Intenta con tu correo electrónico.';
      }
      // Asumimos que el email está guardado en el perfil de Firestore.
      return userProfile?.email;
    } catch (e) {
      // Si hay cualquier error (no encontrado, permisos, etc.), lo relanzamos para que la UI lo maneje.
      // Re-lanzamos la excepción para que la UI la maneje.
      rethrow;
    }
  }

  /// Envía un correo para restablecer la contraseña.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Para no revelar si un usuario existe, podríamos no manejar 'user-not-found'.
      // Pero para una mejor UX, es útil decirle al usuario si el correo no existe.
      if (e.code == 'user-not-found') {
        throw 'No se encontró ningún usuario con ese correo electrónico.';
      }
      // Para otros errores, un mensaje genérico.
      throw 'Ocurrió un error al intentar enviar el correo de restablecimiento.';
    }
  }

  /// Inicia el proceso de verificación de número de teléfono.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Inicia sesión con la credencial de teléfono (OTP).
  Future<User?> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);

      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Si es un usuario nuevo, inicializamos su perfil.
      // Como no tenemos nombre, usamos un placeholder. UserDataSetupScreen pedirá el nombre.
      if (isNewUser && userCredential.user != null) {
        await _initializeFirestoreProfile(userCredential.user!,
            displayName: 'Atleta');
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthExceptionMessage(e.code);
    } catch (e) {
      throw 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }

  /// Método para inicializar el perfil del usuario en Firestore.
  Future<void> _initializeFirestoreProfile(User user,
      {String? displayName, String? email}) async {
    // Usamos updateUserProfile con los datos iniciales.
    // `set` con `merge:true` es idempotente: crea el perfil si no existe
    // y no sobrescribe datos si ya existe (a menos que se especifiquen aquí).
    // Esto es más seguro y simple que `initializeUserProfile`.
    await _firebaseService.updateUserProfile(user.uid, {
      // Solo establecemos estos valores si el perfil se está creando.
      // Si el perfil ya existe, `set(merge:true)` no los tocará si no se especifican.
      // Para asegurarnos de que no sobreescribimos un perfil existente,
      // lo ideal es manejar esto con una Cloud Function o una transacción.
      // Pero para el registro, esta aproximación es generalmente segura.
      'email': email ?? user.email,
      'nombre': displayName ?? user.displayName ?? 'Atleta',
      'nombre_lowercase':
          (displayName ?? user.displayName ?? 'Atleta').toLowerCase(),
      'biografia': '',
      'publico': true,
      'seguidores': 0,
      'seguidos': 0,
      'publicaciones': 0,
      'isProfileComplete': false,
      'level': 1,
      'totalPoints': 0,
    });
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    // Cerramos sesión tanto en Google Sign-In como en Firebase.
    // Es importante desconectar de Google también para que el selector de cuenta aparezca la próxima vez.
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.disconnect();
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Callback que se ejecuta cuando el estado de autenticación cambia.
  void _onAuthStateChanged(User? user) {
    notifyListeners(); // Notifica a los widgets que escuchan.
  }

  /// Convierte los códigos de error de FirebaseAuth a mensajes amigables.
  String _getFriendlyAuthExceptionMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      // Este nuevo caso maneja un error más genérico que Firebase envía a menudo para email/pass incorrectos.
      case 'invalid-credential': // Este error es común para email/pass incorrectos
        return 'Correo o contraseña incorrectos.';
      case 'invalid-verification-code':
        return 'El código de verificación es incorrecto.';
      case 'email-already-in-use':
        return 'Este correo electrónico ya está registrado.';
      default:
        return 'Ocurrió un error de autenticación.';
    }
  }
}
