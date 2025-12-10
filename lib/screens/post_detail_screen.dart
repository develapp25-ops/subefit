import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:subefit/screens/post_model.dart';
import 'package:subefit/screens/comment_model.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/widgets/post_card.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (text.isEmpty || currentUser == null) {
      return;
    }

    // Obtenemos el perfil del usuario actual para usar su nombre.
    final userProfile = await _firebaseService.getUserProfile(currentUser.uid);
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo encontrar tu perfil para comentar.')),
      );
      return;
    }

    try {
      await _firebaseService.addComment(
        postId: widget.post.id,
        autorId: currentUser.uid,
        autorNombre: userProfile.nombre,
        texto: text,
      );
      _commentController.clear();
      _commentFocusNode.unfocus(); // Oculta el teclado después de enviar.
      // Pequeño delay para dar tiempo a que la UI se actualice con el nuevo comentario
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients)
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir comentario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Mostramos la tarjeta de la publicación original.
                SliverToBoxAdapter(
                  child: PostCard(post: widget.post),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text('Comentarios',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                // Usamos un StreamBuilder para mostrar los comentarios en tiempo real.
                StreamBuilder<QuerySnapshot>(
                  stream: _firebaseService.getCommentsStream(widget.post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                              child: Text(
                                  'No hay comentarios todavía. ¡Sé el primero!')),
                        ),
                      );
                    }

                    final comments = snapshot.data!.docs
                        .map((doc) => Comment.fromFirestore(doc))
                        .toList();

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            title: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                      text: '${comment.autorNombre} ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  TextSpan(
                                      text: comment.texto,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal)),
                                ],
                              ),
                            ),
                            subtitle: Text(
                                timeago.format(comment.fecha, locale: 'es')),
                          );
                        },
                        childCount: comments.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Área para escribir un nuevo comentario.
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: const InputDecoration.collapsed(
                  hintText: 'Añadir un comentario...'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: SubefitColors.primaryRed),
            onPressed: _addComment,
          ),
        ],
      ),
    );
  }
}
