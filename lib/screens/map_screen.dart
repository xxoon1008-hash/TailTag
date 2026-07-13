import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../providers/tag_provider.dart';

class MapScreen extends StatelessWidget {
  final Tag tag;

  const MapScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final lastLocation = tagProvider.lastLocationFor(tag.deviceId);

    if (lastLocation == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tag.name)),
        body: const Center(child: Text('아직 위치 기록이 없습니다.')),
      );
    }

    final point = LatLng(lastLocation.latitude, lastLocation.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(tag.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '마지막 감지: ${_formatDateTime(lastLocation.detectedAt)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('신호세기: ${lastLocation.rssi} dBm'),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 17,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tailtag',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}