class RastreamentoSerialInfo {
  final int id;
  final String numeroSerial;
  final int? clienteId;
  final String? clienteNome;
  final int? subclienteId;
  final String? subclienteNome;
  final String unidadeEstoque;
  final String observacoes;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  RastreamentoSerialInfo({
    required this.id,
    required this.numeroSerial,
    this.clienteId,
    this.clienteNome,
    this.subclienteId,
    this.subclienteNome,
    required this.unidadeEstoque,
    required this.observacoes,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory RastreamentoSerialInfo.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? cliente;
    if (json['cliente'] is Map) {
      cliente = json['cliente'] as Map<String, dynamic>;
    }
    Map<String, dynamic>? sub;
    if (json['subcliente'] is Map) {
      sub = json['subcliente'] as Map<String, dynamic>;
    }
    return RastreamentoSerialInfo(
      id: json['id'] as int,
      numeroSerial: json['numero_serial'] as String? ?? '',
      clienteId: cliente?['id'] as int?,
      clienteNome: cliente?['nome'] as String?,
      subclienteId: sub?['id'] as int?,
      subclienteNome: sub?['nome'] as String?,
      unidadeEstoque: json['unidade_estoque'] as String? ?? '',
      observacoes: json['observacoes'] as String? ?? '',
      criadoEm: _parse(json['criado_em']),
      atualizadoEm: _parse(json['atualizado_em']),
    );
  }

  static DateTime? _parse(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
