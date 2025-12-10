import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GPSScreen extends StatefulWidget {
  const GPSScreen({Key? key}) : super(key: key);

  @override
  State<GPSScreen> createState() => _GPSScreenState();
}

class _GPSScreenState extends State<GPSScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? _error;
  bool _isOnline = true;
  String _numericLocation = '';

  // Posición inicial por defecto (ej. centro de una ciudad)
  static const CameraPosition _kDefaultInitialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((_) {
      _checkConnectivity();
    });
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = !(connectivityResult.contains(ConnectivityResult.none));
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          setState(() => _error =
              'El servicio de GPS está deshabilitado. Por favor, actívalo.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _error = "Activa el GPS para continuar");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted)
          setState(() => _error = "Permisos de GPS denegados permanentemente.");
        return;
      }

      // Obtenemos la posición una vez para centrar el mapa rápidamente
      final position = await Geolocator.getCurrentPosition();
      _goToCurrentLocation(position);

      // Nos suscribimos a los cambios para mantener el marcador actualizado
      _positionStreamSubscription =
          Geolocator.getPositionStream().listen((newPosition) {
        if (mounted) {
          setState(() {
            _currentPosition = newPosition;
            _numericLocation =
                'Lat: ${newPosition.latitude.toStringAsFixed(4)}, Lon: ${newPosition.longitude.toStringAsFixed(4)}';
          });
        }
      });
    } catch (e) {
      if (mounted)
        setState(
            () => _error = 'No se pudo obtener la ubicación: ${e.toString()}');
    }
  }

  Future<void> _goToCurrentLocation(Position? position) async {
    if (position == null) return;

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 16.0),
    ));
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _numericLocation =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      });
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {};
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Tu Ubicación'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa GPS'),
      ),
      body: Stack(
        children: [
          // Widget del Mapa
          if (_isOnline)
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _currentPosition != null
                  ? CameraPosition(
                      target: LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                      zoom: 16.0)
                  : _kDefaultInitialPosition,
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) _controller.complete(controller);
              },
              markers: markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          // Indicador de carga inicial
          if (_currentPosition == null && _error == null)
            const Center(child: CircularProgressIndicator()),
          // Mensaje de error
          if (_error != null)
            Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 16)))),
          // Mensaje de sin conexión
          if (!_isOnline)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 20),
                      const Text(
                        'No se puede cargar el mapa sin conexión a internet.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 18, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 12),
                      if (_numericLocation.isNotEmpty)
                        Text('Tus coordenadas son:\n$_numericLocation',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToCurrentLocation(_currentPosition),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.my_location, color: Colors.black),
      ),
    );
  }
}
