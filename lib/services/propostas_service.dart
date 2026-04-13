import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/proposta.dart';
import '../models/proposta_anexo.dart';
import '../models/proposta_chat_message.dart';
import '../models/proposta_item.dart';
import '../models/proposta_produto.dart';
import '../models/proposta_resumo.dart';
import '../models/proposta_versao.dart';
import 'api_client.dart';

class PropostaServico {
  final int id;
  final String nome;
  final String descricao;
  final String categoria;
  final String precoBase;
  final bool ativo;

  const PropostaServico({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.precoBase,
    required this.ativo,
  });

  factory PropostaServico.fromJson(Map<String, dynamic> json) {
    return PropostaServico(
      id: (json['id'] as num).toInt(),
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      precoBase: json['preco_base']?.toString() ?? '0',
      ativo: (json['ativo'] as bool?) ?? false,
    );
  }
}

class PropostasCopilotSugestao {
  final int id;
  final int conversation;
  final int? servico;
  final String? servicoNome;
  final String titulo;
  final String descricao;
  final num? valorEstimado;
  final dynamic dadosContexto;
  final int? clienteId;
  final int? userId;
  final String criadoEm;

  const PropostasCopilotSugestao({
    required this.id,
    required this.conversation,
    required this.servico,
    required this.servicoNome,
    required this.titulo,
    required this.descricao,
    required this.valorEstimado,
    required this.dadosContexto,
    required this.clienteId,
    required this.userId,
    required this.criadoEm,
  });

  factory PropostasCopilotSugestao.fromJson(Map<String, dynamic> json) {
    return PropostasCopilotSugestao(
      id: (json['id'] as num).toInt(),
      conversation: (json['conversation'] as num).toInt(),
      servico: json['servico'] != null ? (json['servico'] as num).toInt() : null,
      servicoNome: json['servico_nome']?.toString(),
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      valorEstimado: json['valor_estimado'] as num?,
      dadosContexto: json['dados_contexto'],
      clienteId: json['cliente_id'] != null ? (json['cliente_id'] as num).toInt() : null,
      userId: json['user_id'] != null ? (json['user_id'] as num).toInt() : null,
      criadoEm: json['criado_em']?.toString() ?? '',
    );
  }
}

class PropostasService {
  final ApiClient _client;

  PropostasService(this._client);

  // Backend (padrão do front web) pode retornar array direto ou { results: [...] }.
  List<T> _unwrapList<T>(
    dynamic decoded,
    T Function(dynamic e) mapper,
  ) {
    if (decoded is List) {
      return decoded.map(mapper).toList();
    }
    if (decoded is Map && decoded['results'] is List) {
      return (decoded['results'] as List).map(mapper).toList();
    }
    return <T>[];
  }

  Future<List<PropostaResumo>> listarResumo() async {
    final resp = await _client.get('/api/propostas/');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar propostas (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body);
    return _unwrapList<PropostaResumo>(
      decoded,
      (e) => PropostaResumo.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<PropostaDetalhe> obterDetalhe(int propostaId) async {
    final resp = await _client.get('/api/propostas/$propostaId/');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar proposta (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    return PropostaDetalhe.fromJson(decoded);
  }

  Future<PropostaDetalhe> criarProposta({
    required int clienteId,
    required String titulo,
    String? descricao,
    String? descricaoTecnica,
    String? descricaoComercial,
    String? descricaoMemoriaCalculo,
    String? dataValidade,
    String tipoProposta = 'comercial',
    List<int>? parceiros,
    List<Map<String, dynamic>>? responsaveis,
    String? codigoInterno,
  }) async {
    final resp = await _client.post(
      '/api/propostas/',
      body: {
        'cliente': clienteId,
        'titulo': titulo,
        'descricao': descricao ?? '',
        'descricao_tecnica': descricaoTecnica ?? '',
        'descricao_comercial': descricaoComercial ?? '',
        'descricao_memoria_calculo': descricaoMemoriaCalculo ?? '',
        'data_validade': dataValidade,
        'tipo_proposta': tipoProposta,
        'parceiros': parceiros ?? [],
        'responsaveis': responsaveis ?? [],
        'codigo_interno': codigoInterno,
      },
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao criar proposta (${resp.statusCode})');
    }

    return PropostaDetalhe.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<PropostaDetalhe> atualizarProposta(
    int propostaId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _client.patch(
      '/api/propostas/$propostaId/',
      body: data,
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao atualizar proposta (${resp.statusCode})');
    }

    return PropostaDetalhe.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<void> excluirProposta(int propostaId) async {
    final resp = await _client.delete('/api/propostas/$propostaId/');
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao excluir proposta (${resp.statusCode})');
    }
  }

  Future<PropostaDetalhe> fecharPropostaContrato(int propostaId) async {
    final resp = await _client.post(
      '/api/propostas/$propostaId/fechar-contrato/',
      body: const {},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao fechar contrato da proposta (${resp.statusCode})');
    }
    return PropostaDetalhe.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<PropostaDetalhe> rejeitarProposta(int propostaId) async {
    final resp = await _client.post(
      '/api/propostas/$propostaId/rejeitar-proposta/',
      body: const {},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao rejeitar proposta (${resp.statusCode})');
    }
    return PropostaDetalhe.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<List<PropostaChatMessage>> listarChat(int propostaId) async {
    final resp = await _client.get('/api/propostas/$propostaId/chat/');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar chat da proposta (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body);
    return _unwrapList<PropostaChatMessage>(
      decoded,
      (e) => PropostaChatMessage.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<PropostaChatMessage> enviarChat({
    required int propostaId,
    required String tipo,
    required String conteudo,
  }) async {
    final resp = await _client.post(
      '/api/propostas/$propostaId/chat/',
      body: {'tipo': tipo, 'conteudo': conteudo},
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao enviar mensagem (${resp.statusCode})');
    }

    return PropostaChatMessage.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<List<PropostaVersao>> listarVersoes(int propostaId) async {
    final resp = await _client.get('/api/propostas/$propostaId/versoes/');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar versões (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body);
    return _unwrapList<PropostaVersao>(
      decoded,
      (e) => PropostaVersao.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<PropostaVersao> gerarVersao(int propostaId) async {
    final resp = await _client.post(
      '/api/propostas/$propostaId/gerar-versao/',
      body: const {},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao gerar versão (${resp.statusCode})');
    }
    return PropostaVersao.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<List<PropostaAnexo>> listarAnexos(int propostaId) async {
    // Muitos endpoints do front web retornam anexos embutidos no detalhe,
    // mas mantemos este método para casos em que o backend expõe lista.
    final resp = await _client.get('/api/propostas/$propostaId/');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar anexos (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final detalhe = PropostaDetalhe.fromJson(decoded);
    return detalhe.anexos ?? const [];
  }

  Future<PropostaAnexo> uploadAnexo({
    required int propostaId,
    required PlatformFile arquivo,
    int? institucionalId,
    int? parceiroId,
  }) async {
    if (arquivo.bytes == null && !kIsWeb) {
      // Em mobile normalmente vem path; se não vier, falha cedo.
      if (arquivo.path == null) {
        throw Exception('Arquivo não possui bytes/path disponíveis.');
      }
    }

    final uri = Uri.parse('${ApiClient.baseUrl}/api/propostas-anexos/');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _client.buildAuthHeaders(json: false);
    request.headers.addAll(headers);

    request.fields['proposta'] = propostaId.toString();
    if (institucionalId != null) {
      request.fields['institucional'] = institucionalId.toString();
    }
    if (parceiroId != null) {
      request.fields['parceiro'] = parceiroId.toString();
    }

    final contentType = _inferMediaType(arquivo.name);
    if (kIsWeb) {
      final bytes = arquivo.bytes;
      if (bytes == null) {
        throw Exception('Não foi possível ler bytes do arquivo (web).');
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivo',
          bytes,
          filename: arquivo.name,
          contentType: contentType,
        ),
      );
    } else {
      final path = arquivo.path;
      if (path == null) {
        throw Exception('Caminho do arquivo não disponível (mobile).');
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          'arquivo',
          path,
          filename: arquivo.name,
          contentType: contentType,
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao enviar anexo (${response.statusCode})');
    }

    return PropostaAnexo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> excluirAnexo(int anexoId) async {
    final resp = await _client.delete('/api/propostas-anexos/$anexoId/');
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao excluir anexo (${resp.statusCode})');
    }
  }

  Future<List<PropostaServico>> listarServicos() async {
    final resp = await _client.get('/api/propostas/servicos/');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar serviços (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body);
    return _unwrapList<PropostaServico>(
      decoded,
      (e) => PropostaServico.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<PropostaItem> criarItem({
    required int propostaId,
    required int servicoId,
    required num quantidade,
    required String precoUnitario,
  }) async {
    final resp = await _client.post(
      '/api/propostas-itens/',
      body: {
        'proposta': propostaId,
        'servico': servicoId,
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
      },
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao criar item (${resp.statusCode})');
    }
    return PropostaItem.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<PropostaProduto> criarProduto({
    required int propostaId,
    required String nome,
    required num quantidade,
    required String valorUnitario,
  }) async {
    final resp = await _client.post(
      '/api/propostas-produtos/',
      body: {
        'proposta': propostaId,
        'nome': nome,
        'quantidade': quantidade,
        'valor_unitario': valorUnitario,
      },
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao criar produto (${resp.statusCode})');
    }
    return PropostaProduto.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<List<PropostasCopilotSugestao>> buscarSugestoesCopilot({
    int? clienteId,
  }) async {
    final query = clienteId != null ? '?cliente=$clienteId' : '';
    final resp = await _client.get('/api/propostas-copilot/sugestoes/$query');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao buscar sugestões do Copilot (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body);
    return _unwrapList<PropostasCopilotSugestao>(
      decoded,
      (e) => PropostasCopilotSugestao.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<String> perguntarCopilot({
    required int? clienteId,
    required String mensagem,
  }) async {
    final resp = await _client.post(
      '/api/propostas-copilot/',
      body: {
        'mensagem': mensagem,
        'cliente_id': clienteId,
      },
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao consultar Copilot de Propostas (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    return decoded['answer']?.toString() ?? '';
  }
}

MediaType _inferMediaType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  }
  if (lower.endsWith('.docx')) return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
  if (lower.endsWith('.doc')) return MediaType('application', 'msword');
  return MediaType('application', 'octet-stream');
}

