import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../providers/tag_provider.dart';
import 'dart:ui' as ui;

class MapScreen extends StatefulWidget {
  final Tag tag;

  const MapScreen({super.key, required this.tag});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final lastLocation = tagProvider.lastLocationFor(widget.tag.deviceId);

    if (lastLocation == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.tag.name)),
        body: const Center(child: Text('아직 위치 기록이 없습니다.')),
      );
    }

    final point = LatLng(lastLocation.latitude, lastLocation.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tag.name),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(lastLocation.detectedAt),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.bluetooth, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${lastLocation.rssi} dBm',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: point,
                initialZoom: 17,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.tailtag',
                  retinaMode: true,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 56,
                      height: 56,
                      alignment: Alignment.topCenter,
                      child: _TagMarker(
                        color: Theme.of(context).colorScheme.primary,
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

class _TagMarker extends StatelessWidget {
  final Color color;
  const _TagMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: color, width: 2.5),
          ),
          child: Icon(Icons.label, color: color, size: 20),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: PinTailPainter(color: color),
        ),
      ],
    );
  }
}

class PinTailPainter extends CustomPainter {
  final Color color;
  const PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
