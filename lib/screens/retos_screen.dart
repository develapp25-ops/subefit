import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/create_post_screen.dart'; // Importamos la nueva pantalla
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/screens/post_model.dart';
import 'package:subefit/widgets/post_card.dart';
import 'package:subefit/screens/search_users_screen.dart'; // Importar la pantalla de búsqueda
import 'package:subefit/screens/ranking_screen.dart'; // Importar la pantalla de ranking
import 'package:subefit/widgets/subefit_colors.dart';

// --- PANTALLA SOCIAL EN CONSTRUCCIÓN ---
// Esta pantalla ahora funciona como el Hub Social
class RetosScreen extends StatefulWidget {
  final void Function(String)? onNavigate;
  const RetosScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<RetosScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<RetosScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Post>> _feedFuture;
  late Future<List<UserProfile>> _suggestionsFuture;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadSuggestions();
  }

  void _loadFeed() {
    // No recargamos las sugerencias cada vez que se refresca el feed
    setState(() {
      _feedFuture =
          _firebaseService.getFeedPosts(currentUserId: _currentUserId);
    });
  }

  void _refreshAll() {
    // Refresca tanto el feed como las sugerencias.
    _loadFeed();
    _loadSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    // Si por alguna razón no hay un usuario, mostramos un loader o un mensaje.
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // backgroundColor: Colors.white, // Eliminado para usar el del tema
      appBar: AppBar(
        // backgroundColor: Colors.white, // Eliminado para usar el del tema
        elevation: 1,
        title: const Text('Retos', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Ver Ranking',
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RankingScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchUsersScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () async {
              // Navegamos a la pantalla de creación y esperamos un resultado.
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (context) => const CreatePostScreen()),
              );
              // Si el resultado es 'true', significa que se creó un post y debemos refrescar.
              if (result == true) {
                _loadFeed();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSuggestionsSection()),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Divider(color: Colors.grey[800]),
              ),
            ),
            _buildFeedList(),
          ],
        ),
      ),
    );
  }

  void _loadSuggestions() {
    if (_currentUserId != null) {
      setState(() {
        _suggestionsFuture =
            _firebaseService.getSuggestedUsers(_currentUserId!, limit: 10);
      });
    }
  }

  Widget _buildSuggestionsSection() {
    return FutureBuilder<List<UserProfile>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox
              .shrink(); // No mostrar nada si no hay sugerencias
        }

        final suggestions = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text('Sugerencias para ti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            // --- CAMBIO: De PageView horizontal a ListView vertical ---
            // Esto muestra las tarjetas de usuario de forma más clara, una debajo de la otra.
            ListView.builder(
              shrinkWrap: true, // Para que funcione dentro de un Column
              physics:
                  const NeverScrollableScrollPhysics(), // Para que el scroll lo maneje el CustomScrollView
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final user = suggestions[index];
                return _SuggestionCard(
                  user: user,
                  onDismiss: () => setState(() => suggestions.removeAt(index)),
                  onFollow: () => _followUser(user, suggestions, index),
                );
              },
            )
          ],
        );
      },
    );
  }

  Widget _buildFeedList() {
    return FutureBuilder<List<Post>>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
              child: Center(
                  child: Text('Error al cargar el feed: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tu feed está vacío.\n¡Sigue a otros atletas para ver su contenido aquí!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),
          );
        }

        final posts = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => PostCard(post: posts[index]),
            childCount: posts.length,
          ),
        );
      },
    );
  }

  // --- NUEVO: Método extraído para seguir a un usuario ---
  // Esto hace el código más limpio y reutilizable.
  void _followUser(
      UserProfile user, List<UserProfile> suggestions, int index) async {
    await _firebaseService.toggleFollow(_currentUserId!, user.id, false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Ahora sigues a ${user.nombre}'),
          duration: const Duration(seconds: 2)),
    );
    // CORREGIDO: Se elimina la tarjeta de la lista y se refresca el feed para una UI más reactiva.
    setState(() {
      suggestions.removeAt(index);
    });
    _loadFeed(); // Recarga solo el feed, no las sugerencias.
  }
}

class _SuggestionCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onDismiss;
  final VoidCallback onFollow;

  const _SuggestionCard(
      {required this.user, required this.onDismiss, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(user.id),
      direction: DismissDirection.endToStart, // Solo deslizar a la izquierda
      onDismissed: (_) => onDismiss(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      // --- CAMBIO: Usamos un Card y un ListTile para un diseño más estándar y limpio ---
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                ? NetworkImage(user.fotoUrl!)
                : null,
            child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
            user.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: user.biografia != null && user.biografia!.isNotEmpty
              ? Text(
                  user.biografia!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: SizedBox(
            height: 32, // Altura fija para el botón
            child: ElevatedButton(
              onPressed: onFollow,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1, size: 16),
                  SizedBox(width: 4),
                  Text('Seguir'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
