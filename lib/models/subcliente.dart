class Subcliente {
  final int id;
  final String nome;
  final String cnpj;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Subcliente({
    required this.id,
    required this.nome,
    this.cnpj = '',
    this.criadoEm,
    this.atualizadoEm,
  });

  factory Subcliente.fromJson(Map<String, dynamic> json) {
    return Subcliente(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
      cnpj: json['cnpj'] as String? ?? '',
      criadoEm: _parseDate(json['criado_em']),
      atualizadoEm: _parseDate(json['atualizado_em']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }
}
