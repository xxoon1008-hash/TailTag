import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/tag.dart';
import '../models/location_record.dart';
import '../services/ble_service.dart';
import '../services/location_service.dart';
import '../services/db_service.dart';
import '../services/tag_api_service.dart';

class TagProvider with ChangeNotifier {
  final BleService _bleService = BleService();
  final LocationService _locationService = LocationService();
  final DbService _dbService = DbService();
  final TagApiService _tagApiService = TagApiService();

  List<Tag> _tags = [];
  final Map<String, LocationRecord> _lastLocations = {};
  Timer? _periodicScanTimer;
  bool _isScanning = false;

  List<Tag> get tags => _tags;
  bool get isScanning => _isScanning;

  LocationRecord? lastLocationFor(String deviceId) => _lastLocations[deviceId];

  Future<void> loadTags() async {
    try {
      _tags = await _tagApiService.getTags();
      for (final tag in _tags) {
        final last = await _dbService.getLastLocation(tag.deviceId);
        if (last != null) _lastLocations[tag.deviceId] = last;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('loadTags error: $e');
      notifyListeners();
    }
  }

  Future<void> registerTag(String name, String deviceId) async {
    final tag = await _tagApiService.addTag(name, deviceId);
    _tags = [..._tags, tag];
    notifyListeners();
  }

  Future<void> removeTag(String deviceId) async {
    final tag = _tags.firstWhere((t) => t.deviceId == deviceId);
    if (tag.id == null) return;
    await _tagApiService.deleteTag(tag.id!);
    _tags = _tags.where((t) => t.deviceId != deviceId).toList();
    _lastLocations.remove(deviceId);
    notifyListeners();
  }

  void startPeriodicScan({Duration interval = const Duration(minutes: 2)}) {
    _periodicScanTimer?.cancel();
    _runScanCycle();
    _periodicScanTimer = Timer.periodic(interval, (_) => _runScanCycle());
  }

  void stopPeriodicScan() {
    _periodicScanTimer?.cancel();
    _periodicScanTimer = null;
  }

  Future<void> _runScanCycle() async {
    if (_isScanning) return;
    if (_tags.isEmpty) {
      await loadTags();
      if (_tags.isEmpty) return;
    }
    _isScanning = true;
    notifyListeners();

    final registeredIds = _tags.map((t) => t.deviceId).toList();

    await _bleService.scanForRegisteredTags(
      registeredDeviceIds: registeredIds,
      onTagDetected: (deviceId, rssi) async {
        final position = await _locationService.getCurrentPosition();
        if (position == null) return;

        final record = LocationRecord(
          tagDeviceId: deviceId,
          latitude: position.latitude,
          longitude: position.longitude,
          rssi: rssi,
          detectedAt: DateTime.now(),
        );

        await _dbService.insertLocationRecord(record);
        _lastLocations[deviceId] = record;
        notifyListeners();
      },
    );

    _isScanning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _periodicScanTimer?.cancel();
    super.dispose();
  }
}
