import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subefit/screens/tienda_screen.dart';
import 'package:subefit/screens/rutinas_ia_screen.dart';
import 'package:subefit/screens/cronometro_screen.dart'; // Importamos la pantalla de cronómetro
import 'package:subefit/screens/sesiones_entrenamiento_screen.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:subefit/screens/main_flow_screen.dart';

// Screen imports
import 'screens/gps_session_screen_styled.dart';
import 'screens/basic_workouts_screen.dart'; // Asegúrate que este import esté presente
import 'screens/full_plans_screen.dart';
import 'screens/config_screen.dart';
import 'screens/login_screen.dart'; // Importamos la pantalla de login unificada
import 'screens/otp_screen.dart';
import 'screens/user_data_screen.dart';
import 'screens/retos_screen.dart';
import 'screens/register_screen.dart';
import 'screens/user_data_setup_screen.dart'; // Importamos la nueva pantalla
import 'screens/account_conversion_screen.dart'; // Importamos la pantalla de conversión
import 'screens/progress_dashboard_screen.dart'; // Dashboard de progreso
import 'screens/user_profile_setup_screen.dart'; // Setup de perfil inteligente
import 'screens/predefined_sessions_screen.dart'; // Pantalla de sesiones predefinidas
import 'onboarding_screen.dart';
import 'auth_gate.dart';

// Importaciones de Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/firebase_auth_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializamos los datos de localización para el formato de fechas en español.
  // Esto soluciona la LocaleDataException.
  await initializeDateFormatting('es', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (context) => FirebaseAuthService(),
      child: const SubefitApp(),
    ),
  );
}

class SubefitApp extends StatelessWidget {
  const SubefitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subefit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        // --- TEMA CLARO PERSONALIZADO ---
        primaryColor: SubefitColors.primaryRed,
        scaffoldBackgroundColor: Colors.white, // Fondo blanco
        colorScheme: const ColorScheme.light(
          primary: SubefitColors.primaryRed,
          secondary: SubefitColors.primaryRed,
          background: Colors.white,
          surface: SubefitColors
              .lightGrey, // Un gris claro para superficies como cards
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Colors.black,
          error: SubefitColors.dangerRed,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: SubefitColors.primaryRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // AppBar blanca
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black), // Iconos negros
          titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto'),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SubefitColors.primaryRed,
            foregroundColor: Colors.white, // Texto blanco para contraste
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade200, // Fondo de input gris claro
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: SubefitColors.primaryRed, width: 2)),
          labelStyle: const TextStyle(
              color: Colors.black54), // Texto de etiqueta oscuro
        ),
        // CORREGIDO: Usar el textTheme de light() como base para asegurar el contraste correcto.
        textTheme: ThemeData.light()
            .textTheme
            .apply(
              fontFamily: 'Roboto',
              bodyColor: Colors.black87, // Color de cuerpo principal
              displayColor:
                  Colors.black, // Color para textos grandes como titulares
            )
            .copyWith(
                titleMedium: const TextStyle(color: Colors.black54),
                titleSmall: const TextStyle(color: Colors.black54)),
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>
            const AuthGate(), // AuthGate es ahora el punto de entrada.
        '/login': (context) =>
            const LoginScreen(), // Ruta para el login unificado.
        '/register': (context) => const RegisterScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/user-data-setup': (context) =>
            const UserDataSetupScreen(), // Añadimos la nueva ruta
        '/convert-account': (context) =>
            AccountConversionScreen(), // Ruta para asegurar la cuenta
        '/user-data': (context) => const UserDataScreen(),
        '/dashboard': (context) =>
            const MainFlowScreen(initialIndex: 0), // Va a la pestaña Inicio
        '/rutinas': (context) => const MainFlowScreen(initialIndex: 1),
        '/retos': (context) =>
            const MainFlowScreen(initialIndex: 2), // Navega a la pestaña Retos
        '/progreso': (context) =>
            const MainFlowScreen(initialIndex: 3), // Navega a la pestaña Perfil
        // La ruta '/otp' se elimina porque la navegación a OTPScreen se maneja dinámicamente.
        // La pantalla de configuración ahora se muestra dentro de un Scaffold con el fondo correcto.
        '/config': (context) => const Scaffold(
              body: ConfigScreen(),
            ),
        // La ruta '/ejercicio-styled' se elimina porque siempre debe ser llamada
        // con un ejercicio específico. La navegación se maneja desde 'entrenamientos_screen.dart'.
        // '/ejercicio-styled': (context) => const ExerciseMainScreenStyled(), // Esta línea causa un error
        '/rutinas-ia': (context) => const RutinasIaScreen(),
        '/cronometro': (context) => CronometroScreen(),
        '/sesiones-entrenamiento': (context) =>
            const SesionesEntrenamientoScreen(),
        '/tienda': (context) => const TiendaScreen(),
        '/gps-session': (context) =>
            const GPSSessionScreenStyled(), // Apuntamos a la nueva pantalla de mapa funcional
        '/basic-workouts': (context) => const BasicWorkoutsScreen(),
        '/full-plans': (context) => const FullPlansScreen(),
        '/progress-dashboard': (context) => const ProgressDashboardScreen(),
        '/profile-setup': (context) => const UserProfileSetupScreen(),
        '/predefined-sessions': (context) => const PredefinedSessionsScreen(),
        '/ranking': (context) => const MainFlowScreen(initialIndex: 2), // Retos/Ranking
        // Las rutas que dependían de la comprobación de datos de Firebase ya no son necesarias
        // o su lógica se simplifica.
      },
    );
  }
}
