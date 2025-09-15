import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? zoneRadius; // Rayon de la zone en mètres
  final String? searchAddress; // Adresse trouvée par recherche
  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.zoneRadius,
    this.searchAddress,
  });
}

/// Écran plein pour sélectionner une localisation sur Google Map
class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _marker;
  double? _accuracy;
  double? _altitude;
  bool loading = true;
  String? error;

  // Nouvelles fonctionnalités
  double _zoneRadius = 100.0; // Rayon initial en mètres
  bool _showZone = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      // Position par défaut (si pas d'initial ou si geolocation échoue)
      LatLng defaultPosition = LatLng(
        widget.initialLat ?? 5.3364, // Abidjan par défaut
        widget.initialLng ?? -4.0267,
      );

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _marker = defaultPosition;
        error = null; // Pas d'erreur, on utilise la position par défaut
      } else {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever ||
            perm == LocationPermission.denied) {
          _marker = defaultPosition;
          error = null; // Pas d'erreur bloquante
        } else {
          try {
            Position pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high);
            _marker = LatLng(widget.initialLat ?? pos.latitude,
                widget.initialLng ?? pos.longitude);
            _accuracy = pos.accuracy;
            _altitude = pos.altitude;
          } catch (e) {
            // Si geolocation échoue, utiliser position par défaut
            _marker = defaultPosition;
          }
        }
      }
    } catch (e) {
      // En cas d'erreur totale, position par défaut
      _marker = LatLng(
        widget.initialLat ?? 5.3364,
        widget.initialLng ?? -4.0267,
      );
      error = null;
    }
    if (mounted) setState(() => loading = false);
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _marker = latLng;
      _updateCoordinatesRealTime(latLng);
    });
  }

  void _updateCoordinatesRealTime(LatLng position) {
    // Mise à jour temps réel des coordonnées (optionnel: récupérer altitude/précision)
    // Pour l'instant on met à jour juste la position visible
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Utilisation de Nominatim (OpenStreetMap) pour éviter les frais Google Places API
      final encodedQuery = Uri.encodeComponent(query);
      final url =
          'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&addressdetails=1';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data
              .map((item) => {
                    'display_name': item['display_name'],
                    'lat': double.parse(item['lat']),
                    'lon': double.parse(item['lon']),
                  })
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      Get.snackbar('Erreur', 'Impossible de rechercher cette localisation');
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final latLng = LatLng(result['lat'], result['lon']);
    setState(() {
      _marker = latLng;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  void _confirm() {
    if (_marker == null) {
      Get.snackbar('Localisation', 'Aucune position sélectionnée');
      return;
    }
    Navigator.of(context).pop(LocationResult(
      latitude: _marker!.latitude,
      longitude: _marker!.longitude,
      altitude: _altitude,
      accuracy: _accuracy,
      zoneRadius: _showZone ? _zoneRadius : null,
      searchAddress: null, // Peut être étendu plus tard
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélection localisation'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showZone = !_showZone),
            icon: Icon(_showZone
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked),
            tooltip: 'Zone de couverture',
          ),
          IconButton(onPressed: _confirm, icon: const Icon(Icons.check)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    // Barre de recherche
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Rechercher une localisation...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _isSearching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchResults = []);
                                          },
                                        )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.length > 2) {
                                _searchLocation(value);
                              } else {
                                setState(() => _searchResults = []);
                              }
                            },
                          ),
                          if (_searchResults.isNotEmpty)
                            Container(
                              height: 150,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final result = _searchResults[index];
                                  return ListTile(
                                    title: Text(
                                      result['display_name'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    leading:
                                        const Icon(Icons.location_on, size: 20),
                                    onTap: () => _selectSearchResult(result),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Contrôles de zone
                    if (_showZone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: Colors.blue.shade50,
                        child: Row(
                          children: [
                            const Text('Rayon: '),
                            Expanded(
                              child: Slider(
                                value: _zoneRadius,
                                min: 50,
                                max: 2000,
                                divisions: 39,
                                label: '${_zoneRadius.round()} m',
                                onChanged: (value) =>
                                    setState(() => _zoneRadius = value),
                              ),
                            ),
                            Text('${_zoneRadius.round()} m'),
                          ],
                        ),
                      ),
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _marker ?? const LatLng(0, 0),
                          zoom: 16,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onMapCreated: (c) => _mapController = c,
                        onTap: _onMapTap,
                        markers: _marker != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('sel'),
                                  position: _marker!,
                                  draggable: true,
                                  onDragEnd: (p) {
                                    setState(() => _marker = p);
                                    _updateCoordinatesRealTime(p);
                                  },
                                )
                              }
                            : {},
                        circles: _showZone && _marker != null
                            ? {
                                Circle(
                                  circleId: const CircleId('zone'),
                                  center: _marker!,
                                  radius: _zoneRadius,
                                  strokeColor: Colors.blue,
                                  strokeWidth: 2,
                                  fillColor: Colors.blue.withOpacity(0.2),
                                )
                              }
                            : {},
                      ),
                    ),
                    if (_marker != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Latitude: ${_marker!.latitude.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                            fontFamily: 'monospace'),
                                      ),
                                      Text(
                                        'Longitude: ${_marker!.longitude.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                            fontFamily: 'monospace'),
                                      ),
                                      if (_altitude != null)
                                        Text(
                                          'Altitude: ${_altitude!.toStringAsFixed(1)} m',
                                          style: const TextStyle(
                                              fontFamily: 'monospace'),
                                        ),
                                      if (_accuracy != null)
                                        Text(
                                          'Précision: ±${_accuracy!.toStringAsFixed(1)} m',
                                          style: const TextStyle(
                                              fontFamily: 'monospace'),
                                        ),
                                      if (_showZone)
                                        Text(
                                          'Zone: ${_zoneRadius.round()} m de rayon',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Indicateur temps réel
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _confirm,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Confirmer'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    if (_marker != null) {
                                      _mapController?.animateCamera(
                                          CameraUpdate.newLatLng(_marker!));
                                    }
                                  },
                                  icon: const Icon(Icons.center_focus_strong),
                                  label: const Text('Centrer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
