import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/local_data_service.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:subefit/screens/full_plans_screen.dart'; // CORREGIDO: Importación añadida

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final LocalDataService _localDataService = LocalDataService();
  Future<Map<String, dynamic>>? _dataFuture;

  // Lista de frases motivacionales
  final List<String> _motivationalQuotes = [
    "La única mala sesión de entrenamiento es la que no se hizo.",
    "Tu cuerpo puede soportar casi cualquier cosa. Es tu mente la que tienes que convencer.",
    "El dolor que sientes hoy será la fuerza que sentirás mañana.",
    "No se trata de ser el mejor. Se trata de ser mejor de lo que eras ayer.",
    "El éxito no es un accidente. Es trabajo duro, perseverancia y aprendizaje.",
    "Cree en ti mismo y en todo lo que eres. Eres más valiente de lo que crees, más talentoso de lo que sabes y capaz de más de lo que imaginas.",
    "La disciplina es el puente entre las metas y los logros."
  ];

  String get _dailyQuote {
    // Obtiene una frase diferente cada día del año
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _motivationalQuotes[dayOfYear % _motivationalQuotes.length];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _dataFuture = _fetchCombinedData(user.uid);
      });
    }
  }

  Future<Map<String, dynamic>> _fetchCombinedData(String userId) async {
    final profile = await _firebaseService.getUserProfile(userId);
    final localData = await _localDataService.loadUserData(userId);
    return {
      'profile': profile,
      'localData': localData,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildGuestView();
    }

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
                child: Text('No se pudieron cargar los datos.'));
          }

          final UserProfile? profile = snapshot.data?['profile'];
          final Map<String, dynamic> localData =
              snapshot.data?['localData'] ?? {};
          final int streak = localData['streak'] ?? 0;
          final int historyCount =
              (localData['history'] as List<dynamic>?)?.length ?? 0;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(profile),
                const SizedBox(height: 24),
                _buildMotivationalQuote(),
                const SizedBox(height: 24),
                _buildStatsGrid(profile, streak, historyCount),
                const SizedBox(height: 24),
                _buildActionCards(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserProfile? profile) {
    final String displayName = profile?.nombre ?? 'Atleta';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.yMMMMd('es').format(DateTime.now()),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Hola, $displayName',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMotivationalQuote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SubefitColors.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_quote,
              color: SubefitColors.primaryRed, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _dailyQuote,
              style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserProfile? profile, int streak, int historyCount) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
            icon: Icons.local_fire_department,
            title: 'Racha',
            value: '$streak días',
            color: SubefitColors.primaryRed),
        _StatCard(
            icon: Icons.star,
            title: 'Puntos',
            value: (profile?.totalPoints ?? 0).toString(),
            color: SubefitColors.primaryRed),
        _StatCard(
            icon: Icons.fitness_center,
            title: 'Entrenos',
            value: historyCount.toString(),
            color: SubefitColors.primaryRed),
        _StatCard(
            icon: Icons.trending_up,
            title: 'Nivel',
            value: (profile?.level ?? 1).toString(),
            color: SubefitColors.primaryRed),
      ],
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        _ActionCard(
          // CORREGIDO: Navegación directa a la pantalla de planes.
          title: 'Planes de Entrenamiento',
          subtitle: 'Explora rutinas completas',
          icon: Icons.assignment,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) =>
                    FullPlansScreen()), // CORREGIDO: Se quita 'const'
          ),
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'Generar Rutina con IA',
          subtitle: 'Crea un entreno a tu medida',
          icon: Icons.smart_toy_outlined,
          onTap: () => Navigator.of(context).pushNamed('/rutinas-ia'),
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'Entrenamiento por GPS',
          subtitle: 'Registra tus carreras o caminatas',
          icon: Icons.location_on_outlined,
          onTap: () => Navigator.of(context).pushNamed('/gps-session'),
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'Cronómetro',
          subtitle: 'Mide tus tiempos de entrenamiento',
          icon: Icons.timer_outlined,
          onTap: () => Navigator.of(context).pushNamed('/cronometro'),
        ),
      ],
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text('Bienvenido a Subefit',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                'Inicia sesión o regístrate para guardar tu progreso y acceder a todas las funciones.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: const Text('Iniciar Sesión o Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.title,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
