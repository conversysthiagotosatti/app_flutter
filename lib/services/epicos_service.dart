import 'dart:convert';

import '../models/epico.dart';
import 'api_client.dart';

class EpicosService {
  final ApiClient _client;

  EpicosService(this._client);

  Future<List<Epico>> listar({int? contratoId}) async {
    final response = await _client.get(
      '/api/epicos/',
      query: contratoId != null ? {'contrato': contratoId} : null,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => Epico.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    throw Exception('Erro ao carregar épicos (${response.statusCode})');
  }

  Future<Epico> criar({
    required int contratoId,
    required String titulo,
    String? descricao,
  }) async {
    final response = await _client.post(
      '/api/epicos/',
      body: {
        'contrato': contratoId,
        'titulo': titulo,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return Epico.fromJson(data);
    }

    throw Exception('Erro ao criar épico (${response.statusCode})');
  }

  Future<Epico> atualizar({
    required int id,
    required String titulo,
    String? descricao,
  }) async {
    final response = await _client.post(
      '/api/epicos/$id/',
      body: {
        'titulo': titulo,
        if (descricao != null) 'descricao': descricao,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return Epico.fromJson(data);
    }

    throw Exception('Erro ao atualizar épico (${response.statusCode})');
  }
}

