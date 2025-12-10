import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExerciseVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final String? gifUrl;
  final String imageUrl;

  const ExerciseVideoPlayer({
    this.videoUrl,
    this.gifUrl,
    required this.imageUrl,
    Key? key,
  }) : super(key: key);

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    // Si hay GIF, mostrar primero
    if (widget.gifUrl != null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[300],
        ),
        child: Image.network(
          widget.gifUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress != null
                  ? const Center(child: CircularProgressIndicator())
                  : child,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackImage(),
        ),
      );
    }

    // Fallback a imagen estática
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[300],
      ),
      child: Image.asset(
        widget.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[400],
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 60),
          ),
        ),
      ),
    );
  }
}
