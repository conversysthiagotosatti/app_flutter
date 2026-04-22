import 'dart:convert';

import 'api_client.dart';

class Chamado {
  final int id;
  final String titulo;
  final String status;
  final String prioridade;
  final String? descricao;
  final String criadoEm;
  final Map<String, dynamic>? solicitanteDetalhes;
  final Map<String, dynamic>? atendenteDetalhes;

  Chamado({
    required this.id,
    required this.titulo,
    required this.status,
    required this.prioridade,
    required this.criadoEm,
    this.descricao,
    this.solicitanteDetalhes,
    this.atendenteDetalhes,
  });

  factory Chamado.fromJson(Map<String, dynamic> json) {
    return Chamado(
      id: json['id'] as int,
      titulo: (json['titulo'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      prioridade: (json['prioridade'] ?? '') as String,
      criadoEm: (json['criado_em'] ?? '') as String,
      descricao: json['descricao'] as String?,
      solicitanteDetalhes:
          json['solicitante_detalhes'] as Map<String, dynamic>?,
      atendenteDetalhes:
          json['atendente_detalhes'] as Map<String, dynamic>?,
    );
  }
}

class HelpdeskChamadosService {
  final ApiClient apiClient;

  HelpdeskChamadosService(this.apiClient);

  Future<List<Map<String, dynamic>>> _listarEntidade(
    String entity, {
    Map<String, dynamic>? query,
  }) async {
    final resp = await apiClient.get(
      '/api/helpdesk/$entity/',
      query: query,
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao carregar $entity (${resp.statusCode})',
      );
    }
    final decoded = jsonDecode(resp.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['results'] is List) {
      list = decoded['results'] as List<dynamic>;
    } else {
      list = const [];
    }
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// Perfil do usuário logado (mesmo payload do portal: `tipo_usuario`, `memberships`, …).
  Future<Map<String, dynamic>> fetchAuthMe() async {
    final resp = await apiClient.get('/api/auth/me/');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar perfil (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida de /api/auth/me/');
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> listarGruposSolucao() =>
      _listarEntidade('grupos-solucao');

  Future<List<Map<String, dynamic>>> listarCategorias() =>
      _listarEntidade('categorias');

  Future<List<Map<String, dynamic>>> listarServicos() =>
      _listarEntidade('servicos');

  Future<List<Map<String, dynamic>>> listarTiposChamado() =>
      _listarEntidade('tipos-chamado');

  Future<List<Map<String, dynamic>>> listarAreas() =>
      _listarEntidade('areas');

  Future<List<Map<String, dynamic>>> listarImpactos() =>
      _listarEntidade('impactos');

  /// Contratos helpdesk; com [clienteConversysId] filtra como no portal (`HelpdeskNewTicketModal`).
  Future<List<Map<String, dynamic>>> listarContratosHd({
    int? clienteConversysId,
  }) async {
    final q = <String, dynamic>{};
    if (clienteConversysId != null) {
      q['cliente_conversys'] = clienteConversysId;
    }
    return _listarEntidade('contratos-hd', query: q.isEmpty ? null : q);
  }

  Future<List<Map<String, dynamic>>> listarTemplates() =>
      _listarEntidade('templates-chamado');

  Future<List<Map<String, dynamic>>> listarItensConfiguracao() =>
      _listarEntidade('itens-configuracao');

  Future<List<Chamado>> listar({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final resp = await apiClient.get(
      '/api/helpdesk/chamados/',
      query: query.isNotEmpty ? query : null,
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao carregar chamados (${resp.statusCode})',
      );
    }
    final decoded = jsonDecode(resp.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['results'] is List) {
      list = decoded['results'] as List<dynamic>;
    } else {
      list = const [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(Chamado.fromJson)
        .toList();
  }

  String _extractErrorMessage(String body) {
    if (body.isEmpty) return '';
    try {
      final j = jsonDecode(body);
      if (j is Map<String, dynamic>) {
        final d = j['detail'];
        if (d is String) return d;
        if (d is List) return d.map((e) => e.toString()).join(' ');
        return j.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('; ');
      }
    } catch (_) {}
    return body.length > 300 ? body.substring(0, 300) : body;
  }

  /// Cria chamado alinhado ao `createChamado` do portal (`HelpdeskNewTicketModal`).
  /// Usa `cliente_conversys` (ID de [clientes.Cliente]); o backend resolve `cliente_helpdesk`.
  Future<void> criar({
    required String titulo,
    String? descricao,
    int? grupoSolucaoId,
    String? prioridade,
    int? categoriaId,
    int? servicoId,
    int? tipoChamadoId,
    int? areaId,
    int? impactoId,
    int? clienteConversysId,
    int? contratoId,
    int? templateId,
    int? subclienteId,
    String? solicitanteNome,
  }) async {
    final body = <String, dynamic>{
      'titulo': titulo.trim(),
      'descricao': (descricao ?? '').trim(),
    };
    if (prioridade != null && prioridade.isNotEmpty) {
      body['prioridade'] = prioridade;
    }
    if (grupoSolucaoId != null) {
      body['grupo_solucao'] = grupoSolucaoId;
    }
    if (categoriaId != null) {
      body['categoria'] = categoriaId;
    }
    if (servicoId != null) {
      body['servico'] = servicoId;
    }
    if (tipoChamadoId != null) {
      body['tipo_chamado'] = tipoChamadoId;
    }
    if (areaId != null) {
      body['area'] = areaId;
    }
    if (impactoId != null) {
      body['impacto'] = impactoId;
    }
    if (clienteConversysId != null) {
      body['cliente_conversys'] = clienteConversysId;
    }
    if (contratoId != null) {
      body['contrato_helpdesk'] = contratoId;
    }
    if (templateId != null) {
      body['template'] = templateId;
    }
    if (subclienteId != null) {
      body['subcliente'] = subclienteId;
    }
    if (solicitanteNome != null && solicitanteNome.trim().isNotEmpty) {
      body['solicitante_nome'] = solicitanteNome.trim();
    }

    final resp = await apiClient.post(
      '/api/helpdesk/chamados/',
      body: body,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final msg = _extractErrorMessage(resp.body);
      throw Exception(
        msg.isEmpty
            ? 'Erro ao criar chamado (${resp.statusCode})'
            : 'Erro ao criar chamado (${resp.statusCode}): $msg',
      );
    }
  }
}
