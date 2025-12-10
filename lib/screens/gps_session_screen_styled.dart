import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart'; // Para mejor rendimiento en web
import 'package:subefit/widgets/subefit_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'local_data_service.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Para feedback por voz
import 'package:intl/intl.dart';

class GPSSessionScreenStyled extends StatefulWidget {
  const GPSSessionScreenStyled({Key? key}) : super(key: key);

  @override
  State<GPSSessionScreenStyled> createState() => _GPSSessionScreenStyledState();
}

enum LocationStatus { loading, ready, serviceDisabled, permissionDenied, error }

enum SessionState { preparing, stopped, running, paused }

/// Helper para cálculos de distancia.
const Distance _distanceCalculator = Distance();

/// NUEVO: Clase para almacenar un punto de la ruta con su velocidad.
class TrackPoint {
  final Position position;
  TrackPoint({required this.position});
}

/// Helper getter to simplify accessing LatLng from TrackPoint
extension TrackPointExtension on TrackPoint {
  LatLng get point => LatLng(position.latitude, position.longitude);
}

class _GPSSessionScreenStyledState extends State<GPSSessionScreenStyled>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription; // NUEVO: Para escuchar cambios de conexión

  LocationStatus _status = LocationStatus.loading;
  String _statusMessage = 'Cargando posición...';
  bool _isOnline = true;
  bool _isFollowingUser =
      true; // Nuevo: para controlar si el mapa sigue al usuario
  final FlutterTts _flutterTts = FlutterTts();
  // --- Estado de la Sesión ---
  SessionState _sessionState = SessionState.stopped;
  final List<TrackPoint> _routePoints = []; // CAMBIO: Ahora almacena TrackPoint
  Timer? _timer;

  // --- Datos de la Sesión ---
  Duration _elapsedTime = Duration.zero;
  double _distance = 0.0; // en kilómetros
  double _calories = 0.0;
  double _speed = 0.0; // en km/h
  DateTime? _startTime;
  double _userWeight = 70.0; // Peso por defecto
  int _lastKilometerAnnounced = 0;

  // --- NUEVO: Control de la tarjeta de UI ---
  bool _isControlsCardExpanded = true;
  late AnimationController _cardAnimationController;
  bool _isSatelliteView = false; // NUEVO: para controlar el tipo de mapa

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadUserWeight();
    _checkConnectivity(); // NUEVO: Iniciar la escucha de conectividad
    _setupTts();
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("es-ES");
    // CORREGIDO: Se aumenta la velocidad de la voz a un valor más natural.
    // 0.5 es muy lento, 1.0 es normal. 0.8 es un buen punto intermedio.
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _loadUserWeight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await LocalDataService().loadUserData(user.uid);
      if (mounted)
        setState(
            () => _userWeight = (data['weight'] as num?)?.toDouble() ?? 70.0);
    }
  }

  // --- NUEVO: Función para verificar y escuchar el estado de la conexión ---
  void _checkConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final bool hasConnection = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi);
      if (mounted) {
        setState(() => _isOnline = hasConnection);
      }
    });
  }

  Future<void> _initializeLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          setState(() {
            _status = LocationStatus.serviceDisabled;
            _statusMessage =
                'El servicio de ubicación está desactivado. Por favor, actívalo en los ajustes de tu dispositivo.';
          });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted)
            setState(() {
              _status = LocationStatus.permissionDenied;
              _statusMessage =
                  'Permiso de ubicación denegado. La función de GPS no puede usarse sin tu permiso.';
            });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted)
          setState(() {
            _status = LocationStatus.permissionDenied;
            _statusMessage =
                'Permiso de ubicación denegado permanentemente. Debes activarlo manualmente en los ajustes de la aplicación.';
          });
        return;
      }

      // Si llegamos aquí, tenemos permisos.
      setState(() {
        _status = LocationStatus.loading;
        _statusMessage = 'Obteniendo ubicación actual...';
      });

      // Intentamos obtener una posición rápida usando la última conocida
      // para evitar pantalla vacía si el GPS tarda en obtener un fix.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          if (mounted) {
            setState(() {
              _currentPosition = last;
              _status = LocationStatus.ready;
              _sessionState = SessionState.preparing;
              _statusMessage = 'Ubicación cargada (cached).';
            });
          }
        }
      } catch (_) {
        // No crítico, seguimos intentando obtener posición en vivo
      }

      // Solicitar un fix actual pero con timeout razonable.
      // Si falla, ya tenemos la última posición (si existe) y mostramos mensaje.
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 5),
        );
        if (pos != null && mounted) {
          setState(() {
            _currentPosition = pos;
            _status = LocationStatus.ready;
            _sessionState = SessionState.preparing;
            _statusMessage = 'Ubicación actualizada.';
          });
        }
      } catch (e) {
        // Si el getCurrentPosition falla por timeout, no bloqueamos la UI.
        if (mounted && _currentPosition == null) {
          setState(() {
            _status = LocationStatus.loading;
            _statusMessage = 'Esperando posición GPS (puede tardar unos segundos)...';
          });
        }
      }

      // --- MEJORA: Escuchar cambios en el estado del servicio GPS ---
      // Esta función no está soportada en la web, así que la envolvemos en un chequeo.
      if (!kIsWeb) {
        _serviceStatusStream =
            Geolocator.getServiceStatusStream().listen((status) {
          if (status == ServiceStatus.disabled) {
            if (mounted) {
              _speak('Servicio de GPS desactivado. Pausando entrenamiento.');
              setState(() {
                _sessionState = SessionState.paused;
                // CORREGIDO: Actualizamos el estado para mostrar una pantalla de información en lugar del mapa.
                _status = LocationStatus.serviceDisabled;
                _statusMessage =
                    'Se desactivó el servicio de ubicación. La sesión está en pausa.';
              });
            }
          }
        });
      }

      // Configuración del stream de posición
      // --- MEJORA DE PRECISIÓN ---
      // Se definen configuraciones específicas por plataforma para obtener la máxima precisión.
      late LocationSettings locationSettings;

      if (kIsWeb) {
        // La web no soporta configuraciones avanzadas, usamos una básica de alta precisión.
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
      } else if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          forceLocationManager:
              true, // Usa el API de LocationManager para mayor consistencia.
          intervalDuration: const Duration(
              seconds: 1), // Solicita actualizaciones cada segundo.
          // Configuración para que el servicio se ejecute en primer plano y no sea detenido por el SO.
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "Subefit está registrando tu ruta activamente.",
            notificationTitle: "Entrenamiento en progreso",
            enableWakeLock: true,
          ),
        );
      } else if (Platform.isIOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          activityType:
              ActivityType.fitness, // Optimiza para actividades de fitness.
          distanceFilter: 0,
          showBackgroundLocationIndicator:
              true, // Muestra la barra azul de ubicación en segundo plano.
          pauseLocationUpdatesAutomatically:
              false, // Evita que iOS pause las actualizaciones.
        );
      }

      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((newPosition) {
        if (!mounted) return;

        // --- MEJORA DE PRECISIÓN: Filtro de puntos con baja precisión ---
        // Si la precisión reportada por el GPS es mayor a 35 metros, es probable que sea un punto erróneo.
        // Lo ignoramos para evitar "saltos" en la ruta.
        if (newPosition.accuracy > 35) {
          return; // Ignoramos esta actualización por ser poco precisa.
        }
        final bool isFirstFix = _status != LocationStatus.ready;
        setState(() {
          _currentPosition = newPosition;
          if (isFirstFix) {
            _status = LocationStatus.ready;
            _sessionState = SessionState.preparing; // Listo para empezar
          }
        });

        // CORRECCIÓN: Mover el mapa si es el primer punto o si el seguimiento está activo.
        if (isFirstFix || _isFollowingUser) {
          _animatedMapMove(LatLng(newPosition.latitude, newPosition.longitude),
              _mapController.camera.zoom);
        }

        if (_sessionState == SessionState.running) {
          final newTrackPoint = TrackPoint(position: newPosition);

          // Añadir punto a la ruta y calcular distancia
          if (_routePoints.isNotEmpty) {
            final lastTrackPoint = _routePoints.last;
            final distanceInMeters = _distanceCalculator.as(
              LengthUnit.Meter,
              lastTrackPoint.point,
              LatLng(newTrackPoint.position.latitude,
                  newTrackPoint.position.longitude),
            );

            // --- MEJORA DE PRECISIÓN: Filtro de velocidad y distancia ---
            // 1. Solo añadir si hay un movimiento significativo para evitar ruido de GPS estático.
            // 2. Añadimos un filtro de velocidad para descartar "saltos" irreales.
            //    Una velocidad > 120 km/h (33.3 m/s) es improbable para un corredor/ciclista.
            final timeDiff = newPosition.timestamp!
                .difference(_routePoints.last.position.timestamp!)
                .inSeconds;
            if (timeDiff > 0) {
              final speedMps = distanceInMeters / timeDiff;
              if (speedMps > 33.3) {
                // > 120 km/h
                return; // Ignoramos el punto por ser un salto irreal.
              }
            }
            if (distanceInMeters > 1.5) {
              // Reducimos el umbral a 1.5m para más sensibilidad en movimientos lentos
              setState(() {
                _distance += distanceInMeters / 1000.0; // Convertir a km
                _routePoints.add(newTrackPoint);
                // Anuncio por voz de cada kilómetro completado
                if (_distance.floor() > _lastKilometerAnnounced) {
                  _lastKilometerAnnounced = _distance.floor();
                  _speak(
                      'Has completado $_lastKilometerAnnounced kilómetros. ¡Sigue así!');
                }
              });
            }
          } else {
            // Es el primer punto de la sesión
            setState(() => _routePoints.add(newTrackPoint));
          }

          // Calcular velocidad actual (opcional, pero útil)
          if (newPosition.speed > 0) {
            setState(() => _speed = newPosition.speed * 3.6); // m/s a km/h
          }

          // Calcular calorías
          // Fórmula simple: METs * peso (kg) * tiempo (horas)
          // MET para caminar/correr ~ 7
          // Se recalcula cada vez que se actualiza la distancia
          final met = 7.0;
          final hours = _elapsedTime.inSeconds / 3600;
          setState(() {
            _calories = met * _userWeight * hours;
          });
        }
      }, onError: (error) {
        if (mounted) {
          // --- SOLUCIÓN: Pausar la sesión y mostrar una alerta ---
          if (_sessionState == SessionState.running) {
            _speak('Señal de GPS perdida. Pausando entrenamiento.');
            setState(() {
              _sessionState = SessionState.paused;
              _statusMessage = 'Señal de GPS perdida. Sesión pausada.';
            });
          }

          // Actualizamos el estado para mostrar el mensaje en la pantalla de información.
          setState(() => _statusMessage =
              'Se perdió la señal de GPS. Intentando reconectar...');
        }
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _status = LocationStatus.error;
          _statusMessage = 'Error al obtener la ubicación: ${e.toString()}';
        });
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) controller.dispose();
    });

    controller.forward();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _serviceStatusStream?.cancel();
    _connectivitySubscription?.cancel(); // NUEVO: Cancelar la suscripción
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesión de GPS'),
      ),
      body: Stack(
        children: [_buildBody(), _buildControlsOverlay()],
      ),
      // --- NUEVO: Botones de control del mapa (Zoom y Centrar) ---
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Espacio para que no se solape con la tarjeta de controles
          // CORRECCIÓN: Eliminamos el SizedBox hardcodeado. El layout se gestiona con el overlay.
          SizedBox(
              height:
                  _isControlsCardExpanded ? 280 : 80), // Ajusta dinámicamente

          // --- NUEVO: Botón para cambiar el tipo de mapa ---
          FloatingActionButton(
            heroTag: 'map_type',
            onPressed: () =>
                setState(() => _isSatelliteView = !_isSatelliteView),
            backgroundColor: Colors.white,
            child: Icon(
              _isSatelliteView
                  ? Icons.map_outlined
                  : Icons.satellite_alt_outlined,
              color: Colors.black,
            ),
          ),
          // Botón de centrar / seguir
          FloatingActionButton(
            heroTag: 'center_map',
            onPressed: _toggleFollowMode,
            backgroundColor: _isFollowingUser
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            child: Icon(Icons.my_location,
                color: _isFollowingUser ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 10),
          // Botón de Zoom In
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () => _animatedMapMove(
                _mapController.camera.center, _mapController.camera.zoom + 1),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 5),
          // Botón de Zoom Out
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: () => _animatedMapMove(
                _mapController.camera.center, _mapController.camera.zoom - 1),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  /// NUEVO: Función para obtener el color basado en la velocidad.
  /// Mapea la velocidad (en km/h) a un gradiente de azul (lento) a rojo (rápido).
  Color _getColorForSpeed(double speedKmh) {
    // Define los umbrales de velocidad
    const double slowSpeed = 4.0; // Lento, ej. caminar
    const double mediumSpeed = 10.0; // Moderado, ej. trotar
    const double fastSpeed = 16.0; // Rápido, ej. correr

    if (speedKmh <= slowSpeed) {
      // Interpola entre azul y verde para velocidades lentas
      return Color.lerp(Colors.blue, Colors.green, speedKmh / slowSpeed)!;
    } else if (speedKmh <= mediumSpeed) {
      // Interpola entre verde y amarillo para velocidades medias
      return Color.lerp(Colors.green, Colors.yellow,
          (speedKmh - slowSpeed) / (mediumSpeed - slowSpeed))!;
    } else {
      // Interpola entre amarillo y rojo para velocidades rápidas
      return Color.lerp(Colors.yellow, Colors.red,
              (speedKmh - mediumSpeed) / (fastSpeed - mediumSpeed)) ??
          Colors.red;
    }
  }

  Widget _buildBody() {
    if (!_isOnline) {
      return _buildInfoScreen(
        icon: Icons.wifi_off_outlined,
        title: 'Sin conexión a internet',
        message:
            'El mapa no puede cargarse. Aún puedes registrar tu actividad, pero no verás tu ubicación en el mapa.',
        coords: _currentPosition,
      );
    }

    if (_status != LocationStatus.ready) {
      return _buildInfoScreen(
        icon: _status == LocationStatus.loading
            ? null
            : Icons.location_off_outlined,
        title: _status == LocationStatus.loading
            ? 'Cargando...'
            : 'Ubicación no disponible',
        message: _statusMessage,
        coords: _currentPosition,
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter:
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        initialZoom: 16.0,
        // Desactivamos el seguimiento al interactuar con el mapa
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && _isFollowingUser) {
            setState(() => _isFollowingUser = false);
          }
        },
      ),
      children: [
        TileLayer(
          // --- CAMBIO: La URL del mapa ahora es dinámica ---
          urlTemplate: _isSatelliteView
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}' // Vista Satélite
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Vista de Calles
          // Usamos el TileProvider cancelable para mejor rendimiento en web
          tileProvider: CancellableNetworkTileProvider(),
          userAgentPackageName: 'com.example.subefit', // Buena práctica
        ),
        // CAMBIO: Usamos PolylineLayer para dibujar segmentos con colores de gradiente.
        Builder(
          builder: (context) {
            List<Polyline> routeSegments = [];
            if (_routePoints.length > 1) {
              for (int i = 0; i < _routePoints.length - 1; i++) {
                final p1 = _routePoints[i];
                final p2 = _routePoints[i + 1];
                final avgSpeed = (p1.position.speed + p2.position.speed) /
                    2 *
                    3.6; // Velocidad promedio en km/h

                routeSegments.add(Polyline(
                  points: [
                    LatLng(p1.position.latitude, p1.position.longitude),
                    LatLng(p2.position.latitude, p2.position.longitude)
                  ],
                  strokeWidth: 6.0,
                  color: _getColorForSpeed(avgSpeed),
                ));
              }
            }
            return PolylineLayer(polylines: routeSegments);
          },
        ),
        if (_currentPosition != null)
          MarkerLayer(
            markers: [
              // Marcador de posición actual
              Marker(
                point: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                width: 80,
                height: 80,
                child: Icon(Icons.person_pin_circle,
                    color: Theme.of(context).colorScheme.primary, size: 50),
              ),
              // Marcador de inicio de ruta
              if (_routePoints.isNotEmpty)
                Marker(
                  point: LatLng(_routePoints.first.position.latitude,
                      _routePoints.first.position.longitude),
                  width: 80,
                  height: 80,
                  child: const Icon(Icons.flag_circle,
                      color: Colors.green, size: 30),
                ),
            ],
          ),
      ], // children of FlutterMap
    );
  }

  Widget _buildInfoScreen(
      {IconData? icon,
      required String title,
      required String message,
      Position? coords}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 60, color: Colors.grey.shade400)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333)),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center),
            if (coords != null) ...[
              const SizedBox(height: 20),
              Text(
                'Últimas coordenadas conocidas:\nLat: ${coords.latitude.toStringAsFixed(4)}, Lon: ${coords.longitude.toStringAsFixed(4)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // --- REDISEÑO: La tarjeta de controles ahora es más compacta y expandible ---
  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactHeader(),
            SizeTransition(
              sizeFactor: CurvedAnimation(
                  parent: _cardAnimationController, curve: Curves.easeInOut),
              child: _buildExpandedContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return InkWell(
      onTap: () {
        setState(() {
          _isControlsCardExpanded = !_isControlsCardExpanded;
          _isControlsCardExpanded
              ? _cardAnimationController.forward()
              : _cardAnimationController.reverse();
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSessionStatusIndicator(),
            Text(
              '${_elapsedTime.inMinutes.toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
            Icon(_isControlsCardExpanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_up),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(),
          if (_sessionState == SessionState.preparing)
            _buildPreparationTips()
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                      icon: Icons.speed_outlined,
                      value: _speed.toStringAsFixed(1),
                      label: 'km/h'),
                  _StatItem(
                      icon: Icons.route_outlined,
                      value: _distance.toStringAsFixed(2),
                      label: 'km'),
                  _StatItem(
                      icon: Icons.local_fire_department_outlined,
                      value: _calories.toStringAsFixed(0),
                      label: 'kcal'),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_sessionState == SessionState.running ||
                  _sessionState == SessionState.paused)
                FloatingActionButton(
                  heroTag: 'pause_resume',
                  onPressed: _togglePause,
                  backgroundColor: Colors.orange,
                  child: Icon(
                      _sessionState == SessionState.paused
                          ? Icons.play_arrow
                          : Icons.pause,
                      color: Colors.white),
                ),
              const SizedBox(width: 20),
              FloatingActionButton.large(
                heroTag: 'start_stop',
                onPressed: (_sessionState == SessionState.stopped ||
                        _sessionState == SessionState.preparing)
                    ? _startSession
                    : _stopSession,
                backgroundColor: (_sessionState == SessionState.stopped ||
                        _sessionState == SessionState.preparing)
                    ? Theme.of(context).colorScheme.primary
                    : SubefitColors.dangerRed,
                child: Icon(
                    (_sessionState == SessionState.stopped ||
                            _sessionState == SessionState.preparing)
                        ? Icons.play_arrow
                        : Icons.stop,
                    color: Colors.white,
                    size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationTips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Text('¡Listo para empezar!',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87)),
          SizedBox(height: 8),
          Text(
            '• Asegúrate de tener buena señal GPS.\n• Realiza un calentamiento de 5 minutos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStatusIndicator() {
    String text;
    Color color;
    IconData icon;

    switch (_sessionState) {
      case SessionState.running:
        text = 'Corriendo';
        color = Colors.green;
        icon = Icons.directions_run;
        break;
      case SessionState.paused:
        text = 'Pausado';
        color = Colors.orange;
        icon = Icons.pause;
        break;
      default:
        text = 'Detenido';
        color = Colors.grey;
        icon = Icons.pan_tool_alt_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold))
        ],
      ),
    );
  }

  // --- Lógica de Control de Sesión ---

  // --- NUEVO: Lógica para el botón de seguir/centrar ---
  void _toggleFollowMode() {
    if (_isFollowingUser) {
      // Si ya está siguiendo, desactivamos el modo
      setState(() => _isFollowingUser = false);
    } else {
      // Si no está siguiendo, lo activamos y centramos el mapa
      setState(() => _isFollowingUser = true);
      // CORRECCIÓN: Asegurarse de que _currentPosition no sea nulo antes de mover.
      final currentPos = _currentPosition;
      if (currentPos != null) {
        _animatedMapMove(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            16.0);
      }
    }
  }

  void _startSession() {
    if (_status != LocationStatus.ready) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Espera a que el GPS esté listo para iniciar.')));
      return;
    }
    _speak('Iniciando entrenamiento. ¡Vamos!');
    // Expande la tarjeta automáticamente al iniciar
    if (!_isControlsCardExpanded) {
      _isControlsCardExpanded = true;
      _cardAnimationController.forward();
    }
    setState(() {
      _sessionState = SessionState.running;
      _routePoints.clear();
      _distance = 0.0;
      _calories = 0.0;
      _elapsedTime = Duration.zero;
      _startTime = DateTime.now();
      _lastKilometerAnnounced = 0;
      if (_currentPosition != null) {
        // Añadimos el primer punto con velocidad 0
        _routePoints.add(TrackPoint(position: _currentPosition!));
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionState == SessionState.running) {
        setState(() => _elapsedTime = DateTime.now().difference(_startTime!));
      }
    });
  }

  void _togglePause() {
    final isPausing = _sessionState == SessionState.running;
    _speak(isPausing ? 'Entrenamiento pausado.' : 'Entrenamiento reanudado.');
    setState(() {
      // Si el usuario pausa manualmente, desactivamos el seguimiento para que no se mueva el mapa.
      _sessionState = isPausing ? SessionState.paused : SessionState.running;
      if (!isPausing) {
        // Reanudando
        // Al reanudar, ajustamos el tiempo de inicio para no contar la pausa
        final pauseDuration = DateTime.now().difference(_startTime!).inSeconds -
            _elapsedTime.inSeconds;
        _startTime = _startTime!.add(Duration(seconds: pauseDuration));
      }
    });
  }

  void _stopSession() async {
    _speak('Entrenamiento finalizado. ¡Buen trabajo!');
    _timer?.cancel();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && _routePoints.length > 1) {
      // Guardar en el historial
      final pointsEarned = (_distance * 10).round(); // 10 puntos por km
      await LocalDataService().logWorkoutInHistory(
          user.uid, _elapsedTime, pointsEarned, ['Carrera/Caminata GPS']);
      // La actualización de puntos y nivel ahora se hace desde `logWorkoutInHistory`
      // await LocalDataService().updateUserWorkoutData(user.uid, pointsEarned);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ ¡Recorrido guardado! Has ganado $pointsEarned puntos.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Recorrido no guardado (muy corto o no has iniciado sesión).'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() {
      _sessionState =
          SessionState.preparing; // Volvemos al estado de preparación
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333))),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
