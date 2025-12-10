import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subefit/screens/comment_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:subefit/screens/firebase_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _isPosting = false;

  Future<void> _postComment() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _commentController.text.trim();

    if (text.isEmpty || user == null) {
      return;
    }

    setState(() => _isPosting = true);

    try {
      await _firebaseService.addComment(
        postId: widget.postId,
        autorId: user.uid,
        autorNombre: user.displayName ?? 'Anónimo',
        texto: text,
      );

      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error al publicar el comentario: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
        backgroundColor: SubefitColors.darkBg,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No hay comentarios aún.',
                          style: TextStyle(color: Colors.white70)));
                }

                final comments = snapshot.data!.docs
                    .map((doc) => Comment.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(comment.autorNombre,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(comment.texto),
                    );
                  },
                );
              },
            ),
          ),
          // Input para nuevo comentario
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                        hintText: 'Añadir un comentario...'),
                    enabled: user != null && !user.isAnonymous,
                  ),
                ),
                IconButton(
                  icon: _isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  onPressed: (_isPosting || (user == null || user.isAnonymous))
                      ? null
                      : _postComment,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
