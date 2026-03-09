import 'dart:convert';

import '../models/contrato_arquivo.dart';
import 'api_client.dart';

class ContratoArquivosService {
  final ApiClient _client;

  ContratoArquivosService(this._client);

  Future<List<ContratoArquivo>> listar(int contratoId) async {
    final response = await _client.get(
      '/api/contratos-arquivos/',
      query: {'contrato': contratoId},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => ContratoArquivo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    throw Exception(
      'Erro ao carregar documentos (${response.statusCode})',
    );
  }

  Future<void> gerarPdfVersao(int contratoId,
      {String tipo = 'CONTRATO_PRINCIPAL'}) async {
    final response = await _client.post(
      '/api/contratos/$contratoId/gerar-pdf-versao/',
      body: {'tipo': tipo},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao gerar PDF (${response.statusCode})',
      );
    }
  }
}

