import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  /// Ajuste esta URL para o host/porta onde o Django está rodando.
  static const String baseUrl = 'http://172.20.10.84';

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _modulesKey = 'modules';

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_accessTokenKey);
  }

  Future<void> clearTokens() async {
    final prefs = await _prefs;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_modulesKey);
  }

  Future<void> saveModules(List<dynamic> modules) async {
    final prefs = await _prefs;
    await prefs.setString(_modulesKey, jsonEncode(modules));
  }

  Future<List<dynamic>?> loadModules() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_modulesKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded;
    }
    return null;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters:
          query?.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final headers = await _buildHeaders(auth: auth);
    final uri = _buildUri(path, query);
    return http.get(uri, headers: headers);
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final headers = await _buildHeaders(auth: auth);
    final uri = _buildUri(path);
    return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final headers = await _buildHeaders(auth: auth);
    final uri = _buildUri(path);
    return http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  Future<Map<String, String>> buildAuthHeaders({bool json = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, String>> _buildHeaders({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }
}


