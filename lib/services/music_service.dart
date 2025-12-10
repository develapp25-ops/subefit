/// Servicio para gestionar música durante entrenamientos
class MusicService {
  /// Modelo de Playlist según tipo de sesión
  static Map<String, Playlist> getPlaylistsBySessionType() => {
        'cardio': const Playlist(
          id: 'cardio',
          name: 'High Energy Cardio',
          description: 'Música energética para cardio intenso',
          targetBPM: 140,
          icon: '🔥',
          spotifyURI: 'spotify:playlist:cardio_high_energy', // Ejemplo
          localTrackCount: 30,
        ),
        'fuerza': const Playlist(
          id: 'fuerza',
          name: 'Power & Strength',
          description: 'Música poderosa para entrenamientos de fuerza',
          targetBPM: 100,
          icon: '💪',
          spotifyURI: 'spotify:playlist:power_strength',
          localTrackCount: 25,
        ),
        'flexibilidad': const Playlist(
          id: 'flexibilidad',
          name: 'Zen & Stretch',
          description: 'Música relajante para flexibilidad',
          targetBPM: 60,
          icon: '🧘',
          spotifyURI: 'spotify:playlist:zen_stretch',
          localTrackCount: 20,
        ),
        'core': const Playlist(
          id: 'core',
          name: 'Core Killer',
          description: 'Ritmo constante para core y abdominales',
          targetBPM: 120,
          icon: '⚡',
          spotifyURI: 'spotify:playlist:core_killer',
          localTrackCount: 28,
        ),
        'amrap': const Playlist(
          id: 'amrap',
          name: 'Beast Mode',
          description: 'Música extrema para AMRAP',
          targetBPM: 150,
          icon: '🎸',
          spotifyURI: 'spotify:playlist:beast_mode',
          localTrackCount: 35,
        ),
      };

  /// Obtener playlist recomendada según sesión
  static Playlist? getRecommendedPlaylist(String sessionType) {
    return getPlaylistsBySessionType()[sessionType.toLowerCase()];
  }

  /// Calcular BPM ideal según tipo de ejercicio
  static int calculateIdealBPM(String exerciseType) {
    const bpmMap = {
      'cardio': 140,
      'fuerza': 100,
      'amrap': 150,
      'core': 120,
      'flexibilidad': 60,
    };
    return bpmMap[exerciseType] ?? 120;
  }

  /// Obtener recomendación de artista según energía
  static String getArtistRecommendation(int targetBPM) {
    if (targetBPM >= 140) {
      return 'Recomendado: Dua Lipa, The Weeknd, Calvin Harris';
    } else if (targetBPM >= 120) {
      return 'Recomendado: Eminem, Post Malone, Juice WRLD';
    } else if (targetBPM >= 100) {
      return 'Recomendado: 50 Cent, Drake, Travis Scott';
    } else {
      return 'Recomendado: Billie Eilish, Khalid, Clairo';
    }
  }

  /// Validar si una canción es adecuada para el entrenamiento
  static bool isTrackSuitableForWorkout(Track track, int targetBPM) {
    // Verificar que el BPM está dentro del rango (±10% tolerancia)
    final tolerance = targetBPM * 0.1;
    final isWithinBPMRange = (track.bpm - targetBPM).abs() <= tolerance;

    // Verificar duración (mínimo 2 min para ser útil)
    final isLongEnough = track.durationSeconds >= 120;

    // Verificar que no sea música demasiado explícita
    final isNotExplicit = !track.isExplicit;

    return isWithinBPMRange && isLongEnough && isNotExplicit;
  }

  /// Generar stats de la sesión con música
  static String getMusicSessionStats(
    int tracksPlayed,
    int totalMinutes,
    double avgBPM,
  ) {
    return 'Sesión Musical: $tracksPlayed canciones, $totalMinutes min, BPM promedio: ${avgBPM.toStringAsFixed(0)}';
  }
}

/// Modelo de Playlist
class Playlist {
  final String id;
  final String name;
  final String description;
  final int targetBPM; // Beats per minute objetivo
  final String icon;
  final String? spotifyURI; // URI de Spotify (si disponible)
  final int? localTrackCount; // Número de canciones locales disponibles

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.targetBPM,
    required this.icon,
    this.spotifyURI,
    this.localTrackCount,
  });
}

/// Modelo de Canción / Track
class Track {
  final String id;
  final String title;
  final String artist;
  final int durationSeconds;
  final int bpm; // Beats per minute
  final String? spotifyURI;
  final String? localPath; // Ruta local si está descargada
  final bool isExplicit;
  final String? imageUrl;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.bpm,
    this.spotifyURI,
    this.localPath,
    this.isExplicit = false,
    this.imageUrl,
  });

  /// Convertir duración a formato MM:SS
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Modelo de Sesión de Música
class MusicSessionStats {
  final String playlistId;
  final List<Track> tracksPlayed;
  final DateTime startTime;
  final DateTime endTime;
  final double avgBPM;

  const MusicSessionStats({
    required this.playlistId,
    required this.tracksPlayed,
    required this.startTime,
    required this.endTime,
    required this.avgBPM,
  });

  int get totalDurationSeconds =>
      tracksPlayed.fold(0, (sum, track) => sum + track.durationSeconds);

  int get totalMinutes => totalDurationSeconds ~/ 60;

  double get avgBPMFromTracks =>
      tracksPlayed.isEmpty
          ? 0
          : tracksPlayed.fold(0, (sum, track) => sum + track.bpm) /
              tracksPlayed.length;
}

/// Sugerencias de música según estado del ejercicio
class MusicRecommendationEngine {
  /// Obtener sugerencia cuando se acelera
  static String suggestForAcceleration() {
    return 'Velocidad aumentada. Busca canciones con BPM más alto 🚀';
  }

  /// Obtener sugerencia cuando desacelera
  static String suggestForDeceleration() {
    return 'Ritmo bajando. Prueba con música más relajante 🧘';
  }

  /// Sugerir cambio de playlist por energía
  static String suggestPlaylistChange(String currentSession, int currentEnergy) {
    if (currentEnergy > 80) {
      return 'Nivel máximo de energía. Cambia a Beast Mode 🔥';
    } else if (currentEnergy < 30) {
      return 'Energía baja. Sube con High Energy Cardio ⚡';
    }
    return 'Sigue adelante, vas bien 💪';
  }
}
