class ContratoTarefaLog {
  final int id;
  final int tarefa;
  final int? usuario;
  final String? usuarioNome;
  final String acao;
  final String? detalhe;
  final DateTime criadoEm;

  ContratoTarefaLog({
    required this.id,
    required this.tarefa,
    this.usuario,
    this.usuarioNome,
    required this.acao,
    this.detalhe,
    required this.criadoEm,
  });

  factory ContratoTarefaLog.fromJson(Map<String, dynamic> json) {
    return ContratoTarefaLog(
      id: json['id'] as int,
      tarefa: json['tarefa'] as int,
      usuario: json['usuario'] as int?,
      usuarioNome: json['usuario_nome'] as String?,
      acao: json['acao'] as String? ?? '',
      detalhe: json['detalhe'] as String?,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }
}

