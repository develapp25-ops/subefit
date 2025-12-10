import 'package:flutter/material.dart';

class SubefitButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final String? emoji;
  final bool isPrimary;
  final bool isDanger;
  final bool isDisabled;
  final double minWidth;
  final double minHeight;

  const SubefitButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.emoji,
    this.isPrimary = false,
    this.isDanger = false,
    this.isDisabled = false,
    this.minWidth = 140,
    this.minHeight = 48,
  }) : super(key: key);

  @override
  State<SubefitButton> createState() => _SubefitButtonState();
}

class _SubefitButtonState extends State<SubefitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTapDown(TapDownDetails d) {
    _controller.forward();
    // TODO: reproducir sonido de clic si se desea
  }

  void _onTapUp(TapUpDetails d) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isDanger
        ? Colors.redAccent
        : widget.isPrimary
            ? const Color(0xFF00E5FF)
            : widget.color ?? Colors.white;
    final Color fg = widget.isDanger
        ? Colors.white
        : widget.isPrimary
            ? Colors.black
            : widget.textColor ?? Colors.black;
    return GestureDetector(
      onTapDown: widget.isDisabled ? null : _onTapDown,
      onTapUp: widget.isDisabled ? null : _onTapUp,
      onTapCancel: widget.isDisabled ? null : _onTapCancel,
      onTap: widget.isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          constraints: BoxConstraints(
              minWidth: widget.minWidth, minHeight: widget.minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDisabled ? Colors.grey[400] : bg,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: bg.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.emoji != null)
                Text(widget.emoji!, style: const TextStyle(fontSize: 22)),
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
