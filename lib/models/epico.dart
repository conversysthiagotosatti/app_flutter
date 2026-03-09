class Epico {
  final int id;
  final int contrato;
  final String titulo;
  final String? descricao;
  final String status;

  Epico({
    required this.id,
    required this.contrato,
    required this.titulo,
    this.descricao,
    required this.status,
  });

  factory Epico.fromJson(Map<String, dynamic> json) {
    return Epico(
      id: json['id'] as int,
      contrato: json['contrato'] as int,
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String?,
      status: json['status'] as String? ?? 'ABERTO',
    );
  }
}

