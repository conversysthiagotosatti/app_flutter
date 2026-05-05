import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  /// Backend local (ex.: `python manage.py runserver` → porta 8000).
  /// Emulador Android use `http://10.0.2.2:8000` em vez de localhost.
  static const String baseUrl = 'http://172.20.5.66:8000';

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _modulesKey = 'modules';
  static const _authClienteIdKey = 'auth_cliente_id';
  static const _authClienteNomeKey = 'auth_cliente_nome';

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
    await prefs.remove(_authClienteIdKey);
    await prefs.remove(_authClienteNomeKey);
  }

  /// Cliente ativo após `novo_login` (contexto Copilot Helpdesk / portal).
  Future<void> saveAuthClienteContext({
    required int clienteId,
    required String clienteNome,
  }) async {
    final prefs = await _prefs;
    await prefs.setInt(_authClienteIdKey, clienteId);
    await prefs.setString(_authClienteNomeKey, clienteNome);
  }

  Future<int?> loadAuthClienteId() async {
    final prefs = await _prefs;
    return prefs.getInt(_authClienteIdKey);
  }

  Future<String?> loadAuthClienteNome() async {
    final prefs = await _prefs;
    return prefs.getString(_authClienteNomeKey);
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
    Map<String, String>? extraHeaders,
  }) async {
    final headers = await _buildHeaders(auth: auth, extra: extraHeaders);
    final uri = _buildUri(path, query);
    return http.get(uri, headers: headers);
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool auth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = await _buildHeaders(auth: auth, extra: extraHeaders);
    final uri = _buildUri(path, query);
    return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool auth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = await _buildHeaders(auth: auth, extra: extraHeaders);
    final uri = _buildUri(path, query);
    return http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  Future<http.Response> delete(
    String path, {
    bool auth = true,
    Map<String, dynamic>? query,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = await _buildHeaders(auth: auth, extra: extraHeaders);
    final uri = _buildUri(path, query);
    return http.delete(uri, headers: headers);
  }

  /// POST multipart (ex.: despesas com comprovante). Não envia `Content-Type`: o boundary é definido pelo pacote `http`.
  Future<http.Response> postMultipart(
    String path, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
    Map<String, dynamic>? query,
    bool auth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(path, query);
    final req = http.MultipartRequest('POST', uri);
    req.headers['Accept'] = 'application/json';
    if (auth) {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
    }
    if (extraHeaders != null) {
      req.headers.addAll(extraHeaders);
    }
    req.fields.addAll(fields);
    req.files.addAll(files);
    final streamed = await req.send();
    return http.Response.fromStream(streamed);
  }

  /// PATCH multipart (edição de despesa com novo comprovante opcional).
  Future<http.Response> patchMultipart(
    String path, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
    Map<String, dynamic>? query,
    bool auth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(path, query);
    final req = http.MultipartRequest('PATCH', uri);
    req.headers['Accept'] = 'application/json';
    if (auth) {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
    }
    if (extraHeaders != null) {
      req.headers.addAll(extraHeaders);
    }
    req.fields.addAll(fields);
    req.files.addAll(files);
    final streamed = await req.send();
    return http.Response.fromStream(streamed);
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

  Future<Map<String, String>> _buildHeaders({
    bool auth = true,
    Map<String, String>? extra,
  }) async {
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

    if (extra != null) {
      headers.addAll(extra);
    }

    return headers;
  }
}


