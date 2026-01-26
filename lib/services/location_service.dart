import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

class LocationService {
  // Check and request permissions
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    return status.isGranted;
  }

  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      // On Web, permission_handler might not work as expected.
      // Geolocator.checkPermission() is more reliable across platforms.
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled.
        return null;
      }

      Position position = await Geolocator.getCurrentPosition();

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Send location to backend
  static Future<bool> updateLocationToServer(Position position) async {
    try {
      final response = await ApiService.makeRequest(
        '${ApiService.baseUrl}/location/update',
        method: 'POST',
        body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  // Reverse Geocoding: Get Address from Coordinates
  static Future<Map<String, String>?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      // Using OpenStreetMap's Nominatim API (Free, no key required)
      // Increased zoom for better address/postal code accuracy
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1');
      
      final response = await ApiService.makeRequest(url.toString(), method: 'GET');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        return {
          'city': (address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? '').toString(),
          'district': (address['state_district'] ?? address['district'] ?? address['county'] ?? '').toString(),
          'county': (address['county'] ?? '').toString(),
          'state': (address['state'] ?? '').toString(),
          'country': (address['country'] ?? '').toString(),
          'postal_code': (address['postcode'] ?? address['postal_code'] ?? '').toString(),
        };
      }
      return null;
    } catch (e) {
      print('Error in reverse geocoding: $e');
      return null;
    }
  }

  // Forward Geocoding: Search Address by Query (City/Place)
  static Future<Map<String, dynamic>?> searchAddressByCity(String query) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=1&addressdetails=1');
      
      final response = await ApiService.makeRequest(url.toString(), method: 'GET');

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final data = results[0];
          final address = data['address'];
          
          return {
            'lat': double.tryParse(data['lat']?.toString() ?? '0'),
            'lon': double.tryParse(data['lon']?.toString() ?? '0'),
            'city': (address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? query).toString(),
            'district': (address['state_district'] ?? address['district'] ?? address['county'] ?? '').toString(),
            'county': (address['county'] ?? '').toString(),
            'state': (address['state'] ?? '').toString(),
            'country': (address['country'] ?? '').toString(),
            'postal_code': (address['postcode'] ?? address['postal_code'] ?? '').toString(),
          };
        }
      }
      return null;
    } catch (e) {
      print('Error in address search: $e');
      return null;
    }
  }

  // Get nearby users
  static Future<dynamic> getNearbyUsers({double radius = 50}) async {
    try {
      final response = await ApiService.makeRequest(
        '${ApiService.baseUrl}/location/nearby?radius=$radius',
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting nearby users: $e');
      return null;
    }
  }
}
