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
}

