import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final LatLng latLng;
  final String address;

  LocationResult(this.latLng, this.address);
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _selectedLocation = const LatLng(-6.200000, 106.816666);
  String _currentAddress = 'Memuat alamat...';
  List<dynamic> _searchResults = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ================= CURRENT LOCATION =================
  Future<void> _initLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    _selectedLocation = LatLng(pos.latitude, pos.longitude);
    _mapController.move(_selectedLocation, 16);

    await _reverseGeocode(_selectedLocation);
    setState(() {});
  }

  // ================= REVERSE GEOCODING =================
  Future<void> _reverseGeocode(LatLng point) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'json',
        'accept-language': 'id',
      },
    );

    final res = await http.get(
      uri,
      headers: {'User-Agent': 'clipperfect-app'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _currentAddress =
            data['display_name'] ?? 'Alamat tidak ditemukan';
      });
    }
  }

  // ================= SEARCH =================
  void _searchLocation(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (q.isEmpty) {
        setState(() => _searchResults.clear());
        return;
      }

      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': q,
          'format': 'json',
          'addressdetails': '1',
          'limit': '8',
          'countrycodes': 'id',
          'accept-language': 'id',
        },
      );

      final res = await http.get(
        uri,
        headers: {'User-Agent': 'clipperfect-app'},
      );

      if (res.statusCode == 200) {
        setState(() => _searchResults = jsonDecode(res.body));
      }
    });
  }

  void _selectSearch(dynamic p) async {
    final lat = double.parse(p['lat']);
    final lon = double.parse(p['lon']);

    _selectedLocation = LatLng(lat, lon);
    _mapController.move(_selectedLocation, 16);
    _searchResults.clear();
    _searchController.clear();

    await _reverseGeocode(_selectedLocation);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Lokasi', style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15,
              onTap: (_, p) async {
                _selectedLocation = p;
                await _reverseGeocode(p);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'clipperfect.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin,
                        color: Colors.red, size: 40),
                  )
                ],
              )
            ],
          ),

          // SEARCH
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchLocation,
                    decoration: InputDecoration(
                      hintText: 'Cari alamat / lokasi...', labelStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    height: 220,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) {
                        final p = _searchResults[i];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(
                            p['display_name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearch(p),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ADDRESS PREVIEW
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentAddress,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              LocationResult(_selectedLocation, _currentAddress),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Pilih Lokasi Ini',
            style: GoogleFonts.poppins(
              color: const Color.fromARGB(255, 255, 0, 0),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
