import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/place_search_service.dart';
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
  bool _pendingAnimate =
      false; // Indique que nous devons animer la caméra quand le contrôleur sera prêt
  static const LatLng defaultCameraTarget = LatLng(12.252356, -2.325412);

  // Anciennes bornes spécifiques Burkina supprimées (recherche désormais mondiale)
  // On conserve la possibilité future d'ajouter un mode restreint via un flag.

  // Nouvelles fonctionnalités
  double _zoneRadius = 100.0; // Rayon initial en mètres
  bool _showZone = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  late final PlaceSearchService _placeSearchService;
  static const String _googleApiKey =
      'AIzaSyBEkGG3-e3pGzTmtYkhs94sJBSZRH2Tn60'; // RESTRICTION NECESSAIRE

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _placeSearchService = PlaceSearchService(_googleApiKey);
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Position par défaut: Burkina (Koudougou approximatif) si aucune info disponible, pour éviter (0,0)
    const LatLng bfFallback = LatLng(12.252356, -2.325412);
    final LatLng defaultPosition = LatLng(
      widget.initialLat ?? bfFallback.latitude,
      widget.initialLng ?? bfFallback.longitude,
    );
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _marker = defaultPosition;
      } else {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever ||
            perm == LocationPermission.denied) {
          _marker = defaultPosition;
        } else {
          // 1. Position rapide: dernière position connue
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            _marker = LatLng(widget.initialLat ?? last.latitude,
                widget.initialLng ?? last.longitude);
            _accuracy = last.accuracy;
            _altitude = last.altitude;
          } else {
            _marker = defaultPosition;
          }
          // Animation différée si contrôleur pas prêt
          _pendingAnimate = true;
          // 2. Raffinement haute précision
          _refreshHighAccuracyPosition(animate: true);
        }
      }
    } catch (e) {
      _marker = defaultPosition;
      error = null; // on garde silencieux
    }
    if (mounted) setState(() => loading = false);
    // Sécurité: si jamais (0,0), rebasculer sur fallback
    if (_marker != null &&
        _marker!.latitude.abs() < 0.0001 &&
        _marker!.longitude.abs() < 0.0001) {
      setState(() => _marker = bfFallback);
    }
  }

  // (normalize helper removed; no longer used)

  void _onMapTap(LatLng latLng) {
    // Sélection libre mondiale désormais
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
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    // 1) Google Autocomplete (léger)
    List<PlaceAutocompleteResult> places =
        await _placeSearchService.autocomplete(trimmed,
            biasLat: _marker?.latitude, biasLng: _marker?.longitude);
    // 2) Si vide -> Google Text Search (renvoie aussi des lat/lng)
    if (places.isEmpty) {
      places = await _placeSearchService.textSearch(trimmed,
          biasLat: _marker?.latitude, biasLng: _marker?.longitude);
    }
    // 3) Si encore vide -> Nominatim fallback (global)
    if (places.isEmpty) {
      places = await _placeSearchService.fallbackNominatim(trimmed);
    }
    if (!mounted) return;
    setState(() {
      _searchResults = places
          .map((p) => {
                'id': p.placeId,
                'primary': p.primaryText,
                'secondary': p.secondaryText,
                'full': p.fullText,
                'lat': p.lat, // présent si fallback nominatim
                'lon': p.lng,
              })
          .toList();
      _isSearching = false;
    });
    if (places.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucun résultat.'),
        duration: Duration(seconds: 3),
      ));
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    // Si déjà lat/lon (fallback OSM) on utilise direct.
    if (result['lat'] != null && result['lon'] != null) {
      final latLng = LatLng(result['lat'], result['lon']);
      setState(() {
        _marker = latLng;
        _searchResults = [];
        _searchController.clear();
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      return;
    }
    // Sinon aller chercher les détails Google Places
    final placeId = result['id'] as String?;
    if (placeId == null || placeId.isEmpty) return;
    _placeSearchService.details(placeId).then((details) {
      if (details == null || details.lat == null || details.lng == null) return;
      if (!mounted) return;
      final target = LatLng(details.lat!, details.lng!);
      setState(() {
        _marker = target;
        _searchResults = [];
        _searchController.clear();
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    });
  }

  Future<void> _refreshHighAccuracyPosition({bool animate = false}) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final newLatLng = LatLng(widget.initialLat ?? pos.latitude,
          widget.initialLng ?? pos.longitude);
      if (!mounted) return;
      setState(() {
        _marker = newLatLng;
        _accuracy = pos.accuracy;
        _altitude = pos.altitude;
      });
      if (animate) {
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(newLatLng));
        } else {
          _pendingAnimate = true; // animera quand contrôleur prêt
        }
      }
    } catch (e) {
      // silencieux
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
                              _searchDebounce?.cancel();
                              if (value.trim().length < 3) {
                                setState(() {
                                  _searchResults = [];
                                  _isSearching = false;
                                });
                                return;
                              }
                              _searchDebounce = Timer(
                                const Duration(milliseconds: 450),
                                () => _searchLocation(value),
                              );
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
                                  final r = _searchResults[index];
                                  return ListTile(
                                    leading:
                                        const Icon(Icons.location_on, size: 20),
                                    title: Text(
                                      r['primary'] ?? r['full'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: (r['secondary'] != null &&
                                            (r['secondary'] as String)
                                                .isNotEmpty)
                                        ? Text(
                                            r['secondary'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          )
                                        : null,
                                    onTap: () => _selectSearchResult(r),
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
                          target: (_marker == null ||
                                  (_marker!.latitude.abs() < 0.0001 &&
                                      _marker!.longitude.abs() < 0.0001))
                              ? defaultCameraTarget
                              : _marker!,
                          zoom: 16,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onMapCreated: (c) {
                          _mapController = c;
                          // Si nous avons une marque et animation en attente -> effectuer
                          if (_marker != null && _pendingAnimate) {
                            _pendingAnimate = false;
                            c.animateCamera(CameraUpdate.newLatLng(_marker!));
                          } else if (_marker != null) {
                            // Always ensure camera matches marker at creation
                            c.moveCamera(CameraUpdate.newLatLng(_marker!));
                          } else {
                            // Essayer de récupérer la localisation et centrer automatiquement
                            _refreshHighAccuracyPosition(animate: true);
                          }
                        },
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
