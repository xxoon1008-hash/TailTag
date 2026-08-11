class LocationRecord {
  final int? id; // 로컬 DB의 primary key
  final String tagDeviceId; // 어떤 태그에서 감지됐는지 (Tag.deviceId 참조)
  final double latitude;
  final double longitude;
  final int rssi; // 신호 세기 (감지 당시)
  final DateTime detectedAt; // 감지된 시간

  LocationRecord({
   this.id,
    required this.tagDeviceId,
    required this.latitude,
    required this.longitude,
    required this.rssi,
    required this.detectedAt,
});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tagDeviceId': tagDeviceId,
      'latitude': latitude,
      'longitude': longitude,
      'rssi': rssi,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    return LocationRecord(
      id: map['id'] as int?,
      tagDeviceId: map['tagDeviceId'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      rssi: map['rssi'] as int,
      detectedAt: DateTime.parse(map['detectedAt'] as String),
    );
  }
}