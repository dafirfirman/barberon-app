import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class MapsPage extends StatefulWidget {
  final latlong.LatLng initialPosition;

  const MapsPage({required this.initialPosition});

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late MapController _mapController;
  latlong.LatLng? _pickedLocation;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final List<Marker> _markers = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialPosition;
    _isLoading = false;
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeModeString = prefs.getString('themeMode');
    if (themeModeString != null) {
      setState(() {});
    }
  }

  void _onMapEvent(TapPosition tapPosition, latlong.LatLng point) {
    setState(() {
      _pickedLocation = point;
      _updateMarker(point);
    });
  }

  void _onPickLocation() {
    if (_pickedLocation != null) {
      Navigator.pop(context, _pickedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih lokasi terlebih dahulu!')),
      );
    }
  }


  void _updateMarker(latlong.LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          point: position,
          width: 40.0,
          height: 40.0,
          child: Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    });
  }

  Future<void> _searchLocation(String query) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        List<Location> locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          Location firstLocation = locations.first;
          latlong.LatLng newLocation = latlong.LatLng(
            firstLocation.latitude,
            firstLocation.longitude,
          );
          _mapController.move(newLocation, 15.0);
          setState(() {
            _pickedLocation = newLocation;
            _updateMarker(newLocation);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lokasi tidak ditemukan!')),
          );
        }
      } catch (e) {
        print('Error searching location: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat mencari lokasi!')),
        );
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.grey[900],
        title: Text(
          'Lokasi',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: _onPickLocation,
            child: Text(
              'Simpan',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: widget.initialPosition,
                    initialZoom: 15.0,
                    onTap: _onMapEvent,
                    minZoom: 2.0,
                    maxZoom: 18.0,
                  ),
                  mapController: _mapController,
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: _markers,
                    ),
                  ],
                ),
                Center(
                  child: Image.asset(
                    'assets/icons/man_copy.png',
                    width: 40,
                    height: 40,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 15,
                  right: 15,
                  height: 50,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari lokasi...',
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onChanged: _searchLocation,
                  ),
                ),
              ],
            ),
    );
  }
}