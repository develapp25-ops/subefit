import 'dart:typed_data';

import 'package:flutter/material.dart';

class UserDataModel {
  // Step 0: Avatar
  // Guardamos la imagen como bytes para ser compatibles con web y móvil.
  Uint8List? avatarBytes;
  // Step 1: Physical Data
  double? height;
  double? weight;
  String? gender;

  // Step 2: Goals
  String? mainGoal;
  double intensity = 5;
  bool includeCardio = true;

  // Step 3: Habits
  double sleepHours = 7;
  TimeOfDay? bedtime;
  TimeOfDay? wakeupTime;
  String? energyLevel;

  // Step 4: Health
  Set<String> injuries = {};
  String? medicalNotes;

  // Step 5: Experience
  String? experienceLevel;
  String? trainingLocation;
  String? gymAccess;
}
