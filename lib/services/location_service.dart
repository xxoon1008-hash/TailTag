import 'package:geolocator/geolocator.dart';

class LocationService {
  // 위치 권한 확인 및 요청
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비(GPS) 자체가 꺼져있는 경우
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.denied) {
      // 사용자가 영구 거부한 경우 -> 설정 앱으로 안내 필요
      return false;
    }

    // whileInUse는 됐지만 background(항상 유지)가 필요한 경우 별도 체크
    return true;
  }

  // 백그라운드 위치 권한까지 확인 (Android 10+)
  Future<bool> requestBackgroundPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) {
      return true;
    }
    // whileInUse 상태에서 always로 승격 유형
    permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always;
  }

  // 현재 위치(GPS 좌표) 획득
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      // 위치 획득 실패 (타임아, GPS 신호 없음 등)
      return null;
    }
  }
}