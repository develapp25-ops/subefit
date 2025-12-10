import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:subefit/screens/comments_screen.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/post_model.dart';
import 'package:subefit/widgets/subefit_colors.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({Key? key, required this.post, this.onTap}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirebaseService _firebaseService = FirebaseService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  bool _isLiked = false;
  bool _isShared = false;
  late int _likeCount;
  late int _sharedCount;
  bool _isProcessingLike = false;
  bool _isProcessingShare = false;

  final List<String> _reactions = ['❤️', '🔥', '💪', '👏', '🎉'];
  String? _selectedReaction;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likes;
    _sharedCount = widget.post.compartidas;
    _checkIfLiked();
    _checkIfShared();
  }

  Future<void> _checkIfLiked() async {
    if (_currentUserId == null) return;
    final liked =
        await _firebaseService.hasLikedPost(_currentUserId, widget.post.id);
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _checkIfShared() async {
    if (_currentUserId == null) return;
    try {
      final sharedPosts = await _firebaseService.getSharedPosts(_currentUserId);
      if (mounted) {
        setState(() {
          _isShared = sharedPosts.any((p) => p.id == widget.post.id);
        });
      }
    } catch (e) {
      debugPrint('Error checking if shared: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (_currentUserId == null || _isProcessingLike) return;

    setState(() {
      _isProcessingLike = true;
    });

    try {
      await _firebaseService.toggleLike(
          _currentUserId, widget.post.id, _isLiked);
      
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      debugPrint("Error al dar like: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingLike = false;
        });
      }
    }
  }

  Future<void> _toggleShare() async {
    if (_currentUserId == null || _isProcessingShare) return;

    setState(() {
      _isProcessingShare = true;
    });

    try {
      if (_isShared) {
        // TODO: Remover de compartidas
      } else {
        await _firebaseService.sharePost(_currentUserId, widget.post.id);
      }
      
      if (mounted) {
        setState(() {
          _isShared = !_isShared;
          _sharedCount += _isShared ? 1 : -1;
        });
      }
    } catch (e) {
      debugPrint("Error al compartir: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingShare = false;
        });
      }
    }
  }

  Future<void> _addReaction(String reaction) async {
    if (_currentUserId == null) return;

    try {
      await _firebaseService.addReactionToPost(
          widget.post.id, _currentUserId, reaction);
      
      if (mounted) {
        setState(() {
          _selectedReaction = reaction;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reaccionaste con $reaction'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al reaccionar: $e");
    }
  }

  void _showReactionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Elige tu reacción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: _reactions.map((reaction) {
                return GestureDetector(
                  onTap: () {
                    _addReaction(reaction);
                    Navigator.pop(context);
                  },
                  child: Text(
                    reaction,
                    style: const TextStyle(fontSize: 32),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        color: SubefitColors.darkGrey.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              Text(widget.post.texto,
                  style: const TextStyle(
                      fontSize: 15, color: SubefitColors.textWhite)),
              const SizedBox(height: 12),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white24,
          child: const Icon(Icons.person, color: Colors.white70),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.autorNombre ?? 'Atleta Anónimo',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                DateFormat.yMMMd('es').add_jm().format(widget.post.fecha),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Tooltip(
                  message: 'Me gusta',
                  child: IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? SubefitColors.dangerRed : Colors.white70,
                    ),
                    onPressed: _toggleLike,
                  ),
                ),
                Text('$_likeCount', style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 16),
                Tooltip(
                  message: 'Comentarios',
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => CommentsScreen(postId: widget.post.id)),
                      );
                    },
                  ),
                ),
                Text(widget.post.comentarios.toString(), style: const TextStyle(color: Colors.white70)),
              ],
            ),
            Row(
              children: [
                Tooltip(
                  message: 'Reacciones',
                  child: IconButton(
                    icon: Text(_selectedReaction ?? '😊', style: const TextStyle(fontSize: 20)),
                    onPressed: _showReactionPicker,
                  ),
                ),
                Tooltip(
                  message: 'Guardar',
                  child: IconButton(
                    icon: Icon(
                      _isShared ? Icons.bookmark : Icons.bookmark_border,
                      color: _isShared ? SubefitColors.primaryRed : Colors.white70,
                    ),
                    onPressed: _toggleShare,
                  ),
                ),
                Text('$_sharedCount', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
