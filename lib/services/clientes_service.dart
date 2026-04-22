import 'dart:convert';

import '../models/cliente.dart';
import '../models/subcliente.dart';
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

  Future<Cliente> obterCliente(int id) async {
    final resp = await _client.get('/api/clientes/$id/');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return Cliente.fromJson(data);
    }
    throw Exception('Erro ao carregar cliente (${resp.statusCode})');
  }

  Future<Cliente> criarCliente({
    required String nome,
    String? documento,
    String? email,
    String? telefone,
    required bool isProspecto,
    bool ativo = true,
    String? codigoIntegracao,
    int? idSoftdesk,
    int? cidadeId,
    String? endereco,
    String? enderecoNumero,
    String? enderecoCompl,
    String? bairro,
    String? cep,
    String? sidebarMenuBgColor,
    String? sidebarMenuTextColor,
  }) async {
    final resp = await _client.post(
      '/api/clientes/',
      body: {
        'nome': nome,
        'documento': ?documento,
        'email': ?email,
        'telefone': ?telefone,
        'ativo': ativo,
        'is_prospecto': isProspecto,
        'codigo_integracao': ?codigoIntegracao,
        'id_softdesk': ?idSoftdesk,
        'cidade': ?cidadeId,
        'endereco': ?endereco,
        'endereco_numero': ?enderecoNumero,
        'endereco_compl': ?enderecoCompl,
        'bairro': ?bairro,
        'cep': ?cep,
        'sidebar_menu_bg_color': ?sidebarMenuBgColor,
        'sidebar_menu_text_color': ?sidebarMenuTextColor,
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
    bool? ativo,
    String? codigoIntegracao,
    int? idSoftdesk,
    int? cidadeId,
    String? endereco,
    String? enderecoNumero,
    String? enderecoCompl,
    String? bairro,
    String? cep,
    String? sidebarMenuBgColor,
    String? sidebarMenuTextColor,
  }) async {
    final body = <String, dynamic>{
      'nome': nome,
      'documento': ?documento,
      'email': ?email,
      'telefone': ?telefone,
      'is_prospecto': isProspecto,
      'ativo': ?ativo,
      'codigo_integracao': ?codigoIntegracao,
      'id_softdesk': ?idSoftdesk,
      'cidade': ?cidadeId,
      'endereco': ?endereco,
      'endereco_numero': ?enderecoNumero,
      'endereco_compl': ?enderecoCompl,
      'bairro': ?bairro,
      'cep': ?cep,
      'sidebar_menu_bg_color': ?sidebarMenuBgColor,
      'sidebar_menu_text_color': ?sidebarMenuTextColor,
    };

    final resp = await _client.patch('/api/clientes/$id/', body: body);

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

  Future<List<Subcliente>> listarSubclientes(int clienteId) async {
    final resp = await _client.get('/api/clientes/$clienteId/subclientes/');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) {
        return data
            .map((e) => Subcliente.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception('Erro ao listar subclientes (${resp.statusCode})');
  }

  Future<Subcliente> criarSubcliente(
    int clienteId, {
    required String nome,
    String cnpj = '',
  }) async {
    final resp = await _client.post(
      '/api/clientes/$clienteId/subclientes/',
      body: {'nome': nome, 'cnpj': cnpj},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao criar subcliente (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Subcliente.fromJson(data);
  }

  Future<Subcliente> atualizarSubcliente(
    int clienteId,
    int subclienteId, {
    required String nome,
    String cnpj = '',
  }) async {
    final resp = await _client.patch(
      '/api/clientes/$clienteId/subclientes/$subclienteId/',
      body: {'nome': nome, 'cnpj': cnpj},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao atualizar subcliente (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return Subcliente.fromJson(data);
  }

  Future<void> excluirSubcliente(int clienteId, int subclienteId) async {
    final resp = await _client.delete(
      '/api/clientes/$clienteId/subclientes/$subclienteId/',
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao excluir subcliente (${resp.statusCode})');
    }
  }
}
