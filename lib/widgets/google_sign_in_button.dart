import 'package:flutter/material.dart';

import 'subefit_colors.dart';

/// Un widget personalizado para el botón de Google que maneja la renderización
/// nativa en la web y un botón personalizado en móvil.
class GoogleSignInButton extends StatelessWidget {
  final Future<void> Function() onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continuar con Google',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ahora usamos el mismo estilo de botón para todas las plataformas.
    // El paquete google_sign_in se encarga de mostrar el popup correcto en web.
    return ElevatedButton.icon(
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(4)),
        child: Image.asset('assets/images/google_logo.png', height: 20.0),
      ),
      label: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(text),
      onPressed: isLoading ? null : onPressed,
      // El estilo ahora coincide con el tema principal de la app
      style: ElevatedButton.styleFrom(
          backgroundColor: SubefitColors.primaryRed,
          foregroundColor: Colors.white),
    );
  }
}
