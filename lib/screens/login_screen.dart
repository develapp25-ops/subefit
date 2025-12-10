import 'package:flutter/material.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:subefit/widgets/google_sign_in_button.dart';
import 'firebase_auth_service.dart'; // Cambiamos al servicio de Firebase
import 'package:provider/provider.dart';
import 'register_screen.dart'; // Importamos la pantalla de registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Determinar si el usuario está intentando iniciar sesión con email o nombre de usuario.
      String loginIdentifier = _emailController.text.trim();
      String password = _passwordController.text.trim();

      final authService =
          Provider.of<FirebaseAuthService>(context, listen: false);

      // Si no es un email, asumimos que es un nombre de usuario y buscamos el email correspondiente.
      if (!loginIdentifier.contains('@')) {
        final email = await authService.getEmailFromUsername(loginIdentifier);
        if (email == null) {
          throw 'No se encontró un usuario con ese nombre. Intenta con tu correo electrónico.';
        }
        loginIdentifier = email;
      }

      await authService.signInWithEmailAndPassword(loginIdentifier, password);
      // AuthGate se encargará de la navegación si el login es exitoso.
    } catch (e) {
      // El servicio ya nos da un mensaje amigable.
      // Lo usamos directamente en lugar de convertirlo a String de nuevo.
      if (mounted) {
        // Hacemos el mensaje de error más claro para el usuario.
        // El servicio ya devuelve "Correo o contraseña incorrectos."
        // Podemos añadir una pista si el usuario podría estar usando su nombre de usuario.
        final message = e.toString();
        setState(() => _errorMessage = message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
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
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              // Contenedor principal del contenido
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Image.asset('assets/images/logorojo.png', height: 150),
                const SizedBox(height: 21),
                const Text('Bienvenido a SubeFit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333))),
                const SizedBox(height: 8),
                const Text(
                    'Inicia sesión o regístrate para guardar tu progreso',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Correo o Nombre de Usuario'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Ingresa tu correo o nombre de usuario'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(
                            () => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) => (value == null || value.length < 6)
                      ? 'La contraseña debe tener al menos 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(_errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: SubefitColors.dangerRed,
                            fontWeight: FontWeight.bold)),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
                      : const Text('Iniciar Sesión'),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black26)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('O', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider(color: Colors.black26)),
                  ],
                ),
                const SizedBox(height: 20),
                GoogleSignInButton(
                  onPressed: _handleGoogleLogin,
                  isLoading: _isLoading,
                  text: 'Continuar con Google',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.phone_android_outlined),
                  label: const Text('Continuar con Teléfono'),
                  onPressed: _isLoading
                      ? null
                      : () {
                          // Asumiendo que tienes una ruta '/phone-login' para PhoneLoginScreen
                          Navigator.of(context).pushNamed('/phone-login');
                        },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    _showPasswordResetDialog(context);
                  },
                  child: const Text('¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes una cuenta?',
                        style: TextStyle(color: Colors.black54)),
                    TextButton(
                      onPressed: () {
                        // Navegamos a la pantalla de registro
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const RegisterScreen()));
                      },
                      child: const Text('Regístrate',
                          style: TextStyle(
                              color: SubefitColors.primaryRed,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ),
    );
  }

  void _showPasswordResetDialog(BuildContext context) {
    final resetEmailController =
        TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.'),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Correo Electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                final authService =
                    Provider.of<FirebaseAuthService>(context, listen: false);
                try {
                  await authService.sendPasswordResetEmail(email);
                  Navigator.of(context).pop(); // Cierra el diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Se ha enviado un correo de restablecimiento.'),
                        backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: SubefitColors.dangerRed),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
