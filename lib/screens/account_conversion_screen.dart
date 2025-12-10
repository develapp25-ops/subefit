import 'package:flutter/material.dart';

class AccountConversionScreen extends StatefulWidget {
  const AccountConversionScreen({Key? key}) : super(key: key);

  @override
  State<AccountConversionScreen> createState() =>
      _AccountConversionScreenState();
}

class _AccountConversionScreenState extends State<AccountConversionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asegura tu Cuenta'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Esta función ya no está disponible. Por favor, crea una cuenta desde la pantalla de inicio de sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
