import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  /// Login sem pedir cliente na tela.
  ///
  /// Fluxo:
  /// 1) /api/auth/login/  -> gera tokens JWT
  /// 2) /api/accounts/auth/me/clients/ (com Bearer) -> pega lista de clientes do usuário
  /// 3) Escolhe o primeiro cliente da lista e chama
  ///    /api/accounts/auth/novo_login/ com username/password/cliente
  ///    para obter os módulos e o cliente final, já validado.
  ///
  /// Retorna o JSON da última chamada (novo_login) ou null em caso de erro.
  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    // 1) Login simples com JWT
    final authUri =
        Uri.parse('${ApiClient.baseUrl}/api/auth/login/');

    final authResponse = await http.post(
      authUri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (authResponse.statusCode != 200) {
      return null;
    }

    final authData =
        jsonDecode(authResponse.body) as Map<String, dynamic>;
    final access = authData['access'] as String?;
    final refresh = authData['refresh'] as String?;
    if (access == null || refresh == null) {
      return null;
    }

    // Salva tokens do primeiro login
    await _client.saveTokens(access: access, refresh: refresh);

    // 2) Descobre os clientes do usuário
    final meClientsResponse =
        await _client.get('/api/auth/me/clients/', auth: true);

    if (meClientsResponse.statusCode != 200) {
      return null;
    }

    final meClientsData = jsonDecode(meClientsResponse.body);
    if (meClientsData is! List || meClientsData.isEmpty) {
      return null;
    }

    // Por enquanto, usa o primeiro cliente ativo da lista
    final first = meClientsData.first as Map<String, dynamic>;
    final clienteId = first['cliente_id'] as int?;
    if (clienteId == null) {
      return null;
    }

    // 3) Chama o novo_login para obter módulos + cliente consolidado
    final novoLoginUri = Uri.parse(
      '${ApiClient.baseUrl}/api/auth/novo_login/',
    );

    final novoLoginResponse = await http.post(
      novoLoginUri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
        'cliente': clienteId,
      }),
    );

    if (novoLoginResponse.statusCode != 200) {
      return null;
    }

    final data =
        jsonDecode(novoLoginResponse.body) as Map<String, dynamic>;
    final access2 = data['access'] as String?;
    final refresh2 = data['refresh'] as String?;
    if (access2 != null && refresh2 != null) {
      // sobrescreve tokens, se desejar
      await _client.saveTokens(access: access2, refresh: refresh2);
    }

    final modules = data['modulos'];
    if (modules is List) {
      // Garante que o módulo "Propostas" exista no superapp.
      // O backend pode não retornar explicitamente, mas a UI precisa estar disponível.
      final normalized = List<dynamic>.from(modules);
      final alreadyHasPropostas = normalized.any((m) {
        if (m is Map) {
          final nome = m['nome'];
          if (nome is String) return nome.toLowerCase().contains('proposta');
        }
        return false;
      });

      if (!alreadyHasPropostas) {
        normalized.add({
          'nome': 'Propostas',
          'descricao': 'Propostas comerciais',
        });
      }

      data['modulos'] = normalized;
      await _client.saveModules(normalized);
    }

    return data;
  }

  Future<void> logout() async {
    await _client.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    // A partir de agora, sempre força a tela de login
    // ao abrir o app, independentemente de haver token salvo.
    await _client.clearTokens();
    return false;
  }
}

