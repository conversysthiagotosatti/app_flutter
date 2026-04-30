import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Chamadas usadas pelo `SettingsModal` do portal (`front-jyra`).
class SettingsService {
  SettingsService(this._c);

  final ApiClient _c;

  List<Map<String, dynamic>> _decodeList(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      return (decoded['results'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> fetchMe({int? clienteId}) async {
    final path = clienteId != null
        ? '/api/auth/me/?cliente=$clienteId'
        : '/api/auth/me/';
    final r = await _c.get(path);
    if (r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode}');
    }
    final d = jsonDecode(r.body);
    if (d is! Map<String, dynamic>) throw Exception('Resposta inválida');
    return d;
  }

  Future<Map<String, dynamic>> patchMe({
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final r = await _c.patchMultipart(
      '/api/auth/me/',
      fields: fields,
      files: files,
    );
    if (r.statusCode != 200) {
      throw Exception(r.body.isNotEmpty ? r.body : 'HTTP ${r.statusCode}');
    }
    final d = jsonDecode(r.body);
    if (d is! Map<String, dynamic>) throw Exception('Resposta inválida');
    return d;
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final r = await _c.post(
      '/api/auth/password/change/',
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
    if (r.statusCode != 200 && r.statusCode != 204) {
      String msg = 'HTTP ${r.statusCode}';
      try {
        final d = jsonDecode(r.body);
        if (d is Map && d['detail'] != null) msg = d['detail'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<List<Map<String, dynamic>>> fetchClientes() async {
    final r = await _c.get('/api/clientes/');
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return _decodeList(jsonDecode(r.body));
  }

  Future<Map<String, dynamic>> fetchCliente(int id) async {
    final r = await _c.get('/api/clientes/$id/');
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final d = jsonDecode(r.body);
    if (d is! Map<String, dynamic>) throw Exception('Resposta inválida');
    return d;
  }

  Future<void> updateCliente(
    int id, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final r = await _c.patchMultipart(
      '/api/clientes/$id/',
      fields: fields,
      files: files,
    );
    if (r.statusCode != 200) {
      throw Exception(r.body.isNotEmpty ? r.body : 'HTTP ${r.statusCode}');
    }
  }

  Future<void> createCliente({
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final r = await _c.postMultipart(
      '/api/clientes/',
      fields: fields,
      files: files,
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception(r.body.isNotEmpty ? r.body : 'HTTP ${r.statusCode}');
    }
  }

  Future<void> deleteCliente(int id) async {
    final r = await _c.delete('/api/clientes/$id/');
    if (r.statusCode != 204 && r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers({int? clienteId}) async {
    final path = clienteId != null
        ? '/api/users/?cliente=$clienteId'
        : '/api/users/';
    final r = await _c.get(path);
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return _decodeList(jsonDecode(r.body));
  }

  Future<List<Map<String, dynamic>>> fetchDepartamentosSap() async {
    final r = await _c.get('/api/auth/departamentos-sap/');
    if (r.statusCode != 200) return const [];
    final d = jsonDecode(r.body);
    return _decodeList(d);
  }

  Future<void> createUser(Map<String, dynamic> body) async {
    final r = await _c.post('/api/auth/users/', body: body);
    if (r.statusCode != 200 && r.statusCode != 201) {
      String msg = 'HTTP ${r.statusCode}';
      try {
        final d = jsonDecode(r.body);
        if (d is Map) {
          msg = d.entries.map((e) => '${e.key}: ${e.value}').join('; ');
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<void> createSubcliente(
    int clienteId, {
    required String nome,
    required String cnpj,
  }) async {
    final r = await _c.post(
      '/api/clientes/$clienteId/subclientes/',
      body: {'nome': nome, 'cnpj': cnpj},
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('HTTP ${r.statusCode}');
    }
  }

  Future<void> updateSubcliente(
    int clienteId,
    int subId, {
    required String nome,
    required String cnpj,
  }) async {
    final r = await _c.patch(
      '/api/clientes/$clienteId/subclientes/$subId/',
      body: {'nome': nome, 'cnpj': cnpj},
    );
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  }

  Future<void> deleteSubcliente(int clienteId, int subId) async {
    final r = await _c.delete('/api/clientes/$clienteId/subclientes/$subId/');
    if (r.statusCode != 204 && r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode}');
    }
  }
}
