import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  Future<bool> requestBlePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every(
        (s) => s.isGranted || s.isLimited,
    );
  }

  Stream<List<ScanResult>> scanForDevices({
    Duration timeout = const Duration(seconds: 8),
  }) {
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> scanForRegisteredTags({
    required List<String> registeredDeviceIds,
    required void Function(String deviceId, int rssi) onTagDetected,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final mac = result.device.remoteId.str;
        if (registeredDeviceIds.contains(mac)) {
          onTagDetected(mac, result.rssi);
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);
    await Future.delayed(timeout);
    await subscription.cancel();
    await FlutterBluePlus.stopScan();
  }

  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;
}
