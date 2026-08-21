import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../models/location_record.dart';
import '../providers/tag_provider.dart';
import '../utils/ble_utils.dart';
import 'map_screen.dart' show PinTailPainter;

class AllTagsMapScreen extends StatefulWidget {
  const AllTagsMapScreen({super.key});

  @override
  State<AllTagsMapScreen> createState() => _AllTagsMapScreenState();
}

class _AllTagsMapScreenState extends State<AllTagsMapScreen> {
  final MapController _mapController = MapController();
  _MarkerGroup? _selectedGroup;

  // 같은 위치(~11m 이내) 태그끼리 그룹핑
  List<_MarkerGroup> _groupMarkers(List<_TagInfo> tagInfos) {
    final groups = <_MarkerGroup>[];
    for (final info in tagInfos) {
      final loc = info.location!;
      bool added = false;
      for (final group in groups) {
        final rep = group.items.first.location!;
        if ((loc.latitude - rep.latitude).abs() < 0.0001 &&
            (loc.longitude - rep.longitude).abs() < 0.0001) {
          group.items.add(info);
          added = true;
          break;
        }
      }
      if (!added) groups.add(_MarkerGroup(items: [info]));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final tags = tagProvider.tags;

    final tagInfos = tags
        .map((tag) => _TagInfo(
              tag: tag,
              location: tagProvider.lastLocationFor(tag.deviceId),
            ))
        .where((t) => t.location != null)
        .toList();

    final groups = _groupMarkers(tagInfos);
    final initialCenter = _computeCenter(tagInfos);
    final initialZoom = tagInfos.isEmpty ? 10.0 : (tagInfos.length == 1 ? 17.0 : 13.0);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('지도'),
        actions: [
          if (tagProvider.isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (tagInfos.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    tags.isEmpty ? '등록된 태그가 없습니다.' : '아직 감지된 위치가 없습니다.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                  ),
                ],
              ),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: initialZoom,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation,
                ),
                onTap: (tapPos, point) => setState(() => _selectedGroup = null),
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
                  markers: groups.map((group) {
                    final isSelected = _selectedGroup == group;
                    final center = group.center;

                    return group.items.length == 1
                        ? _buildSingleMarker(group, isSelected, theme)
                        : _buildClusterMarker(group, isSelected, theme, center);
                  }).toList(),
                ),
              ],
            ),

          // 단일 태그 정보 카드
          if (_selectedGroup != null && _selectedGroup!.items.length == 1)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _SingleTagCard(
                info: _selectedGroup!.items.first,
                onClose: () => setState(() => _selectedGroup = null),
              ),
            ),
        ],
      ),
    );
  }

  Marker _buildSingleMarker(_MarkerGroup group, bool isSelected, ThemeData theme) {
    final info = group.items.first;
    final point = LatLng(info.location!.latitude, info.location!.longitude);
    final color = isSelected ? theme.colorScheme.tertiary : theme.colorScheme.primary;

    return Marker(
      point: point,
      width: 56,
      height: 66,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedGroup = group);
          _mapController.move(point, _mapController.camera.zoom);
        },
        child: Column(
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
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                info.tag.name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildClusterMarker(
      _MarkerGroup group, bool isSelected, ThemeData theme, LatLng center) {
    final color = isSelected ? theme.colorScheme.tertiary : theme.colorScheme.primary;

    return Marker(
      point: center,
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedGroup = group);
          _showClusterBottomSheet(group);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${group.items.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClusterBottomSheet(_MarkerGroup group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '이 위치의 태그 (${group.items.length}개)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: group.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 16),
                  itemBuilder: (ctx, index) {
                    final info = group.items[index];
                    final loc = info.location!;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.label,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18),
                      ),
                      title: Text(info.tag.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${_fmt(loc.detectedAt)}  •  ${BleUtils.distanceLabel(loc.rssi)}  •  ${loc.rssi} dBm',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).whenComplete(() => setState(() => _selectedGroup = null));
  }

  LatLng _computeCenter(List<_TagInfo> tagInfos) {
    if (tagInfos.isEmpty) return const LatLng(37.5665, 126.9780);
    final lat = tagInfos.map((t) => t.location!.latitude).reduce((a, b) => a + b) / tagInfos.length;
    final lng = tagInfos.map((t) => t.location!.longitude).reduce((a, b) => a + b) / tagInfos.length;
    return LatLng(lat, lng);
  }

  String _fmt(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _TagInfo {
  final Tag tag;
  final LocationRecord? location;
  const _TagInfo({required this.tag, required this.location});
}

class _MarkerGroup {
  final List<_TagInfo> items;
  _MarkerGroup({required this.items});

  LatLng get center {
    final lat = items.map((t) => t.location!.latitude).reduce((a, b) => a + b) / items.length;
    final lng = items.map((t) => t.location!.longitude).reduce((a, b) => a + b) / items.length;
    return LatLng(lat, lng);
  }
}

class _SingleTagCard extends StatelessWidget {
  final _TagInfo info;
  final VoidCallback onClose;

  const _SingleTagCard({required this.info, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final loc = info.location!;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.label,
                  color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(info.tag.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${loc.month}/${loc.day} ${loc.hour}:${loc.minute}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.bluetooth, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${loc.rssi} dBm',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 8),
                      _MapDistanceChip(rssi: loc.rssi),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

extension on LocationRecord {
  int get month => detectedAt.month;
  int get day => detectedAt.day;
  String get hour => detectedAt.hour.toString().padLeft(2, '0');
  String get minute => detectedAt.minute.toString().padLeft(2, '0');
}

class _MapDistanceChip extends StatelessWidget {
  final int rssi;
  const _MapDistanceChip({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final level = BleUtils.signalLevel(rssi);
    final colors = [Colors.red, Colors.orange, Colors.yellow[700]!, Colors.green];
    final color = colors[level];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        BleUtils.distanceLabel(rssi),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
