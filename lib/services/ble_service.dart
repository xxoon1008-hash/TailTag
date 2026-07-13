import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  // 권한 요청
  Future<bool> requestBlePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every(
        (statuses) => statuses.isGranted || statuses.isLimited,
    );
  }

  // 태그 등록용: 주변 기기 전체 스캔
  // 스캔 결과를 실시간 스트림으로 변환 (등록 화면에서 리스트업할 때 사용)
  Stream<List<ScanResult>> scanForDevices({
    Duration timeout = const Duration(seconds: 8),
}) {
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // 등록된 태그 감지용: 특정 deviceId만 확인
  // 등록된 태그 deviceId 목록을 받아서, 감지된 태그와 RSSI를 콜백으로 전달
  Future<void> scanForRegisteredTags({
    required List<String> registeredDeviceIds,
    required void Function(String deviceId, int rssi) onTagDetected,
    Duration timeout = const Duration(seconds: 10),
}) async {
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final deviceId = result.device.remoteId.str;
        if (registeredDeviceIds.contains(deviceId)) {
          onTagDetected(deviceId, result.rssi);
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);
    await Future.delayed(timeout);
    await subscription.cancel();
    await FlutterBluePlus.stopScan();
  }

  // 블루투스 어댑터가 켜져있는지 확인
  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;
}