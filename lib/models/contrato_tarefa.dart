class ContratoTarefa {
  final int id;
  final int contrato;
  final int? clausula;
  final int? epico;
  final String? epicoTitulo;
  final String titulo;
  final String? descricao;
  final String? responsavelSugerido;
  final String? prioridade;
  final int? prazoDiasSugerido;
  final DateTime? dataInicioPrevista;
  final double? horasPrevistas;
  final String status;
  final bool geradaPorIa;
  final int? usuarioResponsavel;
  final int? usuarioCriador;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  ContratoTarefa({
    required this.id,
    required this.contrato,
    this.clausula,
    this.epico,
    this.epicoTitulo,
    required this.titulo,
    this.descricao,
    this.responsavelSugerido,
    this.prioridade,
    this.prazoDiasSugerido,
    this.dataInicioPrevista,
    this.horasPrevistas,
    required this.status,
    required this.geradaPorIa,
    this.usuarioResponsavel,
    this.usuarioCriador,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final v = double.tryParse(value.replaceAll(',', '.'));
      return v;
    }
    return null;
  }

  factory ContratoTarefa.fromJson(Map<String, dynamic> json) {
    return ContratoTarefa(
      id: json['id'] as int,
      contrato: json['contrato'] as int,
      clausula: json['clausula'] as int?,
      epico: json['epico'] as int?,
      epicoTitulo: json['epico_titulo'] as String?,
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String?,
      responsavelSugerido: json['responsavel_sugerido'] as String?,
      prioridade: json['prioridade'] as String?,
      prazoDiasSugerido: json['prazo_dias_sugerido'] as int?,
      dataInicioPrevista: json['data_inicio_prevista'] != null
          ? DateTime.parse(json['data_inicio_prevista'] as String)
          : null,
      horasPrevistas: _parseDouble(json['horas_previstas']),
      status: json['status'] as String? ?? '',
      geradaPorIa: json['gerada_por_ia'] as bool? ?? false,
      usuarioResponsavel: json['usuario_responsavel'] as int?,
      usuarioCriador: json['usuario_criador'] as int?,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: DateTime.parse(json['atualizado_em'] as String),
    );
  }
}

