import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType { daily, weekly, special }

enum ChallengeGoal { distance, workouts, points }

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeGoal goalType;
  final int goalValue;
  final int rewardPoints;
  final Timestamp? expiryDate;
  final String difficulty;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.goalType,
    required this.goalValue,
    required this.rewardPoints,
    this.expiryDate,
    this.difficulty = 'Media',
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] ?? 'Sin título',
      description: data['description'] ?? 'Sin descripción',
      type: ChallengeType.values.firstWhere(
          (e) => e.toString() == 'ChallengeType.${data['type']}',
          orElse: () => ChallengeType.daily),
      goalType: ChallengeGoal.values.firstWhere(
          (e) => e.toString() == 'ChallengeGoal.${data['goalType']}',
          orElse: () => ChallengeGoal.workouts),
      goalValue: data['goalValue'] ?? 0,
      rewardPoints: data['rewardPoints'] ?? 0,
      expiryDate: data['expiryDate'] as Timestamp?,
      difficulty: data['difficulty'] ?? 'Media',
    );
  }
}
