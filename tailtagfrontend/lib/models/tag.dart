class Tag {
  final int? id; // 로컬 DB의 아이디 primary key (신규 생성 시 null)
  final String name; // 사용자가 부여한 태그 이름 (예: "지갑", "가방")
  final String deviceId; // BLE 기기의 고유 ID (Android에서는 MAC 주소 역할)
  final DateTime registeredAt; // 등록 시간

  Tag({
    this.id,
    required this.name,
    required this.deviceId,
    required this.registeredAt,
});

  // DB 저장을 위한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'deviceId': deviceId,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  // DB에서 읽어온 Map을 Tag 객체로 변환
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
      deviceId: map['deviceId'] as String,
      registeredAt: DateTime.parse(map['registeredAt'] as String),
    );
  }

  // 백엔드 API 응답 JSON → Tag 변환
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      deviceId: json['deviceId'] as String,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
    );
  }
}