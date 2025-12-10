import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/local_data_service.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum RewardCategory { visual, workouts, bonuses, all }

class RewardItem {
  final String id;
  final String title;
  final String description;
  final int cost;
  final IconData icon;
  final RewardCategory category;

  RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.icon,
    required this.category,
  });
}

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({Key? key}) : super(key: key);

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Future<Map<String, dynamic>>? _userDataFuture;
  RewardCategory _selectedCategory = RewardCategory.all;
  List<String> _purchasedItems = [];

  // Lista de recompensas disponibles en la tienda
  final List<RewardItem> _rewards = [
    // Visual
    RewardItem(
        id: 'theme_neon',
        title: 'Fondo Verde Neón',
        description: 'Un tema vibrante para la app.',
        cost: 500,
        icon: Icons.color_lens_outlined,
        category: RewardCategory.visual),
    RewardItem(
        id: 'theme_red',
        title: 'Fondo Rojo Energía',
        description: 'Un tema intenso para tus entrenos.',
        cost: 500,
        icon: Icons.color_lens_outlined,
        category: RewardCategory.visual),
    RewardItem(
        id: 'particles_effect',
        title: 'Efecto de Partículas',
        description: 'Animaciones en los botones.',
        cost: 700,
        icon: Icons.bubble_chart_outlined,
        category: RewardCategory.visual),
    RewardItem(
        id: 'custom_sounds',
        title: 'Sonidos de Logros',
        description: 'Audio personalizado al completar metas.',
        cost: 300,
        icon: Icons.music_note_outlined,
        category: RewardCategory.visual),
    // Entrenamientos
    RewardItem(
        id: 'workout_explosive',
        title: 'Rutina Explosiva',
        description: 'Entrenamiento de alta intensidad.',
        cost: 1000,
        icon: Icons.fitness_center,
        category: RewardCategory.workouts),
    RewardItem(
        id: 'workout_samurai',
        title: 'Modo Samurai',
        description: 'Fuerza y precisión.',
        cost: 1200,
        icon: Icons.fitness_center,
        category: RewardCategory.workouts),
    RewardItem(
        id: 'workout_spartan',
        title: 'Entrenamiento Spartan',
        description: 'Desafío de resistencia máxima.',
        cost: 1500,
        icon: Icons.fitness_center,
        category: RewardCategory.workouts),
    RewardItem(
        id: 'workout_zen',
        title: 'Modo Zen',
        description: 'Ejercicios suaves y de flexibilidad.',
        cost: 600,
        icon: Icons.self_improvement,
        category: RewardCategory.workouts),
    // Bonos
    RewardItem(
        id: 'bonus_2x_points',
        title: 'Duplicador de Puntos (24h)',
        description: 'Gana el doble de puntos.',
        cost: 1000,
        icon: Icons.star_half_outlined,
        category: RewardCategory.bonuses),
    RewardItem(
        id: 'bonus_recovery',
        title: 'Bonus de Recuperación',
        description: 'Consejos y guías de recuperación.',
        cost: 800,
        icon: Icons.healing_outlined,
        category: RewardCategory.bonuses),
    RewardItem(
        id: 'bonus_challenge',
        title: 'Desbloquear Modo Desafío',
        description: 'Accede a retos más difíciles.',
        cost: 1500,
        icon: Icons.military_tech_outlined,
        category: RewardCategory.bonuses),
  ];

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    final data = await LocalDataService().loadUserData(_currentUser!.uid);
    if (mounted) {
      setState(() {
        _userDataFuture = Future.value(data);
        _purchasedItems = List<String>.from(data['purchased_items'] ?? []);
      });
    }
  }

  Future<void> _purchaseItem(RewardItem item) async {
    if (_currentUser == null) return;

    final currentData = await _userDataFuture!;
    final currentPoints = currentData['totalPoints'] ?? 0;

    if (currentPoints < item.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No tienes suficientes puntos.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: Text('¿Deseas canjear ${item.cost} pts por "${item.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sí, Canjear')),
        ],
      ),
    );

    if (confirmed == true) {
      final newPoints = currentPoints - item.cost;
      final newPurchasedItems = List<String>.from(_purchasedItems)
        ..add(item.id);

      await LocalDataService()
          .updateUserKey(_currentUser!.uid, 'totalPoints', newPoints);
      await LocalDataService().updateUserKey(
          _currentUser!.uid, 'purchased_items', newPurchasedItems);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ ¡Recompensa activada!'),
            backgroundColor: Colors.green),
      );

      // Recargamos los datos para actualizar la UI
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Using light theme background
      appBar: AppBar(
        title: const Text('Tienda de Recompensas'),
        elevation: 1,
        actions: [
          if (_currentUser != null)
            FutureBuilder<Map<String, dynamic>>(
              future: _userDataFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final points = snapshot.data!['totalPoints'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Chip(
                    avatar:
                        Icon(Icons.star_rounded, color: Colors.orange.shade700),
                    label: Text('$points XP',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                    backgroundColor: Colors.orange.withOpacity(0.2),
                  ),
                );
              },
            ),
        ],
      ),
      body: _currentUser == null ? _buildGuestView() : _buildStoreView(),
    );
  }

  Widget _buildStoreView() {
    final filteredRewards = _selectedCategory == RewardCategory.all
        ? _rewards
        : _rewards.where((r) => r.category == _selectedCategory).toList();

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey.shade100,
          child: const Text(
            'Canjea tus puntos por mejoras y extras',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
        // Filtros
        _buildFilterChips(),
        // Grid de recompensas
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _userDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: Text('No se pudieron cargar los datos.'));
              }
              final userPoints = snapshot.data!['totalPoints'] ?? 0;

              if (filteredRewards.isEmpty) {
                return const Center(
                    child: Text('No hay recompensas en esta categoría.'));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredRewards.length,
                itemBuilder: (context, index) {
                  final item = filteredRewards[index];
                  final hasEnoughPoints = userPoints >= item.cost;
                  final isPurchased = _purchasedItems.contains(item.id);
                  return _RewardCard(
                    item: item,
                    hasEnoughPoints: hasEnoughPoints,
                    isPurchased: isPurchased,
                    onPurchase: () => _purchaseItem(item),
                  )
                      .animate()
                      .fadeIn(delay: (100 * (index % 10)).ms)
                      .slideY(begin: 0.2);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FilterChip(
              label: 'Todo',
              isSelected: _selectedCategory == RewardCategory.all,
              onTap: () =>
                  setState(() => _selectedCategory = RewardCategory.all),
            ),
            _FilterChip(
              label: 'Visual',
              isSelected: _selectedCategory == RewardCategory.visual,
              onTap: () =>
                  setState(() => _selectedCategory = RewardCategory.visual),
            ),
            _FilterChip(
              label: 'Entrenamientos',
              isSelected: _selectedCategory == RewardCategory.workouts,
              onTap: () =>
                  setState(() => _selectedCategory = RewardCategory.workouts),
            ),
            _FilterChip(
              label: 'Bonos',
              isSelected: _selectedCategory == RewardCategory.bonuses,
              onTap: () =>
                  setState(() => _selectedCategory = RewardCategory.bonuses),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 80, color: SubefitColors.primaryRed),
            const SizedBox(height: 20),
            const Text('Tienda de Recompensas',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 12),
            const Text(
              'Inicia sesión para ganar puntos y canjear recompensas exclusivas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final RewardItem item;
  final bool hasEnoughPoints;
  final bool isPurchased;
  final VoidCallback onPurchase;

  const _RewardCard({
    required this.item,
    required this.hasEnoughPoints,
    required this.isPurchased,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPurchase = !isPurchased && hasEnoughPoints;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Icon(item.icon, size: 40, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (isPurchased)
              const Chip(
                label: Text('Adquirido',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.green,
                avatar: Icon(Icons.check, color: Colors.white, size: 14),
              )
            else
              ElevatedButton(
                onPressed: canPurchase ? onPurchase : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('${item.cost} XP',
                    style: const TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
