import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para gestionar el perfil inteligente del usuario
/// Incluye equipamiento, nivel, lesiones y preferencias
class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guardar perfil completo del usuario
  Future<void> saveUserProfile(String userId, UserProfile profile) async {
    await _firestore.collection('users').doc(userId).update({
      'profile': profile.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Obtener perfil del usuario
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data()!.containsKey('profile')) {
      return UserProfile.fromJson(doc['profile']);
    }
    return null;
  }

  /// Filtrar sesiones según equipamiento y nivel
  List<String> getAvailableEquipment(UserProfile profile) {
    List<String> equipment = [];
    if (profile.hasDumbbells) equipment.add('mancuernas');
    if (profile.hasResistanceBand) equipment.add('banda');
    if (profile.hasBar) equipment.add('barra');
    if (profile.hasKettlebell) equipment.add('kettlebell');
    equipment.add('peso corporal'); // Siempre disponible
    return equipment;
  }

  /// Verificar si puede hacer un ejercicio según su perfil
  bool canPerformExercise(String exerciseType, UserProfile profile) {
    // Validar lesiones
    if (profile.injuries.contains('espalda') && exerciseType.contains('espalda')) {
      return false;
    }
    if (profile.injuries.contains('rodilla') && exerciseType.contains('rodilla')) {
      return false;
    }
    if (profile.injuries.contains('hombro') && exerciseType.contains('hombro')) {
      return false;
    }
    return true;
  }
}

/// Modelo de Perfil Inteligente del usuario
class UserProfile {
  final String userId;
  final String level; // 'principiante', 'intermedio', 'avanzado'
  final bool hasDumbbells;
  final bool hasResistanceBand;
  final bool hasBar;
  final bool hasKettlebell;
  final List<String> injuries; // ['espalda', 'rodilla', 'hombro', etc]
  final List<String> preferences; // ['cardio', 'fuerza', 'flexibilidad', etc]
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    this.level = 'intermedio',
    this.hasDumbbells = false,
    this.hasResistanceBand = false,
    this.hasBar = false,
    this.hasKettlebell = false,
    this.injuries = const [],
    this.preferences = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'level': level,
        'hasDumbbells': hasDumbbells,
        'hasResistanceBand': hasResistanceBand,
        'hasBar': hasBar,
        'hasKettlebell': hasKettlebell,
        'injuries': injuries,
        'preferences': preferences,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['userId'] ?? '',
        level: json['level'] ?? 'intermedio',
        hasDumbbells: json['hasDumbbells'] ?? false,
        hasResistanceBand: json['hasResistanceBand'] ?? false,
        hasBar: json['hasBar'] ?? false,
        hasKettlebell: json['hasKettlebell'] ?? false,
        injuries: List<String>.from(json['injuries'] ?? []),
        preferences: List<String>.from(json['preferences'] ?? []),
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      );

  UserProfile copyWith({
    String? level,
    bool? hasDumbbells,
    bool? hasResistanceBand,
    bool? hasBar,
    bool? hasKettlebell,
    List<String>? injuries,
    List<String>? preferences,
  }) =>
      UserProfile(
        userId: userId,
        level: level ?? this.level,
        hasDumbbells: hasDumbbells ?? this.hasDumbbells,
        hasResistanceBand: hasResistanceBand ?? this.hasResistanceBand,
        hasBar: hasBar ?? this.hasBar,
        hasKettlebell: hasKettlebell ?? this.hasKettlebell,
        injuries: injuries ?? this.injuries,
        preferences: preferences ?? this.preferences,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
