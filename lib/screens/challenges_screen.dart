import 'package:flutter/material.dart';
import 'package:subefit/models/challenge_model.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/widgets/subefit_colors.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Challenge>> _challengesFuture;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  void _loadChallenges() {
    setState(() {
      _challengesFuture = _firebaseService.getAvailableChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retos y Desafíos'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadChallenges(),
        child: FutureBuilder<List<Challenge>>(
          future: _challengesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error al cargar los retos: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No hay retos disponibles en este momento.\n¡Vuelve más tarde!',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final challenges = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return _ChallengeCard(challenge: challenge);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  IconData _getIconForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return Icons.today_outlined;
      case ChallengeType.weekly:
        return Icons.calendar_view_week_outlined;
      case ChallengeType.special:
        return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Implementar la lógica de progreso del usuario
    final userProgress = 0; // Valor de ejemplo
    final progressPercent =
        (userProgress / challenge.goalValue).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_getIconForType(challenge.type),
                  color: SubefitColors.primaryRed, size: 32),
              title: Text(challenge.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(challenge.description),
            ),
            const SizedBox(height: 16),
            Text('Progreso: $userProgress / ${challenge.goalValue}',
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: Colors.grey.shade300,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(SubefitColors.primaryRed),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Recompensa: ${challenge.rewardPoints} Puntos',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }
}
