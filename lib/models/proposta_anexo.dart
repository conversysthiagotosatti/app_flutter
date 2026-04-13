class PropostaAnexo {
  final int id;
  final int proposta;
  final int? institucional;
  final int? parceiro;
  final String? arquivo;
  final String criadoEm;
  final String? institucionalTitulo;
  final String? parceiroNome;

  const PropostaAnexo({
    required this.id,
    required this.proposta,
    required this.institucional,
    required this.parceiro,
    required this.arquivo,
    required this.criadoEm,
    this.institucionalTitulo,
    this.parceiroNome,
  });

  factory PropostaAnexo.fromJson(Map<String, dynamic> json) {
    return PropostaAnexo(
      id: (json['id'] as num).toInt(),
      proposta: (json['proposta'] as num).toInt(),
      institucional: json['institucional'] != null
          ? (json['institucional'] as num).toInt()
          : null,
      parceiro: json['parceiro'] != null
          ? (json['parceiro'] as num).toInt()
          : null,
      arquivo: json['arquivo']?.toString(),
      criadoEm: json['criado_em']?.toString() ?? '',
      institucionalTitulo: json['institucional_titulo']?.toString(),
      parceiroNome: json['parceiro_nome']?.toString(),
    );
  }
}

