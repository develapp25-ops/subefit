// Modelo simple para representar una publicación en el feed.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:subefit/screens/user_profile_model.dart';

class Post {
  final String id;
  final String autorID;
  final String texto;
  final DateTime fecha;
  final int likes;
  final int comentarios;
  final int compartidas;
  final String? autorNombre;
  final String? autorFotoUrl;
  final Map<String, dynamic>? reacciones;

  Post({
    required this.id,
    required this.autorID,
    required this.texto,
    required this.fecha,
    required this.likes,
    required this.comentarios,
    this.compartidas = 0,
    this.autorNombre,
    this.autorFotoUrl,
    this.reacciones,
  });

  // Factory constructor para crear desde un DocumentSnapshot de Firestore
  factory Post.fromFirestore(DocumentSnapshot doc, UserProfile? author) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      autorID: data['autorID'] ?? '',
      texto: data['texto'] ?? '',
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      comentarios: data['comentarios'] ?? 0,
      compartidas: data['compartidas'] ?? 0,
      autorNombre: author?.nombre,
      autorFotoUrl: author?.fotoUrl,
      reacciones: data['reacciones'],
    );
  }
}
