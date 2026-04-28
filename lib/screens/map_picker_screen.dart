import '../../../../../../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../utils/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({Key? key, this.initialLat, this.initialLng}) : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool _isReverseGeocoding = false;
  bool _isSearching = false;
  String _currentAddress = "Loading address...";
  Map<String, String>? _addressData;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pickedLocation = LatLng(
      widget.initialLat ?? 10.8505, // Kerala Default
      widget.initialLng ?? 76.2711,
    );
    _getInitialAddress();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getInitialAddress() async {
    await _updateAddress(_pickedLocation!);
  }

  Future<void> _updateAddress(LatLng position) async {
    setState(() {
      _isReverseGeocoding = true;
      _pickedLocation = position;
    });

    try {
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (address != null && mounted) {
        setState(() {
          _addressData = address;
          _currentAddress = "${address['city'] ?? ''}, ${address['state'] ?? ''}, ${address['country'] ?? ''}";
          if (_currentAddress.startsWith(", ")) _currentAddress = _currentAddress.substring(2);
          
          // Only update controller if user is NOT typing
          if (!_isSearching) {
            _searchController.text = _currentAddress;
          }
        });
      }
    } catch (e) {
      print("Error in reverse geocoding: $e");
    } finally {
      if (mounted) {
        setState(() => _isReverseGeocoding = false);
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    
    try {
      final result = await LocationService.searchAddressByCity(query);
      if (result != null && mounted) {
        final newLatLng = LatLng(result['lat'], result['lon']);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 15));
        
        setState(() {
          _pickedLocation = newLatLng;
          _addressData = {
            'city': result['city'] ?? '',
            'state': result['state'] ?? '',
            'country': result['country'] ?? '',
            'district': result['district'] ?? '',
            'county': result['county'] ?? '',
            'postal_code': result['postal_code'] ?? '',
          };
          _currentAddress = "${result['city'] ?? ''}, ${result['state'] ?? ''}, ${result['country'] ?? ''}";
          if (_currentAddress.startsWith(", ")) _currentAddress = _currentAddress.substring(2);
          _searchController.text = _currentAddress;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location not found")),
        );
      }
    } catch (e) {
      print("Error searching location: $e");
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.deepEmerald, AppColors.deepEmerald],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: AppColors.cardDark,
        elevation: 4,
        actions: [
          if (_isSearching || _isReverseGeocoding)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: AppColors.cardDark, strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation!,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              setState(() {
                _pickedLocation = position.target;
              });
            },
            onCameraIdle: () {
              if (!_isSearching) {
                _updateAddress(_pickedLocation!);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
          // Static Marker in the center
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Custom Marker Design
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.location_on, size: 52, color: Colors.redAccent.withOpacity(0.9)),
                      const Positioned(
                        top: 10,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: AppColors.midnightEmerald,
                          child: CircleAvatar(radius: 5, backgroundColor: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 12,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.all(Radius.elliptical(20, 10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white70.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Top Search Bar
          Positioned(
            top: 20,
            left: 15,
            right: 15,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white70.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Search city, area or country...",
                  hintStyle: TextStyle(color: AppColors.midnightEmerald, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  prefixIcon: const Icon(Icons.search, color: AppColors.deepEmerald),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.cancel, size: 20, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ) 
                    : null,
                ),
                onSubmitted: _performSearch,
                textInputAction: TextInputAction.search,
                onChanged: (val) {
                  setState(() {}); 
                },
              ),
            ),
          ),
          // My Location Button
          Positioned(
            bottom: 120,
            right: 15,
            child: FloatingActionButton(
              mini: true,
              onPressed: () async {
                try {
                  Position position = await Geolocator.getCurrentPosition();
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 16),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not get current location")),
                  );
                }
              },
              backgroundColor: AppColors.midnightEmerald,
              elevation: 4,
              child: const Icon(Icons.my_location, color: AppColors.deepEmerald),
            ),
          ),
          // Bottom Actions
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: _addressData == null 
                  ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
                  : const LinearGradient(
                      colors: [AppColors.deepEmerald, AppColors.deepEmerald],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  if (_addressData != null)
                    BoxShadow(
                      color: AppColors.deepEmerald.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _addressData == null ? null : () {
                  Navigator.pop(context, {
                    'location': _pickedLocation,
                    'address': _addressData,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.cardDark, letterSpacing: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}















