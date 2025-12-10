import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType { daily, weekly, monthly, custom }

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int targetReps;
  final int currentReps;
  final DateTime startDate;
  final DateTime endDate;
  final int reward; // puntos
  final String exerciseId;
  final bool isCompleted;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetReps,
    required this.currentReps,
    required this.startDate,
    required this.endDate,
    required this.reward,
    required this.exerciseId,
    required this.isCompleted,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Challenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: _parseChallengeType(data['type'] ?? 'daily'),
      targetReps: data['targetReps'] ?? 0,
      currentReps: data['currentReps'] ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 30)),
      reward: data['reward'] ?? 100,
      exerciseId: data['exerciseId'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.toString(),
      'targetReps': targetReps,
      'currentReps': currentReps,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reward': reward,
      'exerciseId': exerciseId,
      'isCompleted': isCompleted,
    };
  }

  static ChallengeType _parseChallengeType(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return ChallengeType.daily;
      case 'weekly':
        return ChallengeType.weekly;
      case 'monthly':
        return ChallengeType.monthly;
      case 'custom':
        return ChallengeType.custom;
      default:
        return ChallengeType.daily;
    }
  }

  bool get isActive => DateTime.now().isBefore(endDate);
  double get progressPercent => currentReps > 0 ? (currentReps / targetReps) * 100 : 0;
  bool get isExpired => DateTime.now().isAfter(endDate);
}
