class PropostaProduto {
  final int id;
  final int proposta;
  final String nome;
  final num quantidade;
  final String valorUnitario;
  final String? valorTotal;
  final String? criadoEm;

  const PropostaProduto({
    required this.id,
    required this.proposta,
    required this.nome,
    required this.quantidade,
    required this.valorUnitario,
    this.valorTotal,
    this.criadoEm,
  });

  factory PropostaProduto.fromJson(Map<String, dynamic> json) {
    return PropostaProduto(
      id: (json['id'] as num).toInt(),
      proposta: (json['proposta'] as num).toInt(),
      nome: json['nome']?.toString() ?? '',
      quantidade: (json['quantidade'] as num),
      valorUnitario: json['valor_unitario']?.toString() ?? '0',
      valorTotal: json['valor_total']?.toString(),
      criadoEm: json['criado_em']?.toString(),
    );
  }
}

