import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

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
        title: const Text('Pick Location', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSearching || _isReverseGeocoding)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
                  Icon(Icons.location_on, size: 50, color: Colors.redAccent.withOpacity(0.9)),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          spreadRadius: 2,
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
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search city, area or country...",
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
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
                    setState(() {}); // Trigger rebuild to show/hide clear icon
                  },
                ),
              ),
            ),
          ),
          // Bottom Actions
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: () async {
                    try {
                      Position position = await Geolocator.getCurrentPosition();
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not get current location")),
                      );
                    }
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Color(0xFF00BCD4)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _addressData == null ? null : () {
                      Navigator.pop(context, {
                        'location': _pickedLocation,
                        'address': _addressData,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
