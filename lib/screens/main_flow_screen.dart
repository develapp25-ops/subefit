import 'package:flutter/material.dart';
import 'package:subefit/screens/progreso_screen.dart';
import 'package:subefit/screens/home_screen.dart'; // Importamos la nueva pantalla de inicio
import 'package:subefit/screens/entrenamientos_screen.dart';
import 'package:subefit/screens/social_hub_screen.dart'; // Importamos la pantalla social real
import 'package:subefit/screens/ia_chat_main_screen.dart'; // Pantalla de chat real
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cronometro_screen.dart'; // Importamos la pantalla del cronómetro

class MainFlowScreen extends StatefulWidget {
  final int initialIndex;
  const MainFlowScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainFlowScreen> createState() => _MainFlowScreenState();
}

class _ScreenData {
  final Widget screen;
  final String title;
  final String background;
  final IconData icon;
  final IconData activeIcon;

  const _ScreenData({
    required this.screen,
    required this.title,
    required this.background,
    required this.icon,
    required this.activeIcon,
  });
}

class _MainFlowScreenState extends State<MainFlowScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Única fuente de verdad para las pestañas
  static final List<_ScreenData> _screens = [
    _ScreenData(
      screen: const HomeScreen(), // La nueva pantalla de inicio
      title: 'Inicio',
      background: 'assets/images/fondochatyotros.jpeg',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    _ScreenData(
      screen: const SocialHubScreen(), // Pestaña Comunidad
      title: 'Comunidad',
      background: 'assets/images/fondochatyotros.jpeg',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
    ),
    _ScreenData(
      screen:
          const IaChatMainScreen(), // Usamos la nueva pantalla de chat conversacional
      title: 'Chat IA',
      background: 'assets/images/fondochatyotros.jpeg',
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy,
    ),
    _ScreenData(
      screen: const ProgresoScreen(), // La pantalla de perfil del usuario
      title: 'Perfil',
      background: 'assets/images/fondochatyotros.jpeg',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    return Scaffold(
      // El fondo ahora se adapta al tema, siendo negro para el nuevo HomeScreen
      backgroundColor: _selectedIndex == 0
          ? Colors.black
          : Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens.map((s) => s.screen).toList(),
      ),
      floatingActionButton:
          null, // El cronómetro ahora es una tarjeta en el hub de inicio.
      bottomNavigationBar: BottomNavigationBar(
        items: _screens
            .map((s) => BottomNavigationBarItem(
                  icon: Icon(s.icon),
                  activeIcon: Icon(s.activeIcon),
                  label: s.title, // El título se usa como label en la barra
                ))
            .toList(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        showUnselectedLabels: false,
      ),
    );
  }
}
