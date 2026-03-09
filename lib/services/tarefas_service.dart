import 'dart:convert';

import '../models/tarefa.dart';
import 'api_client.dart';

class TarefasService {
  final ApiClient _client;

  TarefasService(this._client);

  Future<List<Tarefa>> listarTarefas({
    int? contratoId,
    int? clienteId,
  }) async {
    final query = <String, dynamic>{};
    if (contratoId != null) {
      query['contrato'] = contratoId;
    }
    if (clienteId != null) {
      query['contrato__cliente'] = clienteId;
    }

    final response =
        await _client.get('/api/tarefas/', query: query.isEmpty ? null : query);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => Tarefa.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    throw Exception('Erro ao carregar tarefas (${response.statusCode})');
  }
}

