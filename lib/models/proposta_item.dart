class PropostaItem {
  final int id;
  final int proposta;
  final int servico;
  final String? servicoNome;
  final num quantidade;
  final String precoUnitario;

  const PropostaItem({
    required this.id,
    required this.proposta,
    required this.servico,
    this.servicoNome,
    required this.quantidade,
    required this.precoUnitario,
  });

  factory PropostaItem.fromJson(Map<String, dynamic> json) {
    return PropostaItem(
      id: (json['id'] as num).toInt(),
      proposta: (json['proposta'] as num).toInt(),
      servico: (json['servico'] as num).toInt(),
      servicoNome: json['servico_nome']?.toString(),
      quantidade: (json['quantidade'] as num),
      precoUnitario: json['preco_unitario']?.toString() ?? '0',
    );
  }
}

