import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'user_data_model.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ignore: must_be_immutable
class SummaryStep extends StatefulWidget {
  final UserDataModel userData;
  final VoidCallback onFinish;

  const SummaryStep({Key? key, required this.userData, required this.onFinish})
      : super(key: key);

  @override
  State<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<SummaryStep> {
  bool _isSaving = false;

  Future<void> _saveAndFinish() async {
    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Aquí iría la lógica para guardar los datos en Firebase
    // Por ejemplo:
    await FirebaseService().updateUserProfile(user.uid, {
      'height': widget.userData.height,
      'weight': widget.userData.weight,
      'goals': widget.userData.mainGoal,
      'isProfileComplete': true,
      // ...y todos los demás campos del UserDataModel
    });

    // Simula un pequeño retraso para la animación
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie/dna.json', height: 250),
          const SizedBox(height: 24),
          const Text(
            'Creando tu ADN Fitness...',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text('Estamos personalizando tu plan perfecto.',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 40),
          ElevatedButton(
              onPressed: _saveAndFinish,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Comenzar mi Viaje')),
        ],
      ),
    );
  }
}
