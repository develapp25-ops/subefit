import 'dart:io';
import 'package:flutter/material.dart';
import 'package:subefit/screens/edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/create_post_screen.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/screens/post_detail_screen.dart';
import 'post_model.dart'; // Asegúrate que este import esté presente
import '../widgets/subefit_colors.dart';
import '../widgets/post_card.dart'; // Importamos el PostCard
import 'local_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgresoScreen extends StatefulWidget {
  /// Si se proporciona un [userId], la pantalla mostrará el perfil de ese usuario.
  /// Si es nulo, mostrará el perfil del usuario actualmente logueado.
  final String? userId;
  final void Function(String)? onNavigate;
  const ProgresoScreen({Key? key, this.onNavigate, this.userId})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ProgresoScreenState createState() => _ProgresoScreenState();
}

/// Estado para el botón de seguir.
enum FollowStatus { loading, notFollowing, following, requested }

class _ProgresoScreenState extends State<ProgresoScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();
  Future<UserProfile?>? _userProfileFuture;
  Future<FollowStatus>? _followStatusFuture;
  Future<Map<String, dynamic>>? _localUserDataFuture;
  Future<List<Post>>? _userPostsFuture;

  @override
  void initState() {
    super.initState();
    // La carga de datos se inicia aquí para asegurar que se haga una sola vez
    // al construir el widget, previniendo problemas con el TabController
    // al navegar entre perfiles.
    _loadProfileData();
  }

  /// Determina el estado de seguimiento (si sigue, no sigue, o ha enviado solicitud).
  Future<FollowStatus> _getFollowStatus(
      String currentUserId, String targetUserId) async {
    // Primero, comprobamos si ya lo está siguiendo. Esta es la comprobación más rápida.
    final isFollowing =
        await _firebaseService.isFollowing(currentUserId, targetUserId);
    if (isFollowing) {
      return FollowStatus.following;
    }

    // Si no lo sigue, comprobamos si ha enviado una solicitud.
    final hasRequested = await _firebaseService.hasSentFollowRequest(
        currentUserId, targetUserId);
    if (hasRequested) {
      return FollowStatus.requested;
    }

    // Si no ocurre ninguna de las anteriores, no lo sigue.
    return FollowStatus.notFollowing;
  }

  /// Carga los datos del perfil dependiendo de si es el usuario actual o uno externo.
  void _loadProfileData() {
    // Obtenemos el usuario actual directamente de FirebaseAuth aquí para asegurar que esté actualizado.
    final targetUserId =
        widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (targetUserId == null) return;

    // Si estamos viendo el perfil de otro usuario, usamos Firebase.
    // SIMPLIFICACIÓN: Siempre cargamos los datos desde Firebase para asegurar consistencia.
    // Esto evita problemas con datos locales desactualizados.
    setState(() {
      _userProfileFuture = _firebaseService.getUserProfile(targetUserId);
      if (widget.userId != null && FirebaseAuth.instance.currentUser != null) {
        _followStatusFuture = _getFollowStatus(
            FirebaseAuth.instance.currentUser!.uid, targetUserId);
      }
      // Pasamos el ID del usuario actual para que la consulta sepa si debe filtrar por posts públicos o no.
      _userPostsFuture = _firebaseService.getUserPosts(targetUserId,
          currentUserId: FirebaseAuth.instance.currentUser?.uid);
      // Si es nuestro perfil, también cargamos los datos locales para el historial y logros.
      if (widget.userId == null) {
        _localUserDataFuture = LocalDataService().loadUserData(targetUserId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario actual en cada build para reaccionar a los cambios de login/logout.
    final currentUser = FirebaseAuth.instance.currentUser;

    // Si no hay usuario logueado (ni siquiera anónimo), mostramos el prompt de login.
    if (currentUser == null) {
      return _buildLoginPrompt(context);
    }

    // Usamos DefaultTabController para manejar el estado de las pestañas
    return DefaultTabController(
      length: 3, // Publicaciones, Historial, Logros
      child: RefreshIndicator(
        onRefresh: () async => _loadProfileData(),
        child: Scaffold(
          floatingActionButton: (widget.userId == null ||
                  widget.userId == FirebaseAuth.instance.currentUser?.uid)
              ? FloatingActionButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (context) => const CreatePostScreen()),
                    );
                    if (result == true) {
                      _loadProfileData(); // Recargamos para ver el nuevo post
                    }
                  },
                  child: const Icon(Icons.add),
                  tooltip: 'Crear publicación',
                )
              : null,
          body: Column(
            children: [
              Expanded(
                // NestedScrollView es clave para tener un header que se desplaza con el contenido.
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverOverlapAbsorber(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                  context),
                          sliver: SliverAppBar(
                            // El AppBar se expande para mostrar el header del perfil.
                            expandedHeight:
                                420.0, // Aumentado para dar más espacio
                            floating: false,
                            pinned:
                                true, // El TabBar se quedará fijo en la parte superior.
                            backgroundColor: Theme.of(context)
                                .scaffoldBackgroundColor, // Usar el color de fondo del tema
                            flexibleSpace: FlexibleSpaceBar(
                                background: _buildProfileHeader()),
                            leading: widget.userId != null
                                ? const BackButton()
                                : null,
                            actions: [],
                            bottom: TabBar(
                              indicatorColor: SubefitColors.primaryRed,
                              labelColor: SubefitColors.primaryRed,
                              tabs: [
                                Tab(
                                    icon: Icon(Icons.grid_on_outlined),
                                    text: 'Posts'),
                                Tab(
                                    icon: Icon(Icons.history_edu_outlined),
                                    text: 'Historial'),
                                Tab(
                                    icon: Icon(Icons.emoji_events_outlined),
                                    text: 'Logros'), // Calendario al final
                              ],
                            ),
                          )),
                    ];
                  },
                  // El cuerpo del NestedScrollView es el contenido de las pestañas.
                  body: TabBarView(
                    children: [
                      _buildPostsTab(), // Publicaciones
                      _buildHistoryTab(), // Historial
                      _buildAchievementsTab(), // Logros
                    ],
                  ),
                ),
              ),
              // Texto "Created by DevelApp" movido aquí
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Created by DevelApp',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// FutureBuilder para el header. Carga los datos una vez.
  Widget _buildProfileHeader() {
    return FutureBuilder<UserProfile?>(
      future: _userProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
              child: Text('No se pudo cargar el perfil.',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)));
        }

        final profileUser = snapshot.data!;

        // CORREGIDO: Se elimina el SingleChildScrollView redundante.
        // El NestedScrollView ya gestiona el scroll del header.
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40), // Espacio para la AppBar
            _buildProfileInfo(context, profileUser),
          ],
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Inicia sesión para ver tu perfil y progreso.',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary),
            // Navega a la pantalla de login. Cuando el login sea exitoso,
            // esta pantalla se recargará automáticamente.
            onPressed: () {
              // Simplemente navegamos a la pantalla de login.
              // AuthGate se encargará de redirigir al usuario una vez que
              // el inicio de sesión sea exitoso.
              Navigator.of(context).pushNamed('/login');
            },
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, UserProfile profileUser) {
    final bool isCurrentUser = widget.userId == null ||
        widget.userId == FirebaseAuth.instance.currentUser?.uid;

    // --- MODIFICADO: Implementada la lógica para subir imagen ---
    Future<void> _pickAndUploadImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Mostrar un indicador de carga
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Subiendo imagen...')));

      try {
        // 1. Convertir File a bytes
        final imageBytes = await file.readAsBytes();

        // 2. Subir la imagen a Firebase Storage y obtener la URL
        final imageUrl =
            await _firebaseService.uploadProfileImage(userId, imageBytes: imageBytes);

        // 3. Actualizar el perfil del usuario en Firestore con la nueva URL
        await _firebaseService.updateUserProfile(userId, {'fotoUrl': imageUrl});

        // 3. Recargar los datos del perfil para mostrar la nueva imagen
        _loadProfileData();

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Avatar actualizado!')));
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el avatar.')));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: isCurrentUser ? _pickAndUploadImage : null,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                // --- NUEVO: Lógica para mostrar avatar SVG o imagen normal ---
                backgroundImage: profileUser.fotoUrl != null &&
                        profileUser.fotoUrl!.isNotEmpty
                    ? NetworkImage(profileUser.fotoUrl!)
                    : null,
                child: (profileUser.fotoUrl == null ||
                        profileUser.fotoUrl!.isEmpty)
                    ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                    : null,
              ),
              if (isCurrentUser)
                const CircleAvatar(
                    radius: 15,
                    backgroundColor: SubefitColors.primaryRed,
                    child: Icon(Icons.edit, size: 16, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              profileUser.nombre,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            // Mostramos el nivel y los puntos junto al nombre
            Text(
              '(Nivel ${profileUser.level} - ${profileUser.totalPoints} pts)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Biografía del usuario
        if (profileUser.biografia != null && profileUser.biografia!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              profileUser.biografia!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ),
        const SizedBox(height: 20),
        // Sección de estadísticas o botón de seguir
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: isCurrentUser
              ? OutlinedButton.icon(
                  onPressed: () async {
                    // Navegamos al nuevo asistente de datos de usuario para editar.
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EditProfileScreen(userProfile: profileUser)),
                    );
                    // Si el resultado es `true`, significa que se guardaron cambios, así que recargamos.
                    if (result == true) {
                      _loadProfileData();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar Perfil'),
                )
              : _buildFollowButton(profileUser.id),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildStatsRow(profileUser),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFollowButton(String targetUserId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const SizedBox.shrink(); // No mostrar si no está logueado
    }

    return FutureBuilder<FollowStatus>(
      future: _followStatusFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ElevatedButton(
              onPressed: null,
              child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final status = snapshot.data!;

        // Definimos el texto, icono y color según el estado
        String label;
        IconData icon;
        Color backgroundColor;
        bool isFollowing = false;

        switch (status) {
          case FollowStatus.following:
            label = 'Dejar de seguir';
            icon = Icons.person_remove_alt_1_outlined;
            backgroundColor = SubefitColors.darkGrey;
            isFollowing = true;
            break;
          case FollowStatus.requested:
            label = 'Solicitado';
            icon = Icons.hourglass_top_outlined;
            backgroundColor = SubefitColors.darkGrey;
            isFollowing = false; // Técnicamente no lo sigue aún
            break;
          case FollowStatus.notFollowing:
          default:
            label = 'Seguir';
            icon = Icons.person_add_alt_1_outlined;
            backgroundColor = Theme.of(context).colorScheme.primary;
            isFollowing = false;
            break;
        }

        return ElevatedButton.icon(
          onPressed: () async {
            await _firebaseService.toggleFollow(
                currentUserId, targetUserId, isFollowing);
            setState(() {
              // Recargamos el estado del botón y el perfil para actualizar contadores
              _followStatusFuture =
                  _getFollowStatus(currentUserId, targetUserId);
              _userProfileFuture = _firebaseService.getUserProfile(
                  targetUserId); // Recarga el perfil para actualizar contadores
            });
          },
          icon: Icon(icon, size: 16),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(UserProfile userProfile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
              label: 'Publicaciones',
              value: userProfile.publicaciones.toString()),
          _StatItem(
              label: 'Seguidores',
              value: userProfile.seguidores.toString(),
              onNavigate: widget.onNavigate),
          _StatItem(
              label: 'Seguidos',
              value: userProfile.seguidos.toString(),
              onNavigate: widget.onNavigate),
        ],
      ),
    );
  }

  /// Construye la pestaña de Publicaciones del usuario.
  Widget _buildPostsTab() {
    final isCurrentUser = widget.userId == null ||
        widget.userId == FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<List<Post>>(
      future: _userPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mantenemos el CustomScrollView para que el OverlapInjector funcione correctamente
          return CustomScrollView(slivers: [
            SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          ]);
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('No se pudieron cargar las publicaciones.',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text('Aún no hay publicaciones.',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)));
        }

        final posts = snapshot.data!;
        // Usamos una lista de PostCard para una vista más detallada y consistente.
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            // Solo mostramos el prompt para crear post si es el perfil del usuario actual
            if (isCurrentUser && posts.isEmpty)
              SliverToBoxAdapter(child: _buildCreatePostPrompt(null)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    // El PostCard ahora puede manejar su propia navegación.
                    return PostCard(
                      post: post,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: post)),
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Construye una tarjeta para incitar al usuario a crear una nueva publicación.
  Widget _buildCreatePostPrompt(UserProfile? userProfile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            );
            if (result == true) {
              _loadProfileData(); // Recargamos todo el perfil para ver el nuevo post
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: userProfile?.fotoUrl != null &&
                          userProfile!.fotoUrl!.isNotEmpty
                      ? NetworkImage(userProfile.fotoUrl!)
                      : null,
                  child: userProfile?.fotoUrl == null ||
                          userProfile!.fotoUrl!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('¿Qué estás pensando?',
                      style: TextStyle(color: Colors.grey)),
                ),
                const Icon(Icons.add_photo_alternate_outlined,
                    color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la pestaña de Historial de Entrenamientos.
  Widget _buildHistoryTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _localUserDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
              child: Text('No se pudo cargar el historial.',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)));
        }

        final history =
            (snapshot.data?['history'] as List<dynamic>?)?.reversed.toList() ??
                [];

        if (history.isEmpty) {
          return Center(
              child: Text('Aún no has completado ningún entrenamiento.',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)));
        }

        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = history[index] as Map<String, dynamic>;
                    final date = DateTime.parse(item['date']);
                    final duration = Duration(seconds: item['duration']);
                    final points = item['points'];
                    final exercises =
                        (item['exercises'] as List<dynamic>).join(', ');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: SubefitColors.lightGrey,
                      child: ListTile(
                        // Los colores aquí se heredan del tema, no necesitan cambio
                        leading: Icon(Icons.fitness_center,
                            color: Theme.of(context).colorScheme.primary),
                        title: Text(
                            'Entrenamiento - ${DateFormat.yMMMd('es').format(date)}'),
                        subtitle: Text(
                          'Duración: ${duration.inMinutes} min\nEjercicios: $exercises',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$points',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: SubefitColors.primaryRed)),
                            const Text('Puntos',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: history.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Construye la pestaña de Logros.
  Widget _buildAchievementsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _localUserDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
              child: Text('No se pudo cargar los logros.',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)));
        }

        final userData = snapshot.data!;
        final achievements = _getAchievements(userData);

        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final achievement = achievements[index];
                    return _AchievementCard(achievement: achievement);
                  },
                  childCount: achievements.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Define y comprueba los logros del usuario.
  List<_Achievement> _getAchievements(Map<String, dynamic> userData) {
    final totalPoints = userData['totalPoints'] ?? 0;
    final streak = userData['streak'] ?? 0;
    final history = (userData['history'] as List<dynamic>?) ?? [];
    final historyCount = history.length;

    // Lógica para el logro "Madrugador"
    final bool trainedEarly = history.any((item) {
      final date = DateTime.parse(item['date'] as String);
      return date.hour < 8;
    });

    return [
      _Achievement('Primer Entreno', 'Completa tu primer entrenamiento.',
          historyCount >= 1, Icons.looks_one),
      _Achievement('Novato Constante', 'Completa 5 entrenamientos.',
          historyCount >= 5, Icons.star_border),
      _Achievement('Veterano', 'Completa 20 entrenamientos.',
          historyCount >= 20, Icons.star),
      _Achievement('Acumulador', 'Consigue 1000 puntos.', totalPoints >= 1000,
          Icons.emoji_events_outlined),
      _Achievement('Rey de Puntos', 'Consigue 10000 puntos.',
          totalPoints >= 10000, Icons.emoji_events),
      _Achievement('En Racha', 'Alcanza una racha de 3 días.', streak >= 3,
          Icons.whatshot),
      _Achievement('Imparable', 'Alcanza una racha de 7 días.', streak >= 7,
          Icons.local_fire_department),
      _Achievement('Leyenda', 'Alcanza una racha de 30 días.', streak >= 30,
          Icons.military_tech),
      _Achievement('Madrugador', 'Entrena antes de las 8 AM.', trainedEarly,
          Icons.wb_sunny),
    ];
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String)? onNavigate;

  const _StatItem({required this.label, required this.value, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      ],
    );
  }
}

/// Modelo simple para representar un logro.
class _Achievement {
  final String title;
  final String description;
  final bool isUnlocked;
  final IconData icon;

  _Achievement(this.title, this.description, this.isUnlocked, this.icon);
}

/// Widget para mostrar una tarjeta de logro.
class _AchievementCard extends StatelessWidget {
  final _Achievement achievement;
  const _AchievementCard({Key? key, required this.achievement})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: achievement.isUnlocked ? 1.0 : 0.4,
      child: Card(
        elevation: achievement.isUnlocked ? 2 : 0,
        color: SubefitColors.lightGrey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(achievement.icon,
                  size: 40,
                  color: achievement.isUnlocked
                      ? SubefitColors.primaryRed
                      : Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(achievement.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: achievement.isUnlocked
                          ? Colors.black87
                          : Colors.grey.shade600)),
              const SizedBox(height: 4),
              if (!achievement.isUnlocked)
                Text(achievement.description,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}
