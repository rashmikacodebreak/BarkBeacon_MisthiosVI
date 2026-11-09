import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class PetMapPage extends StatefulWidget {
  const PetMapPage({super.key});

  @override
  State<PetMapPage> createState() => _PetMapPageState();
}

class _PetMapPageState extends State<PetMapPage> {
  final _controller = MapController();
  LatLng? _currentLocation;
  LatLng? _lostPet;
  bool _loading = false;
  bool _mapReady = false;
  String _message = 'Tap the map to place a Lost Pet pin.';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _loading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(
            () =>
                _message = 'Turn on Location in device settings and try again.',
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(
          () => _message = permission == LocationPermission.deniedForever
              ? 'Allow location in the app settings to use My location.'
              : 'Location access was denied. You can still place a pin manually.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = point;
        _message = 'Blue dot shows your location. Tap the map to place a Lost Pet pin.';
      });
      _controller.move(point, 16);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Could not get your location. Try again or place a pin manually.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(_message),
        ),
        Expanded(
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: const LatLng(6.9271, 79.8612),
              initialZoom: 12,
              onMapReady: () => setState(() => _mapReady = true),
              onTap: (_, point) => setState(() {
                _lostPet = point;
                _message = 'Lost Pet pin placed. Tap another spot to move it.';
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bark_beacon',
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  if (_lostPet != null)
                    Marker(
                      point: _lostPet!,
                      alignment: Alignment.topCenter,
                      width: 90,
                      height: 52,
                      child: const Column(
                        children: [
                          Text(
                            'Lost Pet',
                            style: TextStyle(
                              color: Colors.black,
                              backgroundColor: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.location_pin, color: Colors.red, size: 32),
                        ],
                      ),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.https('www.openstreetmap.org', '/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FilledButton.icon(
            onPressed: !_mapReady || _loading ? null : _locate,
            icon: const Icon(Icons.my_location),
            label: Text(_loading ? 'Finding location…' : 'My location'),
          ),
        ),
      ],
    );
  }
}
