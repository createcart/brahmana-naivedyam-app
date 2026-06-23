import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class Place {
  final String label;
  final double lat;
  final double lng;
  Place(this.label, this.lat, this.lng);
}

/// Geolocation + geocoding. Uses the device GPS via geolocator and the keyless
/// OpenStreetMap Nominatim API for forward search + reverse geocoding.
/// (Swap to Google Places later by replacing the two HTTP calls.)
class LocationService {
  static const _ua = {'User-Agent': 'brahmana-app/1.0 (createcart)'};

  /// Current GPS position, requesting permission as needed. null if unavailable.
  static Future<Place?> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final label = await reverse(p.latitude, p.longitude);
    return Place(label ?? 'Current location', p.latitude, p.longitude);
  }

  static Future<String?> reverse(double lat, double lng) async {
    try {
      final r = await http
          .get(Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng'),
              headers: _ua)
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body);
        return j['display_name']?.toString();
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Place>> search(String q) async {
    if (q.trim().isEmpty) return [];
    try {
      final r = await http
          .get(
              Uri.parse(
                  'https://nominatim.openstreetmap.org/search?format=json&limit=6&q=${Uri.encodeComponent(q)}'),
              headers: _ua)
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        return list
            .map((e) => Place(
                  e['display_name'].toString(),
                  double.tryParse(e['lat'].toString()) ?? 0,
                  double.tryParse(e['lon'].toString()) ?? 0,
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
