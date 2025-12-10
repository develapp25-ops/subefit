import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/progreso_screen.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

// Define division thresholds and names
enum UserDivision {
  elite,
  intermediate,
  novice,
}

UserDivision _getDivision(int totalPoints) {
  // These thresholds are examples and should be defined based on your app's progression system.
  // Puedes ajustar estos valores según la dificultad y el ritmo de progresión deseado.
  if (totalPoints >= 5001) {
    return UserDivision.elite;
  } else if (totalPoints >= 1001) {
    return UserDivision.intermediate;
  } else {
    return UserDivision.novice;
  }
}

String _getDivisionName(UserDivision division) {
  return division
      .toString()
      .split('.')
      .last
      .toUpperCase(); // Convierte a "ELITE", "INTERMEDIATE", "NOVICE"
}

class _RankingScreenState extends State<RankingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<UserProfile>> _rankingFuture;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _firebaseService.getUsersRanking(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Atletas'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<UserProfile>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar el ranking.\nAsegúrate de tener el índice de Firestore configurado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay nadie en el ranking.\n¡Completa entrenamientos para ser el primero!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final users = snapshot.data!;

          // Separamos el podio (top 3) del resto de la lista
          final podiumUsers = users.length >= 3 ? users.sublist(0, 3) : users;
          final otherUsers =
              users.length > 3 ? users.sublist(3) : <UserProfile>[];

          return CustomScrollView(
            slivers: [
              if (podiumUsers.isNotEmpty)
                SliverToBoxAdapter(
                  child: _PodiumWidget(
                      users: podiumUsers, currentUserId: _currentUserId),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = otherUsers[index];
                    return _UserRankTile(
                      user: user,
                      rank: index + 4, // Empezamos desde la posición 4
                      isCurrentUser: user.id == _currentUserId,
                    );
                  },
                  childCount: otherUsers.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PodiumWidget extends StatelessWidget {
  final List<UserProfile> users;
  final String? currentUserId;

  const _PodiumWidget({required this.users, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    // Aseguramos el orden: 1ro, 2do, 3ro
    final first = users.isNotEmpty ? users[0] : null;
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: BoxDecoration(
        color: SubefitColors.darkGrey.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (second != null)
            _PodiumPlace(
                user: second,
                place: 2,
                isCurrentUser: second.id == currentUserId),
          if (first != null)
            _PodiumPlace(
                user: first,
                place: 1,
                isCurrentUser: first.id == currentUserId),
          if (third != null)
            _PodiumPlace(
                user: third,
                place: 3,
                isCurrentUser: third.id == currentUserId),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final UserProfile user;
  final int place;
  final bool isCurrentUser;

  const _PodiumPlace(
      {required this.user, required this.place, required this.isCurrentUser});

  String get _medal {
    switch (place) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  double get _height {
    switch (place) {
      case 1:
        return 150;
      case 2:
        return 120;
      case 3:
        return 100;
      default:
        return 100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProgresoScreen(userId: user.id))),
      child: SizedBox(
        height: _height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: place == 1 ? 35 : 28,
                  backgroundImage:
                      user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                          ? NetworkImage(user.fotoUrl!)
                          : null,
                  backgroundColor: SubefitColors.darkGrey,
                  child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
                ),
                Positioned(
                  bottom: -10,
                  left: 0,
                  right: 0,
                  child: Text(_medal,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              // Usamos Flexible para que el texto se ajuste si es muy largo
              child: Text(
                user.nombre, // Mostramos el nombre completo
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCurrentUser
                      ? SubefitColors.primaryRed
                      : SubefitColors.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2, // Permitimos hasta 2 líneas para el nombre
              ),
            ),
            Text(
              '${user.totalPoints} Pts',
              style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRankTile extends StatelessWidget {
  final UserProfile user;
  final int rank;
  final bool isCurrentUser;

  const _UserRankTile({
    Key? key,
    required this.user,
    required this.rank,
    this.isCurrentUser = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isCurrentUser
          ? SubefitColors.primaryRed.withOpacity(0.2)
          : Colors.transparent,
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCurrentUser
                    ? SubefitColors.primaryRed
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        title: Text(
          user.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCurrentUser
                ? SubefitColors.primaryRed
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Nivel ${user.level} - ${_getDivision(user.totalPoints).toString().split('.').last}', // Muestra la división en el subtítulo
          style: TextStyle(
              color: isCurrentUser
                  ? SubefitColors.primaryRed.withOpacity(0.8)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${user.totalPoints} Puntos',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage:
                      user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                          ? NetworkImage(user.fotoUrl!)
                          : null,
                  backgroundColor: SubefitColors.darkGrey,
                  child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                      ? Icon(Icons.person,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7))
                      : null,
                ),
              ],
            )
          ],
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProgresoScreen(userId: user.id)));
        },
      ),
    );
  }
}
