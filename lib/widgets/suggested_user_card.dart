import 'package:flutter/material.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';

/// Un widget para mostrar un usuario sugerido en una tarjeta.
///
/// Muestra la foto de perfil, nombre, nivel, seguidores y un botón para seguir.
/// También indica si el perfil es privado.
class SuggestedUserCard extends StatelessWidget {
  final UserProfile user;
  final bool isFollowing;
  final VoidCallback onFollowToggle;
  final VoidCallback? onTap;

  const SuggestedUserCard({
    Key? key,
    required this.user,
    required this.isFollowing,
    required this.onFollowToggle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                        ? NetworkImage(user.fotoUrl!)
                        : null,
                backgroundColor: Colors.grey.shade200,
                child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                    ? Icon(Icons.person, size: 30, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!user.publico) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.lock,
                              size: 14, color: Colors.grey.shade600),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nivel: ${user.level} • ${user.seguidores} seguidores',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onFollowToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? SubefitColors.darkGrey
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
