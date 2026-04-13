import 'dart:convert';

import '../models/cliente.dart';
import 'api_client.dart';

class ClientesService {
  final ApiClient _client;

  ClientesService(this._client);

  Future<List<Cliente>> listarClientes() async {
    final response = await _client.get('/api/clientes/');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    throw Exception('Erro ao carregar clientes (${response.statusCode})');
  }

  Future<Cliente> criarCliente({
    required String nome,
    String? documento,
    String? email,
    String? telefone,
    required bool isProspecto,
  }) async {
    final resp = await _client.post(
      '/api/clientes/',
      body: {
        'nome': nome,
        if (documento != null) 'documento': documento,
        if (email != null) 'email': email,
        if (telefone != null) 'telefone': telefone,
        // Backend usa `ativo`. Front usa `is_prospecto`.
        'ativo': !isProspecto,
      },
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao criar cliente (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Cliente.fromJson(data);
  }

  Future<Cliente> atualizarCliente({
    required int id,
    required String nome,
    String? documento,
    String? email,
    String? telefone,
    required bool isProspecto,
  }) async {
    final resp = await _client.patch(
      '/api/clientes/$id/',
      body: {
        'nome': nome,
        if (documento != null) 'documento': documento,
        if (email != null) 'email': email,
        if (telefone != null) 'telefone': telefone,
        'ativo': !isProspecto,
      },
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao atualizar cliente (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Cliente.fromJson(data);
  }

  Future<void> excluirCliente(int id) async {
    final resp = await _client.delete('/api/clientes/$id/');
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao excluir cliente (${resp.statusCode})');
    }
  }
}

