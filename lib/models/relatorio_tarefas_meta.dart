class RelatorioTarefasMeta {
  final int id;
  final String nome;
  final String descricao;
  final String endpointApi;
  final bool ativo;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  RelatorioTarefasMeta({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.endpointApi,
    required this.ativo,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory RelatorioTarefasMeta.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return RelatorioTarefasMeta(
      id: json['id'] as int,
      nome: (json['nome'] ?? '') as String,
      descricao: (json['descricao'] ?? '') as String,
      endpointApi: (json['endpoint_api'] ?? '') as String,
      ativo: (json['ativo'] ?? true) as bool,
      criadoEm: parseDate(json['criado_em']),
      atualizadoEm: parseDate(json['atualizado_em']),
    );
  }
}

