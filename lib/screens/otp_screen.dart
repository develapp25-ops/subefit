import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:subefit/screens/firebase_auth_service.dart';
import 'package:pinput/pinput.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;

  const OTPScreen({Key? key, required this.verificationId}) : super(key: key);

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp(String otp) async {
    setState(() => _isLoading = true);

    final authService =
        Provider.of<FirebaseAuthService>(context, listen: false);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      await authService.signInWithPhoneCredential(credential);

      if (mounted) {
        // Si el login es exitoso, AuthGate nos llevará a la pantalla correcta.
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar el código: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Código'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ingresa el código de 6 dígitos que recibiste por SMS.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Pinput(
              controller: _pinController,
              length: 6,
              onCompleted: (pin) => _verifyOtp(pin),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  if (_pinController.text.length == 6) {
                    _verifyOtp(_pinController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Por favor, ingresa el código completo.')),
                    );
                  }
                },
                child: const Text('Verificar e Iniciar Sesión'),
              ),
          ],
        ),
      ),
    );
  }
}
