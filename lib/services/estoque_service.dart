import 'dart:convert';

import '../models/local_estoque.dart';
import '../models/motivo_movimentacao.dart';
import '../models/movimentacao_rastreamento.dart';
import '../models/rastreamento_serial.dart';
import 'api_client.dart';

/// Extrai o serial de texto puro ou de URL do tipo `/estoque/serial/?sn=...`.
String serialFromQrOrText(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  final uri = Uri.tryParse(t);
  if (uri != null && uri.hasQuery) {
    final sn = uri.queryParameters['sn'];
    if (sn != null && sn.trim().isNotEmpty) {
      return Uri.decodeQueryComponent(sn.trim());
    }
  }
  return t;
}

class EstoqueService {
  final ApiClient _client;

  EstoqueService(this._client);

  /// GET /api/estoque/rastreamento-serial/?sn=...
  Future<RastreamentoSerialInfo> buscarPorSerial(String serial) async {
    final s = serial.trim();
    if (s.isEmpty) {
      throw Exception('Informe o número de série.');
    }
    final resp = await _client.get(
      '/api/estoque/rastreamento-serial/',
      query: {'sn': s},
    );
    if (resp.statusCode == 404) {
      throw Exception('Número de série não encontrado no cadastro.');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      String msg = 'Erro ao consultar (${resp.statusCode})';
      try {
        final j = jsonDecode(resp.body);
        if (j is Map && j['detail'] != null) {
          msg = j['detail'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return RastreamentoSerialInfo.fromJson(data);
  }

  /// GET /api/estoque/rastreamento/catalogo/
  Future<List<RastreamentoSerialInfo>> listarCatalogo({
    String? search,
    int? clienteId,
    int limit = 100,
  }) async {
    final q = <String, dynamic>{'limit': limit};
    if (search != null && search.trim().isNotEmpty) {
      q['search'] = search.trim();
    }
    if (clienteId != null) {
      q['cliente'] = clienteId;
    }
    final resp = await _client.get('/api/estoque/rastreamento/catalogo/', query: q);
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar catálogo (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body);
    if (data is! List) return [];
    return data
        .map((e) => RastreamentoSerialInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/estoque/rastreamento/{id}/movimentacoes/
  Future<List<MovimentacaoRastreamentoItem>> listarMovimentacoes(
    int rastreamentoId, {
    int limit = 50,
  }) async {
    final resp = await _client.get(
      '/api/estoque/rastreamento/$rastreamentoId/movimentacoes/',
      query: {'limit': limit},
    );
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar histórico (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body);
    if (data is! List) return [];
    return data
        .map((e) =>
            MovimentacaoRastreamentoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/estoque/locais/?cliente=
  Future<List<LocalEstoqueItem>> listarLocais({int? clienteId}) async {
    final resp = await _client.get(
      '/api/estoque/locais/',
      query: clienteId != null ? {'cliente': clienteId} : null,
    );
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar locais (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body);
    if (data is! List) return [];
    return data
        .map((e) => LocalEstoqueItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/estoque/motivos-movimentacao/
  Future<List<MotivoMovimentacaoItem>> listarMotivos() async {
    final resp = await _client.get('/api/estoque/motivos-movimentacao/');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar motivos (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body);
    if (data is! List) return [];
    return data
        .map((e) => MotivoMovimentacaoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/estoque/rastreamento/{id}/movimentar/
  Future<RastreamentoSerialInfo> movimentar({
    required int rastreamentoId,
    required int motivoId,
    required String localDestino,
    String detalhes = '',
  }) async {
    final resp = await _client.post(
      '/api/estoque/rastreamento/$rastreamentoId/movimentar/',
      body: {
        'motivo': motivoId,
        'local_destino': localDestino.trim(),
        'detalhes': detalhes.trim(),
      },
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      String msg = 'Erro ao movimentar (${resp.statusCode})';
      try {
        final j = jsonDecode(resp.body);
        if (j is Map) {
          if (j['detail'] != null) {
            msg = j['detail'].toString();
          } else {
            for (final e in j.entries) {
              final v = e.value;
              if (v is List && v.isNotEmpty) {
                msg = v.first.toString();
                break;
              }
            }
          }
        }
      } catch (_) {}
      throw Exception(msg);
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final r = data['rastreamento'] as Map<String, dynamic>?;
    if (r == null) {
      throw Exception('Resposta inválida do servidor.');
    }
    return RastreamentoSerialInfo.fromJson(r);
  }
}
