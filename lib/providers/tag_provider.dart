import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/tag.dart';
import '../models/location_record.dart';
import '../services/ble_service.dart';
import '../services/location_service.dart';
import '../services/db_service.dart';

class TagProvider with ChangeNotifier {
  final BleService _bleService = BleService();
  final LocationService _locationService = LocationService();
  final DbService _dbService = DbService();

  List<Tag> _tags = [];
  final Map<String, LocationRecord> _lastLocations = {}; // deviceId -> 마지막 위치
  Timer? _periodicScanTimer;
  bool _isScanning = false;

  List<Tag> get tags => _tags;
  bool get isScanning => _isScanning;

  LocationRecord? lastLocationFor(String deviceId) => _lastLocations[deviceId];

  // 초기화

  Future<void> loadTags() async {
    _tags = await _dbService.getAllTags();
    for (final tag in _tags) {
      final last = await _dbService.getLastLocation(tag.deviceId);
      if (last != null) {
        _lastLocations[tag.deviceId] = last;
      }
    }
    notifyListeners();
  }

  // 태그 삭제
  Future<void> removeTag(String deviceId) async {
    await _dbService.deleteTag(deviceId);
    await loadTags();
  }

  // 태그 등록
  Future<void> registerTag(String name, String deviceId) async {
    final tag = Tag(
      name: name,
      deviceId: deviceId,
      registeredAt: DateTime.now(),
    );
    await _dbService.insertTag(tag);
    await loadTags();
  }

  // 주기적 스캔 시작/중지
  void startPeriodicScan({Duration interval = const Duration(minutes: 2)}) {
    _periodicScanTimer?.cancel();
    _runScanCycle(); // 즉시 한 번 실행
    _periodicScanTimer = Timer.periodic(interval, (_) => _runScanCycle());
  }

  void stopPeriodicScan() {
    _periodicScanTimer?.cancel();
    _periodicScanTimer = null;
  }

  Future<void> _runScanCycle() async {
    if (_isScanning || _tags.isEmpty) return;
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