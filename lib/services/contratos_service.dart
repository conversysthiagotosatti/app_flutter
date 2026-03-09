import 'dart:convert';

import '../models/contrato.dart';
import 'api_client.dart';

class ContratosService {
  final ApiClient _client;

  ContratosService(this._client);

  Future<List<Contrato>> listarContratos({int? clienteId}) async {
    final response = await _client.get(
      '/api/contratos/',
      query: clienteId != null ? {'cliente': clienteId} : null,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => Contrato.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    throw Exception('Erro ao carregar contratos (${response.statusCode})');
  }
}

