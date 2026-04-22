class LocalEstoqueItem {
  final int id;
  final int clienteId;
  final String nome;
  final String codigo;

  LocalEstoqueItem({
    required this.id,
    required this.clienteId,
    required this.nome,
    this.codigo = '',
  });

  factory LocalEstoqueItem.fromJson(Map<String, dynamic> json) {
    return LocalEstoqueItem(
      id: json['id'] as int,
      clienteId: json['cliente_id'] as int? ?? 0,
      nome: json['nome'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
    );
  }
}
