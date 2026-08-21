import 'dart:math';

class BleUtils {
  static double rssiToDistance(int rssi, {int txPower = -59, double n = 2.0}) {
    return pow(10, (txPower - rssi) / (10 * n)).toDouble();
  }

  static String distanceLabel(int rssi) {
    final d = rssiToDistance(rssi);
    if (d < 1) return '1m 이내';
    if (d < 10) return '약 ${d.round()}m';
    if (d < 30) return '약 ${(d / 5).ceil() * 5}m';
    return '30m 이상';
  }

  // RSSI 신호 강도에 따른 색상 레벨 (0~3)
  static int signalLevel(int rssi) {
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }
}
