class Tarefa {
  final int id;
  final int contratoId;
  final String titulo;
  final String? descricao;
  final String status;
  final DateTime? dataInicioPrevista;
  final double horasPrevistas;
  final double horasConsumidas;

  Tarefa({
    required this.id,
    required this.contratoId,
    required this.titulo,
    this.descricao,
    required this.status,
    this.dataInicioPrevista,
    required this.horasPrevistas,
    required this.horasConsumidas,
  });

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      id: json['id'] as int,
      contratoId: json['contrato'] as int,
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String?,
      status: json['status'] as String? ?? '',
      dataInicioPrevista: json['data_inicio_prevista'] != null
          ? DateTime.parse(json['data_inicio_prevista'] as String)
          : null,
      horasPrevistas:
          (json['horas_previstas'] as num?)?.toDouble() ?? 0.0,
      horasConsumidas:
          (json['horas_consumidas'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

