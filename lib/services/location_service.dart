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
      final url = '${ApiService.baseUrl}/location/geocode?lat=$lat&lon=$lon';
      
      final response = await ApiService.makeRequest(url, method: 'GET');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final components = data['results'][0]['address_components'] as List;
          
          String city = '';
          String district = '';
          String county = '';
          String state = '';
          String country = '';
          String postalCode = '';

          for (var component in components) {
            final types = component['types'] as List;
            if (types.contains('locality') || types.contains('sublocality')) {
               if (city.isEmpty) city = component['long_name'];
            }
            if (types.contains('administrative_area_level_2')) {
               district = component['long_name'];
            }
            if (types.contains('administrative_area_level_3')) {
               county = component['long_name'];
               // Fallback for district if level_2 is missing
               if (district.isEmpty) district = component['long_name'];
            }
            if (types.contains('administrative_area_level_1')) {
               state = component['long_name'];
            }
            if (types.contains('country')) {
               country = component['long_name'];
            }
            if (types.contains('postal_code')) {
               postalCode = component['long_name'];
            }
          }

          return {
            'city': city,
            'district': district,
            'county': county,
            'state': state,
            'country': country,
            'postal_code': postalCode,
          };
        }
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
      final url = '${ApiService.baseUrl}/location/search?query=${Uri.encodeComponent(query)}';
      
      final response = await ApiService.makeRequest(url, method: 'GET');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final geometry = result['geometry']['location'];
          final components = result['address_components'] as List;
          
          String city = query;
          String district = '';
          String county = '';
          String state = '';
          String country = '';
          String postalCode = '';

          for (var component in components) {
            final types = component['types'] as List;
            if (types.contains('locality') || types.contains('sublocality')) {
               city = component['long_name'];
            }
            if (types.contains('administrative_area_level_2')) {
               district = component['long_name'];
            }
            if (types.contains('administrative_area_level_3')) {
               county = component['long_name'];
               if (district.isEmpty) district = component['long_name'];
            }
            if (types.contains('administrative_area_level_1')) {
               state = component['long_name'];
            }
            if (types.contains('country')) {
               country = component['long_name'];
            }
            if (types.contains('postal_code')) {
               postalCode = component['long_name'];
            }
          }

          return {
            'lat': geometry['lat'],
            'lon': geometry['lng'], // Google Maps returns 'lng', not 'lon'
            'city': city,
            'district': district,
            'county': county,
            'state': state,
            'country': country,
            'postal_code': postalCode,
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



