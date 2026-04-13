class PropostaResumo {
  final int id;
  final int cliente;
  final String? clienteNome;
  final String? codigoInterno;
  final String titulo;
  final String descricao;
  final String valorTotal;
  final String status;
  final String? dataValidade;
  final String? criadoEm;

  const PropostaResumo({
    required this.id,
    required this.cliente,
    this.clienteNome,
    this.codigoInterno,
    required this.titulo,
    required this.descricao,
    required this.valorTotal,
    required this.status,
    this.dataValidade,
    this.criadoEm,
  });

  factory PropostaResumo.fromJson(Map<String, dynamic> json) {
    return PropostaResumo(
      id: (json['id'] as num).toInt(),
      cliente: (json['cliente'] as num).toInt(),
      clienteNome: json['cliente_nome']?.toString(),
      codigoInterno: json['codigo_interno']?.toString(),
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      valorTotal: json['valor_total']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      dataValidade: json['data_validade']?.toString(),
      criadoEm: json['criado_em']?.toString(),
    );
  }
}

