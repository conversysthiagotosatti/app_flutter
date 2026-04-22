import 'dart:convert';

import 'api_client.dart';

class HelpdeskCopilotResult {
  final String answer;
  final String? intent;
  final num? confianca;

  HelpdeskCopilotResult({
    required this.answer,
    this.intent,
    this.confianca,
  });

  factory HelpdeskCopilotResult.fromJson(Map<String, dynamic> json) {
    return HelpdeskCopilotResult(
      answer: (json['answer'] ?? '').toString(),
      intent: json['intent'] as String?,
      confianca: json['confianca'] as num?,
    );
  }
}

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

  /// Mesmo contrato do portal: `askHelpdeskCopilot` → `POST /api/helpdesk/copilot/`.
  Future<HelpdeskCopilotResult> askHelpdeskCopilot({
    required String mensagem,
    int? clienteId,
    int? chamadoId,
  }) async {
    final body = <String, dynamic>{
      'mensagem': mensagem.trim(),
    };
    if (clienteId != null) {
      body['cliente_id'] = clienteId;
    }
    if (chamadoId != null) {
      body['chamado_id'] = chamadoId;
    }

    final resp = await apiClient.post(
      '/api/helpdesk/copilot/',
      body: body,
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      var detail = '';
      try {
        final j = jsonDecode(resp.body);
        if (j is Map && j['detail'] != null) {
          detail = j['detail'].toString();
        }
      } catch (_) {
        detail = resp.body.length > 200
            ? resp.body.substring(0, 200)
            : resp.body;
      }
      throw Exception(
        detail.isEmpty
            ? 'Erro Copilot Helpdesk (${resp.statusCode})'
            : detail,
      );
    }

    final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do Copilot Helpdesk');
    }
    return HelpdeskCopilotResult.fromJson(data);
  }
}
