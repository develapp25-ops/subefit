import 'package:flutter/material.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({Key? key, this.onComplete}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Lista de páginas del tutorial
  final List<Widget> _pages = [
    _OnboardingPage(
      icon: Icons.waving_hand_rounded,
      title: 'Bienvenido a SubeFit',
      description:
          'La app social donde cada entrenamiento te acerca a la cima. Prepárate para entrenar, competir y conectar.',
      color: SubefitColors.primaryRed,
    ),
    _OnboardingPage(
      icon: Icons.fitness_center,
      title: '1. Entrena y Gana Puntos',
      description:
          'Completa rutinas, planes de entrenamiento o sesiones con GPS. Cada gota de sudor se convierte en puntos de experiencia.',
      color: Colors.cyan,
    ),
    _OnboardingPage(
      icon: Icons.emoji_events_outlined,
      title: '2. Sube de División',
      description:
          'Acumula puntos para ascender desde Novato, pasando por Intermedio, hasta llegar a la élite. ¡Demuestra tu constancia!',
      color: Colors.green,
    ),
    _OnboardingPage(
      icon: Icons.leaderboard_outlined,
      title: '3. Compite en los Rankings',
      description:
          'Compite en rankings globales o contra atletas de tu misma división. ¿Podrás llegar al #1?',
      color: Colors.orange,
    ),
    _OnboardingPage(
      icon: Icons.groups_2_outlined,
      title: '4. Socializa y Motívate',
      description:
          'Comparte tus logros en el feed, sigue a otros atletas y encuentra la inspiración para tu próximo reto. ¡No estás solo!',
      color: Colors.blue,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Botón de Saltar
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child:
                    const Text('Saltar', style: TextStyle(color: Colors.grey)),
              ),
            ),
            // Contenido de las páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _pages,
              ),
            ),
            // Indicador de página y botones de navegación
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicador de puntos
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: const WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: SubefitColors.primaryRed,
                      dotColor: Colors.black12,
                    ),
                  ),
                  // Botón de Siguiente / Empezar
                  ElevatedButton(
                    onPressed: () {
                      if (isLastPage) {
                        widget.onComplete?.call();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Icon(
                        isLastPage ? Icons.check : Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget reutilizable para cada página del onboarding
class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.color = SubefitColors.primaryRed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: color),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
