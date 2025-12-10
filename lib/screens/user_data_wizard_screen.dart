import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:lottie/lottie.dart';

import 'avatar_step.dart'; // NUEVO: Importar el paso del avatar
import 'physical_data_step.dart';
import 'goals_step.dart';
import 'habits_step.dart';
import 'health_step.dart';
import 'experience_step.dart';
import 'summary_step.dart';
import 'user_data_model.dart';
import 'firebase_service.dart'; // NUEVO: Importar FirebaseService
import '../widgets/subefit_colors.dart';

class UserDataWizardScreen extends StatefulWidget {
  const UserDataWizardScreen({Key? key}) : super(key: key);

  @override
  State<UserDataWizardScreen> createState() => _UserDataWizardScreenState();
}

class _UserDataWizardScreenState extends State<UserDataWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7; // 6 steps + summary

  // Modelo para almacenar los datos del usuario a través de los pasos
  final UserDataModel _userData = UserDataModel();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      // Previene errores si el pageController se usa antes de que la página esté construida.
      if (_pageController.page?.round() != _currentStep)
        _onPageChanged(_pageController.page!.round());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics:
                      const NeverScrollableScrollPhysics(), // Deshabilita el swipe
                  children: [
                    AvatarStep(
                        userData: _userData,
                        onNext: _nextPage), // NUEVO: Añadir el paso del avatar
                    PhysicalDataStep(userData: _userData, onNext: _nextPage),
                    GoalsStep(userData: _userData, onNext: _nextPage),
                    HabitsStep(userData: _userData, onNext: _nextPage),
                    HealthStep(userData: _userData, onNext: _nextPage),
                    ExperienceStep(userData: _userData, onNext: _nextPage),
                    SummaryStep(userData: _userData, onFinish: _finishWizard),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finishWizard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firebaseService = FirebaseService();
    String? avatarUrl;

    // 1. Si el usuario seleccionó un avatar, lo subimos
    if (_userData.avatarBytes != null) {
      try {
        avatarUrl = await firebaseService.uploadProfileImage(user.uid,
            imageBytes: _userData.avatarBytes!);
      } catch (e) {
        // Manejar error de subida si es necesario
        debugPrint("Error al subir el avatar: $e");
      }
    }

    // 2. Preparamos los datos para guardar en Firestore
    final dataToSave = {
      'fotoUrl': avatarUrl, // Puede ser null si no se eligió imagen
      // ... aquí irían los otros datos del _userData model
      'isProfileComplete': true,
    };

    await firebaseService.updateUserProfile(user.uid, dataToSave);
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _currentStep > 0
                  ? IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                    )
                  : const SizedBox(width: 48), // Placeholder for alignment
              Text(
                'Paso ${_currentStep + 1} de $_totalSteps',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              _currentStep == _totalSteps - 1
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _finishWizard,
                    )
                  : const SizedBox(width: 48), // Placeholder
            ],
          ),
          const SizedBox(height: 12),
          StepProgressIndicator(
            totalSteps: _totalSteps,
            currentStep: _currentStep + 1,
            size: 8,
            padding: 0,
            selectedColor: SubefitColors.primaryRed,
            unselectedColor: Colors.white.withOpacity(0.2),
            roundedEdges: const Radius.circular(10),
          ),
        ],
      ),
    );
  }
}

class WizardSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const WizardSection({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 32),
        ...children,
      ],
    );
  }
}
