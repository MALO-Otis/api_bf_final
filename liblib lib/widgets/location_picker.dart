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

  // Villes principales du Burkina Faso avec coordonnées
  final List<Map<String, dynamic>> _villesBurkinaFaso = [
    {'name': 'Ouagadougou', 'lat': 12.3714, 'lon': -1.5197, 'type': 'Capitale'},
    {'name': 'Bobo-Dioulasso', 'lat': 11.1781, 'lon': -4.2979, 'type': 'Ville'},
    {'name': 'Koudougou', 'lat': 12.2530, 'lon': -2.3622, 'type': 'Ville'},
    {'name': 'Ouahigouya', 'lat': 13.5829, 'lon': -2.4214, 'type': 'Ville'},
    {'name': 'Banfora', 'lat': 10.6340, 'lon': -4.7613, 'type': 'Ville'},
    {'name': 'Kaya', 'lat': 13.0928, 'lon': -1.0844, 'type': 'Ville'},
    {'name': 'Tenkodogo', 'lat': 11.7806, 'lon': -0.3694, 'type': 'Ville'},
    {'name': 'Dédougou', 'lat': 12.4636, 'lon': -3.4836, 'type': 'Ville'},
    {'name': 'Fada N\'Gourma', 'lat': 12.0614, 'lon': 0.3581, 'type': 'Ville'},
    {'name': 'Dori', 'lat': 14.0354, 'lon': -0.0347, 'type': 'Ville'},
    {'name': 'Gaoua', 'lat': 10.3336, 'lon': -3.1817, 'type': 'Ville'},
    {'name': 'Ziniaré', 'lat': 12.5833, 'lon': -1.2972, 'type': 'Ville'},
    {'name': 'Réo', 'lat': 12.3197, 'lon': -2.4711, 'type': 'Ville'},
    {'name': 'Manga', 'lat': 11.6644, 'lon': -1.0736, 'type': 'Ville'},
    {'name': 'Diapaga', 'lat': 12.0708, 'lon': 1.7881, 'type': 'Ville'},
  ];

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
      // Position par défaut : Ouagadougou, Burkina Faso
      LatLng defaultPosition = LatLng(
        widget.initialLat ?? 12.3714, // Ouagadougou, Burkina Faso
        widget.initialLng ?? -1.5197,
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
            // Utiliser la position actuelle si dans le Burkina Faso, sinon position par défaut
            if (_isInBurkinaFaso(pos.latitude, pos.longitude)) {
              _marker = LatLng(widget.initialLat ?? pos.latitude,
                  widget.initialLng ?? pos.longitude);
              _accuracy = pos.accuracy;
              _altitude = pos.altitude;
            } else {
              // Si l'utilisateur n'est pas au Burkina Faso, utiliser Ouagadougou
              _marker = defaultPosition;
              Get.snackbar(
                '📍 Position détectée',
                'Vous n\'êtes pas au Burkina Faso. Carte centrée sur Ouagadougou.',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            }
          } catch (e) {
            // Si geolocation échoue, utiliser position par défaut
            _marker = defaultPosition;
          }
        }
      }
    } catch (e) {
      // En cas d'erreur totale, position par défaut : Ouagadougou
      _marker = LatLng(
        widget.initialLat ?? 12.3714,
        widget.initialLng ?? -1.5197,
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

  /// Vérifier si les coordonnées sont dans le Burkina Faso
  bool _isInBurkinaFaso(double latitude, double longitude) {
    // Boîte englobante approximative du Burkina Faso
    // Nord: 15.1°N, Sud: 9.4°N, Est: 2.4°E, Ouest: 5.5°W
    return latitude >= 9.4 &&
        latitude <= 15.1 &&
        longitude >= -5.5 &&
        longitude <= 2.4;
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
      List<Map<String, dynamic>> results = [];

      // 1. Recherche locale dans les villes burkinabé
      final localResults = _villesBurkinaFaso
          .where((ville) =>
              ville['name'].toLowerCase().contains(query.toLowerCase()))
          .map((ville) => {
                'display_name':
                    '${ville['name']}, ${ville['type']}, Burkina Faso',
                'lat': ville['lat'],
                'lon': ville['lon'],
                'type': ville['type'],
                'importance': 1.0, // Priorité élevée pour les villes locales
                'source': 'local',
              })
          .toList();

      results.addAll(localResults);

      // 2. Recherche en ligne avec Nominatim (si pas assez de résultats locaux)
      if (results.length < 5) {
        final encodedQuery = Uri.encodeComponent(query);

        // Ajouter "Burkina Faso" à la recherche si pas déjà présent
        final searchQuery = query.toLowerCase().contains('burkina') ||
                query.toLowerCase().contains('faso')
            ? query
            : '$query, Burkina Faso';
        final finalEncodedQuery = Uri.encodeComponent(searchQuery);

        // Limiter la recherche au Burkina Faso avec viewbox
        final url = 'https://nominatim.openstreetmap.org/search'
            '?q=$finalEncodedQuery'
            '&format=json'
            '&limit=8'
            '&addressdetails=1'
            '&countrycodes=BF' // Code pays Burkina Faso
            '&viewbox=-5.5,15.1,2.4,9.4' // Boîte englobante du Burkina Faso
            '&bounded=1'; // Limiter strictement à la boîte

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final onlineResults = data
              .map((item) => {
                    'display_name': item['display_name'],
                    'lat': double.parse(item['lat']),
                    'lon': double.parse(item['lon']),
                    'type': item['type'] ?? 'lieu',
                    'importance': (item['importance'] ?? 0.0) *
                        0.8, // Priorité légèrement inférieure
                    'source': 'online',
                  })
              .toList();

          results.addAll(onlineResults);
        }
      }

      setState(() {
        // Supprimer les doublons et trier par importance
        final uniqueResults = <String, Map<String, dynamic>>{};
        for (final result in results) {
          final key = '${result['lat']}_${result['lon']}';
          if (!uniqueResults.containsKey(key)) {
            uniqueResults[key] = result;
          }
        }

        _searchResults = uniqueResults.values.toList();
        _searchResults.sort((a, b) =>
            (b['importance'] as double).compareTo(a['importance'] as double));
        _isSearching = false;
      });
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

  /// Aller à la position actuelle
  Future<void> _goToCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          '📍 Service de localisation',
          'Veuillez activer la géolocalisation',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        Get.snackbar(
          '📍 Permission refusée',
          'Veuillez autoriser l\'accès à la localisation',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Afficher un indicateur de chargement
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Localisation en cours...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fermer le dialog de chargement
      Get.back();

      if (_isInBurkinaFaso(position.latitude, position.longitude)) {
        final currentLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _marker = currentLocation;
          _accuracy = position.accuracy;
          _altitude = position.altitude;
        });

        _mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(currentLocation, 16));

        Get.snackbar(
          '📍 Position trouvée',
          'Vous êtes au Burkina Faso !',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          '🌍 Position détectée',
          'Vous n\'êtes pas au Burkina Faso. Utilisez la recherche pour trouver un lieu.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      // Fermer le dialog si ouvert
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        '❌ Erreur',
        'Impossible d\'obtenir votre position',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
        title: const Text('🇧🇫 Localisation Burkina Faso'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _goToCurrentLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Ma position actuelle',
          ),
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
                              hintText: 'Rechercher au Burkina Faso...',
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
                                  final isLocal = result['source'] == 'local';
                                  final type = result['type'] ?? 'lieu';

                                  IconData icon;
                                  Color iconColor;

                                  if (type == 'Capitale') {
                                    icon = Icons.location_city;
                                    iconColor = Colors.red;
                                  } else if (type == 'Ville') {
                                    icon = Icons.location_city;
                                    iconColor = Colors.blue;
                                  } else {
                                    icon = Icons.location_on;
                                    iconColor = Colors.grey;
                                  }

                                  return ListTile(
                                    title: Text(
                                      result['display_name'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isLocal
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    leading:
                                        Icon(icon, size: 20, color: iconColor),
                                    trailing: isLocal
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '🇧🇫',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          )
                                        : null,
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
