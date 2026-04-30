import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/marketplace.dart';
import 'api_client.dart';

class MarketplaceException implements Exception {
  final String message;
  MarketplaceException(this.message);
  @override
  String toString() => message;
}

class MarketplaceService {
  final ApiClient apiClient;

  MarketplaceService(this.apiClient);

  List<dynamic> _decodeList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      return decoded['results'] as List<dynamic>;
    }
    return const [];
  }

  void _ensureOk(http.Response r, String action) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    var msg = action;
    try {
      final j = jsonDecode(r.body);
      if (j is Map && j['detail'] != null) {
        msg = '$action: ${j['detail']}';
      }
    } catch (_) {
      if (r.body.isNotEmpty) msg = '$action (${r.statusCode})';
    }
    throw MarketplaceException(msg);
  }

  Future<List<MarketplaceGrupo>> fetchGruposCatalogo() async {
    final r = await apiClient.get('/api/marketplace/grupos-catalogo/');
    _ensureOk(r, 'Erro ao carregar grupos');
    return _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceGrupo.fromJson)
        .toList();
  }

  Future<List<MarketplaceProduto>> fetchProdutosPorGrupo(int grupoId) async {
    final r = await apiClient.get(
      '/api/marketplace/catalogo-produtos/',
      query: {
        'grupo': grupoId,
        'ordering': 'subgrupo,descricao_curta',
      },
    );
    _ensureOk(r, 'Erro ao carregar produtos');
    return _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceProduto.fromJson)
        .toList();
  }

  Future<MarketplaceCestaItem> adquirirProduto({
    required int clienteId,
    required int catalogoProdutoId,
  }) async {
    final r = await apiClient.post(
      '/api/marketplace/cesta-cliente-itens/',
      body: {
        'cliente': clienteId,
        'catalogo_produto': catalogoProdutoId,
      },
    );
    _ensureOk(r, 'Erro ao adquirir produto');
    final j = jsonDecode(r.body);
    if (j is! Map<String, dynamic>) {
      throw MarketplaceException('Resposta inválida');
    }
    return MarketplaceCestaItem.fromJson(j);
  }

  Future<MarketplaceSaldoCliente?> fetchSaldoCliente(int clienteId) async {
    final r = await apiClient.get(
      '/api/marketplace/saldo-cliente/',
      query: {'cliente': clienteId},
    );
    _ensureOk(r, 'Erro ao carregar saldo');
    final list = _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceSaldoCliente.fromJson)
        .toList();
    return list.isEmpty ? null : list.first;
  }

  Future<List<MarketplaceMovimentacaoFinanceira>> fetchMovimentacoes(
    int clienteId,
  ) async {
    final r = await apiClient.get(
      '/api/marketplace/movimentacao-financeira-cliente/',
      query: {
        'cliente': clienteId,
        'ordering': '-criado_em',
      },
    );
    _ensureOk(r, 'Erro ao carregar movimentações');
    return _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceMovimentacaoFinanceira.fromJson)
        .toList();
  }

  Future<List<MarketplaceCestaItem>> fetchCestaItens(int clienteId) async {
    final r = await apiClient.get(
      '/api/marketplace/cesta-cliente-itens/',
      query: {
        'cliente': clienteId,
        'ordering': '-criado_em',
      },
    );
    _ensureOk(r, 'Erro ao carregar cesta');
    return _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceCestaItem.fromJson)
        .toList();
  }

  Future<MarketplaceMovimentacaoFinanceira> adicionarCredito({
    required int clienteId,
    required String valor,
    String descricao = '',
  }) async {
    final r = await apiClient.post(
      '/api/marketplace/movimentacao-financeira-cliente/',
      body: {
        'cliente': clienteId,
        'tipo': 'ENTRADA',
        'valor': valor,
        'descricao': descricao,
      },
    );
    _ensureOk(r, 'Erro ao adicionar crédito');
    final j = jsonDecode(r.body);
    if (j is! Map<String, dynamic>) {
      throw MarketplaceException('Resposta inválida');
    }
    return MarketplaceMovimentacaoFinanceira.fromJson(j);
  }
}
