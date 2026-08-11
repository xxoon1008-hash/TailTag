import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.219.112:8080';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> authHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String get baseUrl => _baseUrl;
}
