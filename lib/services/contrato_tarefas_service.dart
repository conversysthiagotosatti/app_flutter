import 'dart:convert';

import '../models/contrato_tarefa.dart';
import '../models/contrato_tarefa_log.dart';
import 'api_client.dart';

class ContratoTarefasService {
  final ApiClient _client;

  ContratoTarefasService(this._client);

  Future<List<ContratoTarefa>> listar({
    int? contratoId,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (contratoId != null) {
      query['contrato'] = contratoId;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    final response = await _client.get(
      '/api/contratos-tarefas/',
      query: query.isEmpty ? null : query,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => ContratoTarefa.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    throw Exception(
      'Erro ao carregar tarefas de contrato (${response.statusCode})',
    );
  }

  Future<ContratoTarefa> criar({
    required int contratoId,
    required String titulo,
    String? descricao,
    String? prioridade,
    DateTime? dataInicioPrevista,
    double? horasPrevistas,
    int? clausulaId,
    int? epicoId,
  }) async {
    final body = <String, dynamic>{
      'contrato': contratoId,
      'titulo': titulo,
      'status': 'ABERTA',
      'gerada_por_ia': false,
    };
    if (descricao != null && descricao.isNotEmpty) {
      body['descricao'] = descricao;
    }
    if (prioridade != null && prioridade.isNotEmpty) {
      body['prioridade'] = prioridade;
    }
    if (dataInicioPrevista != null) {
      body['data_inicio_prevista'] =
          dataInicioPrevista.toIso8601String().split('T').first;
    }
    if (horasPrevistas != null) {
      body['horas_previstas'] = horasPrevistas;
    }
    if (clausulaId != null) {
      body['clausula'] = clausulaId;
    }
    if (epicoId != null) {
      body['epico'] = epicoId;
    }

    final response = await _client.post(
      '/api/contratos-tarefas/',
      body: body,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return ContratoTarefa.fromJson(data);
    }

    throw Exception(
      'Erro ao criar tarefa (${response.statusCode})',
    );
  }

  Future<ContratoTarefa> atualizar(
    int id, {
    String? titulo,
    String? descricao,
    String? status,
    String? prioridade,
  }) async {
    final body = <String, dynamic>{};
    if (titulo != null) body['titulo'] = titulo;
    if (descricao != null) body['descricao'] = descricao;
    if (status != null) body['status'] = status;
    if (prioridade != null) body['prioridade'] = prioridade;

    final response = await _client.patch(
      '/api/contratos-tarefas/$id/',
      body: body,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return ContratoTarefa.fromJson(data);
    }

    throw Exception(
      'Erro ao atualizar tarefa (${response.statusCode})',
    );
  }

  Future<List<ContratoTarefaLog>> listarLogs(int tarefaId) async {
    final response = await _client.get(
      '/api/contratos-tarefas/$tarefaId/logs/',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) =>
                ContratoTarefaLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    throw Exception(
      'Erro ao carregar atividade da tarefa (${response.statusCode})',
    );
  }
}

