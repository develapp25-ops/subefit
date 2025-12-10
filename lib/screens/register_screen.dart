import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:subefit/widgets/google_sign_in_button.dart';
import 'firebase_auth_service.dart';
import 'package:subefit/screens/user_data_wizard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  Future<void> _handleGoogleRegister() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService =
          Provider.of<FirebaseAuthService>(context, listen: false);
      final user = await authService.signInWithGoogle();

      // AuthGate se encargará de la navegación.
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailPasswordRegister() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService =
          Provider.of<FirebaseAuthService>(context, listen: false);
      // Pasamos todos los datos necesarios para el registro.
      await authService.createUserWithEmailAndPassword(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        // Navegamos directamente al nuevo asistente de configuración de datos.
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => UserDataWizardScreen(),
          ),
          (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SubefitColors.appWhite,
      appBar: AppBar(
        backgroundColor: SubefitColors.appWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: SubefitColors.textBlack),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Image.asset('assets/images/logorojo.png', height: 60),
              const SizedBox(height: 16),
              const Text('Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: SubefitColors.textBlack)),
              const SizedBox(height: 8),
              const Text('Únete a la comunidad y empieza a entrenar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 50),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: SubefitColors.dangerRed,
                          fontWeight: FontWeight.bold)),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration:
                          const InputDecoration(labelText: 'Nombre de usuario'),
                      keyboardType: TextInputType.text,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Ingresa un nombre de usuario'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: 'Correo electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value == null ||
                              value.isEmpty ||
                              !value.contains('@'))
                          ? 'Ingresa un correo válido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                          labelText: 'Contraseña (mín. 6 caracteres)'),
                      obscureText: true,
                      validator: (value) => (value == null || value.length < 6)
                          ? 'La contraseña es muy corta'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleEmailPasswordRegister,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white))
                    : const Text('Registrarse'),
              ),
              const SizedBox(height: 20),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('O')),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GoogleSignInButton(
                  onPressed: _handleGoogleRegister,
                  isLoading: _isLoading,
                  text: 'Registrarse con Google', // Texto más explícito
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿Ya tienes una cuenta?',
                      style: TextStyle(color: Colors.black54)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Inicia sesión',
                        style: TextStyle(
                            color: SubefitColors.primaryRed,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
