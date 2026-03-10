import 'dart:convert';

import 'api_client.dart';

class HelpdeskResumo {
  final int total;
  final int abertos;
  final int emAtendimento;
  final int aguardando;
  final int resolvidos;
  final int cancelados;
  final double slaCompliance;
  final int slaVencido;
  final int slaProximoVencer;
  final double? tempoMedioResolucaoHoras;
  final int semAtendente;
  final List<Map<String, dynamic>> porPrioridade;
  final List<Map<String, dynamic>> porStatus;

  HelpdeskResumo({
    required this.total,
    required this.abertos,
    required this.emAtendimento,
    required this.aguardando,
    required this.resolvidos,
    required this.cancelados,
    required this.slaCompliance,
    required this.slaVencido,
    required this.slaProximoVencer,
    required this.tempoMedioResolucaoHoras,
    required this.semAtendente,
    required this.porPrioridade,
    required this.porStatus,
  });

  factory HelpdeskResumo.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    List<Map<String, dynamic>> _toListMap(dynamic v) {
      if (v is List) {
        return v.whereType<Map<String, dynamic>>().toList();
      }
      return const [];
    }

    return HelpdeskResumo(
      total: json['total'] as int? ?? 0,
      abertos: json['abertos'] as int? ?? 0,
      emAtendimento: json['em_atendimento'] as int? ?? 0,
      aguardando: json['aguardando'] as int? ?? 0,
      resolvidos: json['resolvidos'] as int? ?? 0,
      cancelados: json['cancelados'] as int? ?? 0,
      slaCompliance: _toDouble(json['sla_compliance']),
      slaVencido: json['sla_vencido'] as int? ?? 0,
      slaProximoVencer: json['sla_proximo_vencer'] as int? ?? 0,
      tempoMedioResolucaoHoras:
          json['tempo_medio_resolucao_horas'] != null
              ? _toDouble(json['tempo_medio_resolucao_horas'])
              : null,
      semAtendente: json['sem_atendente'] as int? ?? 0,
      porPrioridade: _toListMap(json['por_prioridade']),
      porStatus: _toListMap(json['por_status']),
    );
  }
}

class ProblemaRecorrente {
  final String cliente;
  final String categoria;
  final int total;

  ProblemaRecorrente({
    required this.cliente,
    required this.categoria,
    required this.total,
  });

  factory ProblemaRecorrente.fromJson(Map<String, dynamic> json) {
    return ProblemaRecorrente(
      cliente: (json['cliente_helpdesk__razao_social'] ?? '') as String,
      categoria: (json['categoria__nome'] ?? '') as String,
      total: json['total'] as int? ?? 0,
    );
  }
}

class HelpdeskDashboardService {
  final ApiClient apiClient;

  HelpdeskDashboardService(this.apiClient);

  Future<HelpdeskResumo> fetchResumo() async {
    final resp =
        await apiClient.get('/api/helpdesk/dashboard/resumo/');
    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao carregar dashboard de helpdesk (${resp.statusCode})',
      );
    }
    final data =
        jsonDecode(resp.body) as Map<String, dynamic>;
    return HelpdeskResumo.fromJson(data);
  }

  Future<List<ProblemaRecorrente>> fetchRecorrentes() async {
    final resp = await apiClient.get(
      '/api/helpdesk/dashboard/problemas_recorrentes/',
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao carregar problemas recorrentes (${resp.statusCode})',
      );
    }
    final data = jsonDecode(resp.body);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ProblemaRecorrente.fromJson)
          .toList();
    }
    return const [];
  }
}

