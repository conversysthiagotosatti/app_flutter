import 'dart:convert';

import '../models/notificacao.dart';
import 'api_client.dart';

class NotificacoesService {
  final ApiClient apiClient;

  NotificacoesService(this.apiClient);

  /// Lista notificações do usuário logado.
  /// Backend: GET /api/notificacoes/
  Future<List<Notificacao>> listar({bool apenasNaoLidas = false}) async {
    final resp = await apiClient.get(
      '/api/notificacoes/',
      // ajuste aqui se o backend suportar filtro de lidas/não lidas
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao buscar notificações (${resp.statusCode})',
      );
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is List) {
      return decoded
          .map((e) => Notificacao.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (decoded is Map && decoded['results'] is List) {
      final results = decoded['results'] as List;
      return results
          .map((e) => Notificacao.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Marca uma notificação como lida.
  /// Backend: POST /api/notificacoes/{id}/marcar_lida/
  Future<void> marcarComoLida(int id) async {
    final resp = await apiClient.post(
      '/api/notificacoes/$id/marcar_lida/',
      body: const {},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'Erro ao marcar notificação como lida (${resp.statusCode})',
      );
    }
  }
}

