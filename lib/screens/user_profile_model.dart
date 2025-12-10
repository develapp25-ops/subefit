import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id; // El ID del documento será el UID del usuario
  final String nombre;
  final String? email; // Añadimos el campo para el email
  final String? biografia;
  final String? fotoUrl;
  final bool publico;
  final int seguidores;
  final int seguidos;
  final int publicaciones;
  // Campos migrados desde el almacenamiento local
  final double weight;
  final double height;
  final String goals;
  final bool isProfileComplete;
  final int level;
  final int totalPoints;
  final int streak;
  // NUEVO: Campos añadidos para corregir errores
  final int? age;
  final String? gender;

  UserProfile({
    required this.id,
    required this.nombre,
    this.email,
    this.biografia,
    this.fotoUrl,
    required this.publico,
    required this.seguidores,
    required this.seguidos,
    this.publicaciones = 0,
    this.weight = 0.0,
    this.height = 0.0,
    this.goals = '',
    this.isProfileComplete = false,
    this.level = 1,
    this.totalPoints = 0,
    this.streak = 0,
    this.age,
    this.gender,
  });

  String get levelString {
    if (level < 5) return 'Principiante';
    if (level < 15) return 'Intermedio';
    return 'Avanzado';
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      nombre: data['nombre'] ?? 'Atleta Anónimo',
      email: data['email'], // Leemos el email desde Firestore
      biografia: data['biografia'], // Puede ser null
      fotoUrl: data[
          'fotoUrl'], // Corregido de 'foto' a 'fotoUrl' para coincidir con la BD
      publico: data['publico'] ?? true,
      seguidores: data['seguidores'] ?? 0,
      seguidos: data['seguidos'] ?? 0,
      publicaciones: data['publicaciones'] ?? 0,
      // Leer los nuevos campos desde Firestore con valores por defecto
      weight: (data['weight'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      goals: data['goals'] ?? '',
      isProfileComplete: data['isProfileComplete'] ?? false,
      level: data['level'] ?? 1,
      totalPoints: data['totalPoints'] ?? 0,
      streak: data['streak'] ?? 0,
      age: data['age'],
      gender: data['gender'],
    );
  }
}
