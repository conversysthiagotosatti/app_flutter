class MovimentacaoRastreamentoItem {
  final int id;
  final String motivoNome;
  final String localOrigem;
  final String localDestino;
  final String detalhes;
  final DateTime? criadoEm;
  final String? criadoPorNome;

  MovimentacaoRastreamentoItem({
    required this.id,
    required this.motivoNome,
    required this.localOrigem,
    required this.localDestino,
    required this.detalhes,
    this.criadoEm,
    this.criadoPorNome,
  });

  factory MovimentacaoRastreamentoItem.fromJson(Map<String, dynamic> json) {
    String motivoNome = '';
    final m = json['motivo'];
    if (m is Map && m['nome'] is String) {
      motivoNome = m['nome'] as String;
    }
    return MovimentacaoRastreamentoItem(
      id: json['id'] as int,
      motivoNome: motivoNome,
      localOrigem: json['local_origem'] as String? ?? '',
      localDestino: json['local_destino'] as String? ?? '',
      detalhes: json['detalhes'] as String? ?? '',
      criadoEm: _parse(json['criado_em']),
      criadoPorNome: json['criado_por_nome'] as String?,
    );
  }

  static DateTime? _parse(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
