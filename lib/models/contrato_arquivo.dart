class ContratoArquivo {
  final int id;
  final int contrato;
  final String tipo;
  final int versao;
  final String nomeOriginal;
  final String? mimeType;
  final int? tamanhoBytes;
  final String? sha256;
  final String? url;
  final DateTime? extraidoEm;

  ContratoArquivo({
    required this.id,
    required this.contrato,
    required this.tipo,
    required this.versao,
    required this.nomeOriginal,
    this.mimeType,
    this.tamanhoBytes,
    this.sha256,
    this.url,
    this.extraidoEm,
  });

  factory ContratoArquivo.fromJson(Map<String, dynamic> json) {
    return ContratoArquivo(
      id: json['id'] as int,
      contrato: json['contrato'] as int,
      tipo: json['tipo'] as String? ?? '',
      versao: json['versao'] as int? ?? 1,
      nomeOriginal: json['nome_original'] as String? ?? '',
      mimeType: json['mime_type'] as String?,
      tamanhoBytes: json['tamanho_bytes'] as int?,
      sha256: json['sha256'] as String?,
      url: json['url'] as String?,
      extraidoEm: json['extraido_em'] != null
          ? DateTime.parse(json['extraido_em'] as String)
          : null,
    );
  }
}

