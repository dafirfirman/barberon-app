import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapsPage extends StatefulWidget {
  final LatLng initialPosition;

  const MapsPage({required this.initialPosition});

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController _controller;
  LatLng? _pickedLocation;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialPosition;
    _isLoading = false;
  }

  void _onCameraMove(CameraPosition position) {
    _pickedLocation = position.target;
  }

  void _onPickLocation() {
    Navigator.pop(context, _pickedLocation);
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
  }

  Future<void> _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location firstLocation = locations.first;
        _controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(firstLocation.latitude, firstLocation.longitude),
            zoom: 15,
          ),
        ));
        setState(() {
          _pickedLocation = LatLng(firstLocation.latitude, firstLocation.longitude);
        });
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 26, 192, 101),
        title: Text('Pilih Lokasi'),
        actions: [
          TextButton(
            onPressed: _onPickLocation,
            child: Text(
              'SIMPAN',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialPosition,
                    zoom: 15,
                  ),
                  onMapCreated: _onMapCreated,
                  onCameraMove: _onCameraMove,
                ),
                Center(
                  child: Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 15,
                  right: 15,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari lokasi...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _searchLocation,
                  ),
                ),
              ],
            ),
    );
  }
}
