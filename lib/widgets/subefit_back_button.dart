import 'package:flutter/material.dart';

class SubefitBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;
  const SubefitBackButton(
      {Key? key, required this.onPressed, this.isDark = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
      child: IconButton(
        icon: const Text('🔙', style: TextStyle(fontSize: 28)),
        color: isDark ? Colors.white : Colors.black,
        tooltip: 'Volver atrás',
        onPressed: onPressed,
        splashRadius: 28,
        highlightColor: Colors.transparent,
        splashColor: const Color(0xFF00E5FF).withOpacity(0.2),
      ),
    );
  }
}
