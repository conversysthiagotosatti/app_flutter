import 'dart:convert';

import 'api_client.dart';

class CopilotService {
  final ApiClient apiClient;

  CopilotService(this.apiClient);

  Future<String> perguntar({
    required int contratoId,
    required String mensagem,
  }) async {
    final resp = await apiClient.post(
      '/api/contratos/$contratoId/copilot/query/',
      body: {
        'message': mensagem,
      },
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao consultar Copilot (${resp.statusCode})',
      );
    }

    final data =
        jsonDecode(resp.body) as Map<String, dynamic>;
    final answer = data['answer']?.toString() ?? '';
    return answer;
  }

  Future<String> perguntarHelpdesk({
    required String mensagem,
    String? clienteNome,
  }) async {
    final body = <String, dynamic>{
      'message': mensagem,
    };
    if (clienteNome != null && clienteNome.isNotEmpty) {
      body['cliente_nome'] = clienteNome;
    }

    final resp = await apiClient.post(
      '/copilot/mcp/chat/',
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao consultar Copilot Helpdesk (${resp.statusCode})',
      );
    }

    final data =
        jsonDecode(resp.body) as Map<String, dynamic>;
    final answer = data['answer']?.toString() ?? '';
    return answer;
  }
}

