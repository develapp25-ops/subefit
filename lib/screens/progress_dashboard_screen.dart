import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/services/progress_analytics_service.dart';
import 'package:subefit/services/ranking_service.dart';
import 'package:subefit/services/user_profile_service.dart';
import 'package:subefit/services/ai_recommendation_service.dart';
import 'package:subefit/widgets/subefit_colors.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  late final ProgressAnalyticsService _analyticsService = ProgressAnalyticsService();
  late final RankingService _rankingService = RankingService();
  late final UserProfileService _profileService = UserProfileService();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Progreso'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<UserStats?>(
      future: _analyticsService.getUserStats(_userId),
      builder: (context, statsSnapshot) {
        if (statsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = statsSnapshot.data;
        if (stats == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Comienza tu viaje de fitness',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCards(stats),
              const SizedBox(height: 24),
              _buildRecommendationCard(stats),
              const SizedBox(height: 24),
              _buildActivityChart(stats),
              const SizedBox(height: 24),
              _buildMilestoneSuggestion(stats),
              const SizedBox(height: 24),
              _buildFavoriteExercises(stats),
              const SizedBox(height: 24),
              _buildRankingCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(UserStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _StatCard(
          title: 'Sesiones',
          value: stats.totalSessions.toString(),
          icon: Icons.fitness_center,
          color: SubefitColors.primaryRed,
        ),
        _StatCard(
          title: 'Minutos',
          value: stats.totalMinutes.toString(),
          icon: Icons.timer,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Puntos',
          value: stats.totalPoints.toString(),
          icon: Icons.star,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Racha 🔥',
          value: stats.currentStreak.toString(),
          icon: Icons.local_fire_department,
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(UserStats stats) {
    return FutureBuilder<UserProfile?>(
      future: _profileService.getUserProfile(_userId),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        if (profile == null) return const SizedBox.shrink();

        final recommendation = AIRecommendationService.recommendNextSession(
          stats,
          profile,
          [stats.favoriteExerciseType],
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SubefitColors.primaryRed.withOpacity(0.8), SubefitColors.primaryRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💡 Recomendación',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                recommendation,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: SubefitColors.primaryRed,
                ),
                child: const Text('Comenzar Sesión'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityChart(UserStats stats) {
    return FutureBuilder<List<DailyActivity>>(
      future: _analyticsService.getActivityHistory(_userId, 7),
      builder: (context, activitySnapshot) {
        if (activitySnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final activities = activitySnapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Última Semana',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: activities.map((activity) {
                  return Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40 +
                            (activity.sessionsCompleted * 10)
                                .toDouble()
                                .clamp(0, 80),
                        decoration: BoxDecoration(
                          color: activity.sessionsCompleted > 0
                              ? SubefitColors.primaryRed
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.date.split('-').last,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMilestoneSuggestion(UserStats stats) {
    final milestone = AIRecommendationService.predictNextMilestone(stats);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu próxima meta',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  milestone,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteExercises(UserStats stats) {
    return FutureBuilder<List<FavoriteExercise>>(
      future: _analyticsService.getFavoriteExercises(_userId, 5),
      builder: (context, favSnapshot) {
        if (favSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final favorites = favSnapshot.data ?? [];
        if (favorites.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ejercicios Favoritos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...favorites.map((ex) => ListTile(
                  title: Text(ex.name),
                  trailing: Text(
                    '${ex.timesCompleted}x',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: SubefitColors.primaryRed,
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildRankingCard() {
    return FutureBuilder<UserRanking?>(
      future: _rankingService.getUserRank(_userId),
      builder: (context, rankSnapshot) {
        if (rankSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final rank = rankSnapshot.data;
        if (rank == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            border: Border.all(color: Colors.purple.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '#${rank.rank}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Posición Global'),
                    Text(
                      '${rank.totalPoints} puntos',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (rank.medals.isNotEmpty)
                Row(
                  children: rank.medals
                      .take(3)
                      .map((medal) => Text(RankingService.getMedalEmoji(medal)))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
