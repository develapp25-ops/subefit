import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subefit/screens/main_flow_screen.dart';
import 'package:subefit/screens/firebase_service.dart'; // Importamos el servicio de Firestore
import 'package:subefit/screens/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar Firebase Auth
import 'package:subefit/screens/login_screen.dart';
import 'package:subefit/onboarding_screen.dart'; // Importamos la pantalla de Onboarding

/// Un widget que actúa como "guardián" de la autenticación.
///
/// Escucha el estado de `LocalAuthService` y muestra la pantalla de `Login`
/// o la pantalla principal de la aplicación (`MainFlowScreen`) según corresponda.
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Helper method to build a consistent loading screen.
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logorojo.png', height: 100),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el servicio de autenticación a través de Provider.
    final authService = Provider.of<FirebaseAuthService>(context);

    // Usamos un StreamBuilder para escuchar los cambios de autenticación de Firebase.
    return StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          // Si el stream todavía está conectando, mostramos un loader.
          if (snapshot.connectionState == ConnectionState.waiting)
            return _buildLoadingScreen();

          // Si no hay un usuario autenticado, lo dirigimos a la pantalla de login.
          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginScreen();
          }

          // Si el usuario SÍ ha iniciado sesión, comprobamos si su perfil está completo.
          final user = snapshot.data!;
          return FutureBuilder<bool>(
            future: _isProfileComplete(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting)
                return _buildLoadingScreen();

              final isComplete = profileSnapshot.data ?? false;
              if (isComplete) {
                return const MainFlowScreen();
              } else {
                // Si el perfil no está completo, vamos al Onboarding.
                // Le pasamos una función `onComplete` que se ejecutará cuando el usuario
                // termine el tutorial. Esta función ahora navegará a la pantalla de
                // configuración de datos del usuario.
                return OnboardingScreen(onComplete: () {
                  // Navegamos a la pantalla de configuración de datos.
                  // Usamos pushReplacement para que el usuario no pueda volver al onboarding.
                  Navigator.of(context)
                      .pushReplacementNamed('/user-data-setup');
                });
              }
            },
          );
        });
  }

  /// Comprueba si el perfil del usuario está marcado como completo en sus datos locales.
  Future<bool> _isProfileComplete(String firebaseUserId) async {
    // Usamos el servicio de Firebase para obtener el perfil.
    final profile = await FirebaseService().getUserProfile(firebaseUserId);
    // Si el perfil no existe o no está completo, devolvemos false.
    // Esto es más robusto que depender de datos locales que podrían no existir.
    return profile?.isProfileComplete ?? false;
  }
}
