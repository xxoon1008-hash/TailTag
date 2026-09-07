import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _authBase = 'http://192.168.219.112:8080/api/auth';
  static const String _userBase = 'http://192.168.219.112:8080/api/users';
  static const String _tokenKey = 'auth_token';
  static const String _nicknameKey = 'nickname';
  static const String _emailKey = 'email';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: _tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await http.post(
      Uri.parse('$_authBase/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'nickname': nickname}),
    ).timeout(const Duration(seconds: 10));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      await _storage.write(key: _tokenKey, value: body['token']);
      await _storage.write(key: _nicknameKey, value: body['nickname']);
      await _storage.write(key: _emailKey, value: body['email']);
    } else {
      final message = body['error'] ?? body.values.first ?? '회원가입에 실패했습니다.';
      throw AuthException(message.toString());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_authBase/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      await _storage.write(key: _tokenKey, value: body['token']);
      await _storage.write(key: _nicknameKey, value: body['nickname']);
      await _storage.write(key: _emailKey, value: body['email']);
    } else {
      final message = body['error'] ?? '로그인에 실패했습니다.';
      throw AuthException(message.toString());
    }
  }

  Future<void> updateNickname(String nickname) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$_userBase/me/nickname'),
      headers: headers,
      body: jsonEncode({'nickname': nickname}),
    );
    if (response.statusCode == 200) {
      await _storage.write(key: _nicknameKey, value: nickname);
    } else {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw AuthException(body['error'] ?? '닉네임 변경에 실패했습니다.');
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$_userBase/me/password'),
      headers: headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw AuthException(body['error'] ?? '비밀번호 변경에 실패했습니다.');
    }
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<String?> getNickname() => _storage.read(key: _nicknameKey);
  Future<String?> getEmail() => _storage.read(key: _emailKey);

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _nicknameKey);
    await _storage.delete(key: _emailKey);
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
