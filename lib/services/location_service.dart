import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<String> getCity(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isEmpty) return '';

    final place = placemarks.first;

    return place.locality ??
        place.subAdministrativeArea ??
        place.administrativeArea ??
        '';
  }
}