import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subefit/widgets/subefit_colors.dart';
import 'local_auth_service.dart';

class LoginScreenLocal extends StatefulWidget {
  const LoginScreenLocal({Key? key}) : super(key: key);

  @override
  _LoginScreenLocalState createState() => _LoginScreenLocalState();
}

class _LoginScreenLocalState extends State<LoginScreenLocal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<LocalAuthService>(context, listen: false);
      final success = await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!success && mounted) {
        setState(() {
          _errorMessage = 'Correo o contraseña incorrectos.';
        });
      }
      // Si el login es exitoso, AuthGate se encargará de la navegación.
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocurrió un error. Inténtalo de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBodyBehindAppBar permite que el body se dibuje detrás de la AppBar (y la barra de estado)
      extendBodyBehindAppBar: true,
      // La AppBar se hace transparente para que se vea el fondo.
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        // Usamos un Stack para superponer los elementos
        children: [
          // 1. Imagen de fondo que cubre todo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondoparaloguin.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Capa oscura para legibilidad
          Positioned.fill(
            child: Container(
              color: Colors.black
                  .withOpacity(0.6), // Opacidad ajustada para mayor legibilidad
            ),
          ),
          // 3. Contenido del formulario
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.1), // Espacio superior
                  Image.asset('assets/images/logorojo.png', height: 80),
                  const SizedBox(height: 16),
                  const Text(
                      'Bienvenido de vuelta', // CORREGIDO: Se eliminó el texto "ECESITO U" que causaba un error.
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Inicia sesión para continuar tu progreso',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                              labelText: 'Correo electrónico'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              (value!.isEmpty || !value.contains('@'))
                                  ? 'Ingresa un correo válido'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration:
                              const InputDecoration(labelText: 'Contraseña'),
                          obscureText: true,
                          validator: (value) => (value!.length < 6)
                              ? 'La contraseña es muy corta'
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
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3, color: Colors.white),
                                )
                              : const Text('Iniciar Sesión'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes una cuenta?',
                          style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/register'),
                        child: const Text(
                          'Regístrate aquí',
                          style: TextStyle(
                              color: SubefitColors.primaryRed,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
