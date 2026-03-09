import 'dart:convert';

import '../models/relatorio_tarefas_meta.dart';
import 'api_client.dart';

class RelatoriosService {
  final ApiClient apiClient;

  RelatoriosService(this.apiClient);

  /// Lista os metadados de relatórios de tarefas.
  /// Backend web usa: GET /api/relatorios-tarefas/
  Future<List<RelatorioTarefasMeta>> listar() async {
    final resp = await apiClient.get('/api/relatorios-tarefas/');
    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao buscar relatórios (${resp.statusCode})',
      );
    }

    final decoded = jsonDecode(resp.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      list = decoded['results'] as List<dynamic>;
    } else {
      list = const [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(RelatorioTarefasMeta.fromJson)
        .toList();
  }

  /// Carrega os dados do relatório apontado por `endpoint_api`.
  ///
  /// No front web, o campo endpoint_api pode vir como "/api/xyz" ou "/xyz".
  /// Aqui normalizamos para sempre chamar o backend Django na raiz "/api".
  Future<dynamic> carregarDadosEndpoint(RelatorioTarefasMeta meta) async {
    String path = meta.endpointApi;

    if (path.startsWith('/api')) {
      // já está no formato /api/...
    } else if (path.startsWith('/')) {
      path = '/api$path';
    } else {
      path = '/api/$path';
    }

    final resp = await apiClient.get(path);
    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao carregar dados do relatório (${resp.statusCode})',
      );
    }

    if (resp.body.isEmpty) return null;
    return jsonDecode(resp.body);
  }
}

