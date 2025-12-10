import 'package:flutter/material.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'tts_service.dart';
import 'local_data_service.dart';
import 'package:provider/provider.dart';
import 'firebase_auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EntrenamientosScreen extends StatefulWidget {
  const EntrenamientosScreen({Key? key}) : super(key: key);

  @override
  State<EntrenamientosScreen> createState() => _EntrenamientosScreenState();
}

class _EntrenamientosScreenState extends State<EntrenamientosScreen> {
  Future<Map<String, dynamic>>? _userDataFuture; // Para cargar los puntos

  @override
  void initState() {
    super.initState();
    // La carga de datos se iniciará en didChangeDependencies o build
    // cuando el usuario esté disponible a través del Provider.
  }

  String _getDynamicGreeting(String? name) {
    final hour = DateTime.now().hour;
    // Si no hay nombre, mostramos un saludo genérico.
    if (name == null || name.isEmpty) {
      return '¡Hola, Atleta!';
    }

    final displayName = name.split(' ').first; // Usa solo el primer nombre

    if (hour < 12) {
      return 'Buenos días, $displayName ☀️';
    } else if (hour < 20) {
      return 'Buenas tardes, $displayName 🌤️';
    } else {
      return 'Buenas noches, $displayName 🌙';
    }
  }

  void _loadUserDataForPoints(String userId) {
    // Solo asignamos el Future si no ha sido asignado antes para este usuario.
    if (_userDataFuture == null) {
      setState(() {
        _userDataFuture = LocalDataService().loadUserData(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<FirebaseAuthService>(context);
    final currentUser = authService.currentUser;
    final ttsService = TtsService();

    if (currentUser != null) {
      _loadUserDataForPoints(currentUser.uid);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Image.asset('assets/images/logorojo.png', height: 50),
          ),
          // --- Header con saludo y título ---
          SliverPadding(
              padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
              sliver: SliverToBoxAdapter(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      // Usamos el usuario del provider
                      _getDynamicGreeting(currentUser?.displayName),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined,
                        color: Colors.black54),
                    onPressed: () => ttsService.speak(
                        '${_getDynamicGreeting(currentUser?.displayName)}. ENTRENAMIENTOS.'),
                    tooltip: 'Leer encabezado',
                  ),
                ],
              ))),
          // Título principal
          SliverToBoxAdapter(
            child: const Center(
                child: Text(
              '¿Qué entrenamos hoy?',
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 18,
                  color: Colors.black54,
                  letterSpacing: 1.2),
            )),
          ),
          // --- Contador de Puntos (visible en Inicio) ---
          if (currentUser != null)
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _userDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox
                        .shrink(); // O un mensaje de error discreto
                  }
                  final totalPoints = snapshot.data!['totalPoints'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24),
                        const SizedBox(width: 8),
                        Text('$totalPoints Puntos',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),
          // --- Hub central con tarjetas ---
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: MediaQuery.of(context).size.width /
                    (MediaQuery.of(context).size.height / 1.8),
              ),
              delegate: SliverChildListDelegate(
                [
                  _HubCard(
                    title: 'Entrenamientos',
                    icon: Icons.fitness_center,
                    requiresLogin: true,
                    onTap: () {
                      if (currentUser != null) {
                        Navigator.of(context)
                            .pushNamed('/sesiones-entrenamiento');
                      } else {
                        _showLoginDialog(context,
                            'Debes iniciar sesión para acceder a los entrenamientos.');
                      }
                    },
                  ).animate().fadeIn(delay: 100.ms).slideX(),
                  _HubCard(
                    title: 'Entrenamiento por GPS',
                    icon: Icons.location_on_outlined,
                    requiresLogin: true,
                    onTap: () => _handleNavigation(context, currentUser != null,
                        '/gps-session', 'iniciar una sesión con GPS.'),
                  ).animate().fadeIn(delay: 200.ms).slideX(),
                  _HubCard(
                    title: 'Retos',
                    icon: Icons.groups_outlined,
                    requiresLogin: true,
                    onTap: () => _handleNavigation(context, currentUser != null,
                        '/retos', 'acceder a los retos.'),
                  ).animate().fadeIn(delay: 300.ms).slideX(),
                  _HubCard(
                    title: 'Mi Perfil',
                    icon: Icons.bar_chart,
                    requiresLogin: true,
                    onTap: () => _handleNavigation(context, currentUser != null,
                        '/progreso', 'ver tu perfil.'),
                  ).animate().fadeIn(delay: 400.ms).slideX(),
                  _HubCard(
                    title: 'Entrenamiento IA',
                    icon: Icons.smart_toy_outlined,
                    requiresLogin: true,
                    onTap: () => _handleNavigation(context, currentUser != null,
                        '/rutinas-ia', 'usar la IA.'),
                  ).animate().fadeIn(delay: 400.ms).slideX(),
                  _HubCard(
                    // Nueva tarjeta para la tienda
                    title: 'Tienda',
                    icon: Icons.storefront_outlined,
                    requiresLogin: true,
                    onTap: () => _handleNavigation(context, currentUser != null,
                        '/tienda', 'acceder a la tienda.'),
                  ).animate().fadeIn(delay: 500.ms).slideX(),
                  _HubCard(
                    title: 'Cronómetro',
                    icon: Icons.timer_outlined,
                    requiresLogin: false, // El cronómetro no requiere login
                    onTap: () =>
                        _handleNavigation(context, true, '/cronometro'),
                  ).animate().fadeIn(delay: 500.ms).slideX(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(
      BuildContext context, bool isLoggedIn, String routeName,
      [String? featureName]) {
    if (isLoggedIn) {
      // CORREGIDO: Se ajustaron los índices para que coincidan con el orden de MainFlowScreen.
      // MainFlowScreen: 0:Inicio, 1:Entrenar, 2:Social, 3:Chat IA, 4:Perfil
      final tabRoutes = ['/dashboard', '/retos', '/progreso'];
      if (tabRoutes.contains(routeName)) {
        // Se mapean las rutas a los índices correctos de la barra de navegación.
        final routesMap = {'/dashboard': 0, '/retos': 2, '/progreso': 4};
        // Se navega a la pantalla principal (MainFlowScreen) pasándole el índice de la pestaña a la que ir.
        Navigator.of(context).pushNamed('/', arguments: routesMap[routeName]);
      } else {
        Navigator.of(context).pushNamed(routeName);
      }
    } else {
      _showLoginDialog(context,
          'Debes iniciar sesión para ${featureName ?? 'acceder a esta sección.'}');
    }
  }

  void _showFeatureDisabled(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Esta función estará disponible próximamente.')),
    );
  }

  void _showLoginDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Acceso Requerido'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Iniciar Sesión'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Cierra el diálogo.
                // Navegamos a la pantalla de login. AuthGate se encargará del resto
                // cuando el estado de autenticación cambie.
                Navigator.of(context).pushNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool requiresLogin;

  const _HubCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.requiresLogin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // El estado de login se obtiene del Provider para decidir si la tarjeta está bloqueada.
    final authService =
        Provider.of<FirebaseAuthService>(context, listen: false);
    final bool isLoggedIn = authService.isLoggedIn;
    final bool isLocked = requiresLogin && !isLoggedIn;

    return InkWell(
      onTap:
          isLocked ? null : onTap, // Deshabilitamos el onTap si está bloqueado
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isLocked
                  ? Colors.grey.shade400
                  : Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: isLocked
                  ? Colors.grey.withOpacity(0.2)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocked ? Icons.lock_outline : icon,
              size: 40,
              color: isLocked
                  ? Colors.grey.shade500
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLocked ? Colors.grey.shade500 : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
