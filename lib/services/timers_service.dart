import 'dart:convert';

import 'api_client.dart';

class TimerApontamento {
  final int id;
  final int tarefa;
  final String tarefaTitulo;
  final int contratoId;
  final String contratoTitulo;
  final int usuario;
  final String usuarioNome;
  final String? iniciadoEm;
  final String? finalizadoEm;
  final double horas;
  final String? data;

  TimerApontamento({
    required this.id,
    required this.tarefa,
    required this.tarefaTitulo,
    required this.contratoId,
    required this.contratoTitulo,
    required this.usuario,
    required this.usuarioNome,
    required this.horas,
    this.iniciadoEm,
    this.finalizadoEm,
    this.data,
  });

  factory TimerApontamento.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) {
        return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      }
      return 0;
    }

    return TimerApontamento(
      id: json['id'] as int,
      tarefa: json['tarefa'] as int,
      tarefaTitulo: (json['tarefa_titulo'] ?? '') as String,
      contratoId: json['contrato_id'] as int? ?? 0,
      contratoTitulo: (json['contrato_titulo'] ?? '') as String,
      usuario: json['usuario'] as int,
      usuarioNome: (json['usuario_nome'] ?? '') as String,
      horas: toDouble(json['horas']),
      iniciadoEm: json['iniciado_em'] as String?,
      finalizadoEm: json['finalizado_em'] as String?,
      data: json['data'] as String?,
    );
  }
}

class TimersService {
  final ApiClient apiClient;

  TimersService(this.apiClient);

  Future<List<TimerApontamento>> listar({
    int? contrato,
    int? tarefa,
    int? usuario,
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final query = <String, String>{};
    if (contrato != null) query['contrato'] = contrato.toString();
    if (tarefa != null) query['tarefa'] = tarefa.toString();
    if (usuario != null) query['usuario'] = usuario.toString();
    if (inicio != null) {
      query['data_inicio'] =
          '${inicio.year.toString().padLeft(4, '0')}-${inicio.month.toString().padLeft(2, '0')}-${inicio.day.toString().padLeft(2, '0')}';
    }
    if (fim != null) {
      query['data_fim'] =
          '${fim.year.toString().padLeft(4, '0')}-${fim.month.toString().padLeft(2, '0')}-${fim.day.toString().padLeft(2, '0')}';
    }

    final resp = await apiClient.get(
      '/api/contratos-timers/',
      query: query.isNotEmpty ? query : null,
    );
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar apontamentos (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body);
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      list = decoded['results'] as List<dynamic>;
    } else {
      list = const [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(TimerApontamento.fromJson)
        .toList();
  }

  Future<void> lancarHorasManual({
    required int tarefaId,
    required double horas,
    String? descricao,
    DateTime? data,
    String? horaInicio,
  }) async {
    final body = <String, dynamic>{
      'horas': horas,
      'descricao': descricao ?? '',
      'data': data != null
          ? '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}'
          : null,
      'hora_inicio': horaInicio,
    };

    final resp = await apiClient.post(
      '/api/contratos-tarefas/$tarefaId/timer/manual/',
      body: body,
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Erro ao lançar horas (${resp.statusCode})');
    }
  }
}
