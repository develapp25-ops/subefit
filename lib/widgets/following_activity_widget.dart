import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';

/// Widget que muestra la actividad de usuarios que sigues
class FollowingActivityWidget extends StatefulWidget {
  const FollowingActivityWidget({Key? key}) : super(key: key);

  @override
  _FollowingActivityWidgetState createState() => _FollowingActivityWidgetState();
}

class _FollowingActivityWidgetState extends State<FollowingActivityWidget> {
  final FirebaseService _firebaseService = FirebaseService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  late Future<List<UserProfile>> _followingUsersFuture;

  @override
  void initState() {
    super.initState();
    if (_currentUserId != null) {
      _followingUsersFuture = _firebaseService.getFollowingUsers(_currentUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<UserProfile>>(
      future: _followingUsersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No estás siguiendo a nadie',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        final followingUsers = snapshot.data!;

        return ListView.builder(
          itemCount: followingUsers.length,
          itemBuilder: (context, index) {
            final user = followingUsers[index];
            return _buildActivityCard(user);
          },
        );
      },
    );
  }

  Widget _buildActivityCard(UserProfile user) {
    return Card(
      color: SubefitColors.darkGrey.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: const Icon(Icons.person, color: Colors.white70),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (user.biografia != null && user.biografia!.isNotEmpty)
                    Text(
                      user.biografia!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              onPressed: () {
                // TODO: Navegar al perfil del usuario
              },
            ),
          ],
        ),
      ),
    );
  }
}
