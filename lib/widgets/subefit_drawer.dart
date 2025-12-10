import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/firebase_auth_service.dart';
import 'subefit_colors.dart';

class SubefitDrawer extends StatelessWidget {
  final String selectedRoute;
  final void Function(String) onSelect;
  const SubefitDrawer({
    Key? key,
    required this.selectedRoute,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Un usuario está "logueado" si no es anónimo.
    final isLoggedIn = user != null && !user.isAnonymous;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName ?? 'Usuario';
    final email = user?.email ?? 'Modo Invitado';
    return Drawer(
      backgroundColor: SubefitColors.darkBg.withValues(alpha: 0.95),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  backgroundColor: Colors.black26,
                  child: photoUrl == null
                      ? const Icon(Icons.person,
                          size: 40, color: Colors.white70)
                      : null,
                ),
                const SizedBox(height: 8),
                Text('¡Hola, $displayName!',
                    style: const TextStyle(
                        color: SubefitColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text(email,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _drawerItem(context, 'Dashboard', Icons.home, '/dashboard',
              selectedRoute, onSelect),
          _drawerItem(context, 'GPS', Icons.location_on, '/gps', selectedRoute,
              onSelect),
          _drawerItem(context, 'Progreso', Icons.bar_chart, '/progreso',
              selectedRoute, onSelect),
          _drawerItem(context, 'Feed', Icons.dynamic_feed, '/retos',
              selectedRoute, onSelect),
          _drawerItem(context, 'Rutinas IA', Icons.smart_toy, '/rutinas',
              selectedRoute, onSelect),
          const Divider(height: 16, color: Colors.white24),
          _drawerItem(context, 'Mi Progreso', Icons.trending_up, '/progress-dashboard',
              selectedRoute, onSelect),
          _drawerItem(context, 'Mi Perfil', Icons.person_outline, '/profile-setup',
              selectedRoute, onSelect),
          _drawerItem(context, 'Sesiones', Icons.fitness_center, '/predefined-sessions',
              selectedRoute, onSelect),
          _drawerItem(context, 'Ranking', Icons.leaderboard, '/ranking',
              selectedRoute, onSelect),
          _drawerItem(context, 'Configuración', Icons.settings, '/config',
              selectedRoute, onSelect),
          const Spacer(),
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SubefitColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await FirebaseAuthService().signOut();
                  // Navegamos a la raíz para que AuthGate maneje el estado (mostrará login).
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String label, IconData icon,
      String route, String selected, void Function(String) onTap) {
    final protectedRoutes = ['/progreso', '/gps', '/config'];
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null && !user.isAnonymous;
    final isEnabled = !protectedRoutes.contains(route) || isLoggedIn;
    final bool active = route == selected;

    return Material(
      color: active
          ? SubefitColors.primaryRed.withValues(alpha: 0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? () => onTap(route) : null,
        splashColor: SubefitColors.primaryRed.withValues(alpha: 0.4),
        highlightColor: SubefitColors.primaryRed.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(icon,
                color: active
                    ? SubefitColors.primaryRed
                    : (isEnabled
                        ? Colors.white70
                        : Colors.grey[800])),
            title: Text(
              label,
              style: TextStyle(
                  color: active
                      ? Colors.white
                      : (isEnabled
                          ? SubefitColors.textWhite
                          : Colors.grey[700]),
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
