import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/post_model.dart';
import 'package:subefit/widgets/post_card.dart';
import 'package:subefit/widgets/subefit_colors.dart';

/// Pantalla para ver las publicaciones guardadas del usuario
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({Key? key}) : super(key: key);

  @override
  _SavedPostsScreenState createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  late Future<List<Post>> _savedPostsFuture;

  @override
  void initState() {
    super.initState();
    if (_currentUserId != null) {
      _savedPostsFuture = _firebaseService.getSharedPosts(_currentUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicaciones Guardadas'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Post>>(
        future: _savedPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final savedPosts = snapshot.data ?? [];

          if (savedPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes publicaciones guardadas',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: savedPosts.length,
            itemBuilder: (context, index) {
              return PostCard(
                post: savedPosts[index],
              );
            },
          );
        },
      ),
    );
  }
}
