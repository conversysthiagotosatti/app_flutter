import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/assets_conversys.dart';
import 'api_client.dart';

class AssetsConversysException implements Exception {
  final String message;
  AssetsConversysException(this.message);
  @override
  String toString() => message;
}

/// Controle de assets (`/api/assets-conversys/*`), alinhado ao portal `api.ts`.
class AssetsConversysService {
  final ApiClient apiClient;

  AssetsConversysService(this.apiClient);

  String _clienteQ(int clienteId) => '?cliente=${Uri.encodeComponent('$clienteId')}';

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
    throw AssetsConversysException(msg);
  }

  Future<List<ProdutoConversys>> fetchProdutos(int clienteId) async {
    final r = await apiClient.get(
      '/api/assets-conversys/produtos/${_clienteQ(clienteId)}',
    );
    _ensureOk(r, 'Erro ao carregar produtos');
    return _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(ProdutoConversys.fromJson)
        .toList();
  }

  Future<ProdutoConversys> createProduto(
    int clienteId, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
  }) async {
    late http.Response r;
    if (files.isEmpty) {
      final body = <String, dynamic>{};
      for (final e in fields.entries) {
        if (e.key == 'ativo') {
          body[e.key] = e.value == 'true';
        } else {
          body[e.key] = e.value;
        }
      }
      r = await apiClient.post(
        '/api/assets-conversys/produtos/${_clienteQ(clienteId)}',
        body: body,
      );
    } else {
      r = await apiClient.postMultipart(
        '/api/assets-conversys/produtos/${_clienteQ(clienteId)}',
        fields: fields,
        files: files,
      );
    }
    _ensureOk(r, 'Erro ao criar produto');
    final j = jsonDecode(r.body);
    if (j is! Map<String, dynamic>) {
      throw AssetsConversysException('Resposta inválida');
    }
    return ProdutoConversys.fromJson(j);
  }

  Future<ProdutoConversys> patchProduto(
    int clienteId,
    int id, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final r = await apiClient.patchMultipart(
      '/api/assets-conversys/produtos/$id/${_clienteQ(clienteId)}',
      fields: fields,
      files: files,
    );
    _ensureOk(r, 'Erro ao atualizar produto');
    final j = jsonDecode(r.body);
    if (j is! Map<String, dynamic>) {
      throw AssetsConversysException('Resposta inválida');
    }
    return ProdutoConversys.fromJson(j);
  }

  Future<List<AssetConversys>> fetchAssets(
    int clienteId, {
    int? produtoId,
  }) async {
    var path = '/api/assets-conversys/assets/${_clienteQ(clienteId)}';
    if (produtoId != null) {
      path += '&produto=${Uri.encodeComponent('$produtoId')}';
    }
    final r = await apiClient.get(path);
    _ensureOk(r, 'Erro ao carregar ativos');
    return _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(AssetConversys.fromJson)
        .toList();
  }

  Future<AssetConversys> createAsset(
    int clienteId,
    Map<String, dynamic> body,
  ) async {
    final r = await apiClient.post(
      '/api/assets-conversys/assets/${_clienteQ(clienteId)}',
      body: body,
    );
    _ensureOk(r, 'Erro ao criar ativo');
    final j = jsonDecode(r.body);
    if (j is! Map<String, dynamic>) {
      throw AssetsConversysException('Resposta inválida');
    }
    return AssetConversys.fromJson(j);
  }

  Future<AssetConversys> patchAsset(
    int clienteId,
    int id,
    Map<String, dynamic> body,
  ) async {
    final r = await apiClient.patch(
      '/api/assets-conversys/assets/$id/${_clienteQ(clienteId)}',
      body: body,
    );
    _ensureOk(r, 'Erro ao atualizar ativo');
    final j = jsonDecode(r.body);
    if (j is! Map<String, dynamic>) {
      throw AssetsConversysException('Resposta inválida');
    }
    return AssetConversys.fromJson(j);
  }

  Future<List<MovimentacaoAssetConversys>> fetchMovimentacoes(
    int clienteId, {
    int? assetId,
  }) async {
    var path = '/api/assets-conversys/movimentacoes/${_clienteQ(clienteId)}';
    if (assetId != null) {
      path += '&asset=${Uri.encodeComponent('$assetId')}';
    }
    final r = await apiClient.get(path);
    _ensureOk(r, 'Erro ao carregar movimentações');
    return _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(MovimentacaoAssetConversys.fromJson)
        .toList();
  }

  Future<MovimentacaoAssetConversys> createMovimentacao(
    int clienteId,
    Map<String, dynamic> body,
  ) async {
    final r = await apiClient.post(
      '/api/assets-conversys/movimentacoes/${_clienteQ(clienteId)}',
      body: body,
    );
    _ensureOk(r, 'Erro ao registrar movimentação');
    final j = jsonDecode(r.body);
    if (j is! Map<String, dynamic>) {
      throw AssetsConversysException('Resposta inválida');
    }
    return MovimentacaoAssetConversys.fromJson(j);
  }

  Future<List<MotivoMovimentacaoMini>> fetchMotivosMovimentacao() async {
    final r = await apiClient.get('/api/estoque/motivos-movimentacao/');
    _ensureOk(r, 'Erro ao carregar motivos');
    return _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(MotivoMovimentacaoMini.fromJson)
        .toList();
  }

  Future<List<LocalEstoqueRow>> fetchLocaisEstoque(int clienteId) async {
    final r = await apiClient.get(
      '/api/estoque/locais/',
      query: {'cliente': clienteId},
    );
    _ensureOk(r, 'Erro ao carregar locais');
    return _decodeList(r.body)
        .whereType<Map<String, dynamic>>()
        .map(LocalEstoqueRow.fromJson)
        .where((l) => l.ativo)
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }
}
