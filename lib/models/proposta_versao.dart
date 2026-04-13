class PropostaVersao {
  final int id;
  final int proposta;
  final int versao;
  final dynamic snapshotJson;
  final String criadoEm;

  const PropostaVersao({
    required this.id,
    required this.proposta,
    required this.versao,
    required this.snapshotJson,
    required this.criadoEm,
  });

  factory PropostaVersao.fromJson(Map<String, dynamic> json) {
    return PropostaVersao(
      id: (json['id'] as num).toInt(),
      proposta: (json['proposta'] as num).toInt(),
      versao: (json['versao'] as num).toInt(),
      snapshotJson: json['snapshot_json'],
      criadoEm: json['criado_em']?.toString() ?? '',
    );
  }
}

