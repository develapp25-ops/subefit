import 'package:flutter/material.dart';

class SubefitCelebration extends StatefulWidget {
  final String message;
  final VoidCallback? onEnd;
  const SubefitCelebration({Key? key, required this.message, this.onEnd})
      : super(key: key);

  @override
  State<SubefitCelebration> createState() => _SubefitCelebrationState();
}

class _SubefitCelebrationState extends State<SubefitCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (widget.onEnd != null) widget.onEnd!();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confeti/fuegos artificiales (placeholder, puedes integrar un paquete real)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) => Opacity(
                opacity: _anim.value,
                child: child,
              ),
              child: const Center(
                child: Text('🎉🎆', style: TextStyle(fontSize: 80)),
              ),
            ),
          ),
        ),
        // Mensaje motivacional
        Center(
          child: ScaleTransition(
            scale: _anim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Color(0xFF00FF94),
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
