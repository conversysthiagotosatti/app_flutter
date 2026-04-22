class MotivoMovimentacaoItem {
  final int id;
  final String nome;

  MotivoMovimentacaoItem({required this.id, required this.nome});

  factory MotivoMovimentacaoItem.fromJson(Map<String, dynamic> json) {
    return MotivoMovimentacaoItem(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
    );
  }
}
