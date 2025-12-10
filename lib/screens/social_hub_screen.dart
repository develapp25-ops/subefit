import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/create_post_screen.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/screens/post_model.dart';
import 'package:subefit/screens/saved_posts_screen.dart';
import 'package:subefit/widgets/post_card.dart';
import 'package:subefit/screens/post_detail_screen.dart';
import 'package:subefit/screens/search_users_screen.dart';
import 'package:subefit/screens/ranking_screen.dart';
import 'package:subefit/widgets/subefit_colors.dart';

/// --- NUEVO: Pantalla Social rediseñada con Historias, Feeds y Sugerencias ---
class SocialHubScreen extends StatefulWidget {
  final void Function(String)? onNavigate;
  const SocialHubScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Futuros para los datos
  late Future<List<Post>> _followingFeedFuture;
  late Future<List<Post>> _discoverFeedFuture;
  late Future<List<UserProfile>> _suggestionsFuture;
  late Future<List<UserProfile>>
      _followingUsersFuture; // NUEVO: Futuro para los usuarios que sigues (para las historias)

  // Controlador para las pestañas del feed
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeed();
    _loadSuggestions();
    _loadFollowingUsers(); // NUEVO: Cargar usuarios para las historias
  }

  void _loadFeed() {
    // No recargamos las sugerencias cada vez que se refresca el feed
    setState(() {
      _followingFeedFuture =
          _firebaseService.getFeedPosts(currentUserId: _currentUserId);
      _discoverFeedFuture = _firebaseService.getDiscoverPosts(
          limit: 20); // Nuevo feed de descubrimiento
    });
  }

  void _refreshAll() {
    // Refresca tanto el feed como las sugerencias.
    _loadFeed();
    _loadSuggestions();
    _loadFollowingUsers();
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
        elevation: 1,
        title: const Text('Comunidad',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outlined),
            tooltip: 'Publicaciones Guardadas',
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavedPostsScreen()));
            },
          ),
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
            _buildStoriesSection(), // Ahora es un Sliver
            SliverToBoxAdapter(child: _buildSuggestionsSection()),
            SliverAppBar(
              pinned: true,
              toolbarHeight: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottom: TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'Siguiendo'), Tab(text: 'Descubrir')],
              ),
            ),
            _buildFeeds(),
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

  // NUEVO: Cargar los perfiles de los usuarios que seguimos para las historias.
  void _loadFollowingUsers() {
    if (_currentUserId != null) {
      setState(() {
        _followingUsersFuture =
            _firebaseService.getFollowingUsers(_currentUserId!);
      });
    }
  }

  // --- MODIFICADO: Sección de Historias ahora es dinámica ---
  Widget _buildStoriesSection() {
    return FutureBuilder<List<UserProfile>>(
      future: _followingUsersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
              child: SizedBox(height: 110)); // Espacio mientras carga
        }
        // Si no hay datos o la lista está vacía, no mostramos nada.
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final followingUsers = snapshot.data!;

        return SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: followingUsers.length,
                  itemBuilder: (context, index) {
                    final user = followingUsers[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: SubefitColors.primaryRed,
                            child: CircleAvatar(
                              radius: 32,
                              backgroundImage: user.fotoUrl != null &&
                                      user.fotoUrl!.isNotEmpty
                                  ? NetworkImage(user.fotoUrl!)
                                  : null,
                              child: (user.fotoUrl == null ||
                                      user.fotoUrl!.isEmpty)
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(user.nombre,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Divider(color: Colors.grey[300]),
              ),
            ],
          ),
        );
      },
    );
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
            // --- CAMBIO: De ListView vertical a un carrusel horizontal ---
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final user = suggestions[index];
                  return _SuggestionCard(
                      user: user,
                      onFollow: () => _followUser(user, suggestions, index));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- NUEVO: Contenedor para los dos feeds con pestañas ---
  Widget _buildFeeds() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedList(_followingFeedFuture,
              'Tu feed está vacío.\n¡Sigue a otros atletas para ver su contenido aquí!'),
          _buildFeedList(_discoverFeedFuture,
              'No hay posts para descubrir en este momento.'),
        ],
      ),
    );
  }

  Widget _buildFeedList(Future<List<Post>> future, String emptyMessage) {
    return FutureBuilder<List<Post>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error al cargar el feed: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          );
        }

        final posts = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.zero, // El CustomScrollView ya maneja el padding
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(
              post: post,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: post))),
            );
          },
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
  final VoidCallback onFollow;

  const _SuggestionCard({required this.user, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    // --- CAMBIO: Tarjeta de sugerencia rediseñada para carrusel horizontal ---
    return SizedBox(
      width: 160,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                        ? NetworkImage(user.fotoUrl!)
                        : null,
                child: (user.fotoUrl == null || user.fotoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.nombre,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user.biografia ?? 'Nuevo en Subefit',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onFollow,
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('Seguir'),
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
