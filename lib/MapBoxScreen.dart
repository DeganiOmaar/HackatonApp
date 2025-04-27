import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;

class MapViewScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapViewScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  mp.MapboxMap? mapBoxController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localisation du cas'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: mp.MapWidget(
        onMapCreated: _onMapCreated,
        cameraOptions: mp.CameraOptions(
          center: mp.Point(coordinates: mp.Position(widget.longitude, widget.latitude)),
          zoom: 14.0,
        ),
      ),
    );
  }

  void _onMapCreated(mp.MapboxMap controller) {
    mapBoxController = controller;

    mapBoxController?.location.updateSettings(
      mp.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );

    // Optionnel : centrer encore une fois (sécurité)
    mapBoxController?.setCamera(
      mp.CameraOptions(
        center: mp.Point(coordinates: mp.Position(widget.longitude, widget.latitude)),
        zoom: 14.0,
      ),
    );
  }
}
