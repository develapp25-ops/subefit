import 'package:flutter/material.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';

/// Widget que muestra las estadísticas de un usuario (seguidores, siguiendo, publicaciones)
class UserStatsWidget extends StatefulWidget {
  final UserProfile userProfile;
  final bool showFollowButton;
  final VoidCallback? onFollowChanged;

  const UserStatsWidget({
    Key? key,
    required this.userProfile,
    this.showFollowButton = true,
    this.onFollowChanged,
  }) : super(key: key);

  @override
  _UserStatsWidgetState createState() => _UserStatsWidgetState();
}

class _UserStatsWidgetState extends State<UserStatsWidget> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<int> _followerCountFuture;
  late Future<int> _followingCountFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    _followerCountFuture =
        _firebaseService.getFollowerCount(widget.userProfile.id);
    _followingCountFuture =
        _firebaseService.getFollowingCount(widget.userProfile.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SubefitColors.darkGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Publicaciones',
                  (widget.userProfile.publicaciones ?? 0).toString()),
              _buildStatColumn('Seguidores',
                  _buildCounterDisplay(_followerCountFuture)),
              _buildStatColumn('Siguiendo',
                  _buildCounterDisplay(_followingCountFuture)),
            ],
          ),
          if (widget.showFollowButton) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Seguir'),
              onPressed: () {
                // TODO: Implementar lógica de seguir
                widget.onFollowChanged?.call();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                backgroundColor: SubefitColors.primaryRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, dynamic count) {
    return Column(
      children: [
        Text(
          count is String ? count : count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SubefitColors.primaryRed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildCounterDisplay(Future<int> future) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SubefitColors.primaryRed,
            ),
          );
        }
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }
}
