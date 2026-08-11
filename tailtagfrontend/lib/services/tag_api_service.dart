import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/tag.dart';

class TagApiService {
  static const String _baseUrl = 'http://192.168.219.112:8080/api/tags';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Tag>> getTags() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(utf8.decode(response.bodyBytes));
      return json.map((e) => Tag.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('태그 목록을 불러올 수 없습니다.');
  }

  Future<Tag> addTag(String name, String deviceId) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'deviceId': deviceId}),
    );
    if (response.statusCode == 200) {
      return Tag.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception(body['error'] ?? '태그 등록에 실패했습니다.');
  }

  Future<void> deleteTag(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 204) {
      throw Exception('태그 삭제에 실패했습니다.');
    }
  }
}
