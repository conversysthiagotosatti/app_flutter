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

  Future<List<Map<String, dynamic>>> _listarEntidade(String entity) async {
    final resp = await apiClient.get('/api/helpdesk/$entity/');
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

  Future<List<Map<String, dynamic>>> listarClientesHd() =>
      _listarEntidade('clientes-hd');

  Future<List<Map<String, dynamic>>> listarContratosHd() =>
      _listarEntidade('contratos-hd');

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
    int? clienteId,
    int? contratoId,
    int? templateId,
    int? itemConfiguracaoId,
    String? solicitanteNome,
  }) async {
    final body = <String, dynamic>{
      'titulo': titulo.trim(),
    };
    if (descricao != null && descricao.trim().isNotEmpty) {
      body['descricao'] = descricao.trim();
    }
    if (grupoSolucaoId != null) {
      body['grupo_solucao'] = grupoSolucaoId;
    }
    if (prioridade != null && prioridade.isNotEmpty) {
      body['prioridade'] = prioridade;
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
    if (clienteId != null) {
      body['cliente_helpdesk'] = clienteId;
    }
    if (contratoId != null) {
      body['contrato_helpdesk'] = contratoId;
    }
    if (templateId != null) {
      body['template'] = templateId;
    }
    if (itemConfiguracaoId != null) {
      body['item_configuracao'] = itemConfiguracaoId;
    }
    if (solicitanteNome != null && solicitanteNome.trim().isNotEmpty) {
      body['solicitante_nome'] = solicitanteNome.trim();
    }

    final resp = await apiClient.post(
      '/api/helpdesk/chamados/',
      body: body,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'Erro ao criar chamado (${resp.statusCode})',
      );
    }
  }
}

