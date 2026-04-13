class PropostaChatMessage {
  final int id;
  final String tipo; // alteracao | aceite | comentario
  final String conteudo;
  final String criadoEm;
  final String autorTipo; // interno | externo
  final String autorNome;

  const PropostaChatMessage({
    required this.id,
    required this.tipo,
    required this.conteudo,
    required this.criadoEm,
    required this.autorTipo,
    required this.autorNome,
  });

  factory PropostaChatMessage.fromJson(Map<String, dynamic> json) {
    return PropostaChatMessage(
      id: (json['id'] as num).toInt(),
      tipo: json['tipo']?.toString() ?? '',
      conteudo: json['conteudo']?.toString() ?? '',
      criadoEm: json['criado_em']?.toString() ?? '',
      autorTipo: json['autor_tipo']?.toString() ?? '',
      autorNome: json['autor_nome']?.toString() ?? '',
    );
  }
}

