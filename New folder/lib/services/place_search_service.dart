import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

/// Abstraction unifiée de recherche de lieux.
/// Utilise Google Places en priorité avec session token pour optimiser la facturation,
/// puis fallback sur Nominatim (OpenStreetMap) si aucun résultat ou erreur.
class PlaceSearchService {
  final String _apiKey;
  final _uuid = const Uuid();
  String? _sessionToken;

  /// Clé API Google (NE PAS laisser en clair en prod sans restrictions).
  /// Ajoute des restrictions sur la clé dans Google Cloud Console.
  PlaceSearchService(String apiKey) : _apiKey = apiKey;

  void startSession() {
    _sessionToken ??= _uuid.v4();
  }

  void endSession() {
    _sessionToken = null;
  }

  Future<List<PlaceAutocompleteResult>> autocomplete(
    String input, {
    double? biasLat,
    double? biasLng,
    int biasRadiusMeters = 50000,
  }) async {
    startSession();
    try {
      final uri = Uri.parse(
              'https://maps.googleapis.com/maps/api/place/autocomplete/json')
          .replace(queryParameters: {
        'input': input,
        'key': _apiKey,
        'language': 'fr',
        'sessiontoken': _sessionToken!,
        // Optional localisation bias (improves result relevance around current view)
        if (biasLat != null && biasLng != null)
          'locationbias':
              'circle:${biasRadiusMeters}@${biasLat.toStringAsFixed(6)},${biasLng.toStringAsFixed(6)}'
      });
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        // REQUEST_DENIED / OVER_QUERY_LIMIT / etc. -> make caller fallback to OSM
        return [];
      }
      final List preds = (data['predictions'] as List? ?? []);
      return preds
          .map((p) => PlaceAutocompleteResult(
                placeId: (p['place_id'] ?? '') as String,
                primaryText: (p['structured_formatting']?['main_text'] ??
                    p['description'] ??
                    '') as String,
                secondaryText: (p['structured_formatting']?['secondary_text'] ??
                    '') as String,
                fullText: (p['description'] ?? '') as String,
              ))
          .cast<PlaceAutocompleteResult>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Google Places Text Search fallback. Useful on web to avoid OSM CORS issues.
  Future<List<PlaceAutocompleteResult>> textSearch(
    String query, {
    double? biasLat,
    double? biasLng,
    int biasRadiusMeters = 50000,
  }) async {
    try {
      final qp = <String, String>{
        'query': query,
        'key': _apiKey,
        'language': 'fr',
      };
      if (biasLat != null && biasLng != null) {
        qp['location'] =
            '${biasLat.toStringAsFixed(6)},${biasLng.toStringAsFixed(6)}';
        qp['radius'] = '$biasRadiusMeters';
      }
      final uri = Uri.parse(
              'https://maps.googleapis.com/maps/api/place/textsearch/json')
          .replace(queryParameters: qp);
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();
      if (status != 'OK' && status != 'ZERO_RESULTS') return [];
      final List results = (data['results'] as List? ?? []);
      return results
          .map((r) => PlaceAutocompleteResult(
                placeId: (r['place_id'] ?? '') as String,
                primaryText: (r['name'] ?? '') as String,
                secondaryText: (r['formatted_address'] ?? '') as String,
                fullText: (r['name'] ?? '') as String,
                lat: (r['geometry']?['location']?['lat'] as num?)?.toDouble(),
                lng: (r['geometry']?['location']?['lng'] as num?)?.toDouble(),
              ))
          .cast<PlaceAutocompleteResult>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<PlaceDetailsResult?> details(String placeId) async {
    if (placeId.isEmpty) return null;
    try {
      final uri =
          Uri.parse('https://maps.googleapis.com/maps/api/place/details/json')
              .replace(queryParameters: {
        'place_id': placeId,
        'key': _apiKey,
        'language': 'fr',
        'fields': 'geometry,name,formatted_address',
        'sessiontoken': _sessionToken ?? _uuid.v4(),
      });
      final res = await http.get(uri);
      endSession();
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      final result = data['result'] as Map<String, dynamic>;
      final loc = result['geometry']?['location'] as Map<String, dynamic>?;
      return PlaceDetailsResult(
        name: (result['name'] ?? '') as String,
        formattedAddress: (result['formatted_address'] ?? '') as String,
        lat: (loc?['lat'] as num?)?.toDouble(),
        lng: (loc?['lng'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fallback simple OpenStreetMap (Nominatim) global.
  Future<List<PlaceAutocompleteResult>> fallbackNominatim(String query) async {
    try {
      // Try exact query first
      final encoded = Uri.encodeComponent(query);
      final url =
          'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=5&addressdetails=1';
      final response = await http.get(Uri.parse(url),
          headers: const {'User-Agent': 'apisavana-place-search/1.0'});
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final List data = json.decode(response.body) as List;
      if (data.isEmpty) {
        // Second chance: basic ASCII normalization (remove accents)
        final normalized = _basicNormalize(query);
        if (normalized != query) {
          final enc2 = Uri.encodeComponent(normalized);
          final url2 =
              'https://nominatim.openstreetmap.org/search?q=$enc2&format=json&limit=5&addressdetails=1';
          final resp2 = await http.get(Uri.parse(url2),
              headers: const {'User-Agent': 'apisavana-place-search/1.0'});
          if (resp2.statusCode == 200 && resp2.body.isNotEmpty) {
            final List data2 = json.decode(resp2.body) as List;
            return data2
                .map((e) => PlaceAutocompleteResult(
                      placeId: 'osm_${e['osm_id']}',
                      primaryText:
                          (e['display_name'] ?? '').toString().split(',').first,
                      secondaryText: ((e['display_name'] ?? '') as String)
                          .split(',')
                          .skip(1)
                          .join(',')
                          .trim(),
                      fullText: (e['display_name'] ?? '') as String,
                      lat: double.tryParse(e['lat'].toString()),
                      lng: double.tryParse(e['lon'].toString()),
                    ))
                .toList();
          }
        }
      }
      return data
          .map((e) => PlaceAutocompleteResult(
                placeId: 'osm_${e['osm_id']}',
                primaryText:
                    (e['display_name'] ?? '').toString().split(',').first,
                secondaryText: ((e['display_name'] ?? '') as String)
                    .split(',')
                    .skip(1)
                    .join(',')
                    .trim(),
                fullText: (e['display_name'] ?? '') as String,
                lat: double.tryParse(e['lat'].toString()),
                lng: double.tryParse(e['lon'].toString()),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Minimal ASCII normalize for fallback queries
  String _basicNormalize(String s) {
    const map = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'í': 'i',
      'ì': 'i',
      'ô': 'o',
      'ö': 'o',
      'ò': 'o',
      'ó': 'o',
      'õ': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ú': 'u',
      'ç': 'c',
      'œ': 'oe',
      'Æ': 'AE',
      'æ': 'ae',
      '’': "'"
    };
    final sb = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }
}

class PlaceAutocompleteResult {
  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;
  final double? lat; // lat/lng seulement présents sur fallback nominatim
  final double? lng;
  PlaceAutocompleteResult({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
    this.lat,
    this.lng,
  });
}

class PlaceDetailsResult {
  final String name;
  final String formattedAddress;
  final double? lat;
  final double? lng;
  PlaceDetailsResult({
    required this.name,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });
}
