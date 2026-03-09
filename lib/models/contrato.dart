import 'cliente.dart';

class Contrato {
  final int id;
  final Cliente cliente;
  final String titulo;
  final String? descricao;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final double horasPrevistasTotal;

  Contrato({
    required this.id,
    required this.cliente,
    required this.titulo,
    this.descricao,
    required this.dataInicio,
    this.dataFim,
    required this.horasPrevistasTotal,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final v = double.tryParse(value.replaceAll(',', '.'));
      return v ?? 0;
    }
    return 0;
  }

  factory Contrato.fromJson(Map<String, dynamic> json) {
    return Contrato(
      id: json['id'] as int,
      cliente: Cliente.fromJson(json['cliente'] is Map
          ? json['cliente'] as Map<String, dynamic>
          : {
              'id': json['cliente'],
              'nome': json['cliente_nome'] ?? '',
              'ativo': true,
            }),
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String?,
      dataInicio: DateTime.parse(json['data_inicio'] as String),
      dataFim: json['data_fim'] != null
          ? DateTime.parse(json['data_fim'] as String)
          : null,
      horasPrevistasTotal: _parseDouble(json['horas_previstas_total']),
    );
  }
}

