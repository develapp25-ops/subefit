import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id; // ID del documento del comentario en Firestore
  final String autorId; // ID del usuario que hizo el comentario
  final String
      autorNombre; // Nombre del usuario (desnormalizado para eficiencia)
  final String texto;
  final DateTime fecha; // Fecha y hora del comentario

  Comment({
    required this.id,
    required this.autorId,
    required this.autorNombre,
    required this.texto,
    required this.fecha,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      autorId: data['autorId'] ?? '',
      autorNombre: data['autorNombre'] ?? 'Anónimo',
      texto: data['texto'] ?? '',
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'autorId': autorId,
      'autorNombre': autorNombre,
      'texto': texto,
      'fecha': FieldValue.serverTimestamp(), // Usamos el timestamp del servidor
    };
  }
}
