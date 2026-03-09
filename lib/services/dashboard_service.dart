import 'dart:convert';

import 'api_client.dart';

class DashboardExecutivoKpis {
  final int contratosTotal;
  final double horasPrevistasTotal;
  final double horasApontadasTotal;

  DashboardExecutivoKpis({
    required this.contratosTotal,
    required this.horasPrevistasTotal,
    required this.horasApontadasTotal,
  });

  factory DashboardExecutivoKpis.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    return DashboardExecutivoKpis(
      contratosTotal: json['contratos_total'] as int? ?? 0,
      horasPrevistasTotal: _toDouble(json['horas_previstas_total']),
      horasApontadasTotal: _toDouble(json['horas_apontadas_total']),
    );
  }
}

class DashboardOperacionalKpis {
  final int contratosAtivos;
  final int contratosTotal;
  final int contratosVencendo30Dias;
  final int tarefasTotal;
  final int tarefasAtrasadasEstimada;

  DashboardOperacionalKpis({
    required this.contratosAtivos,
    required this.contratosTotal,
    required this.contratosVencendo30Dias,
    required this.tarefasTotal,
    required this.tarefasAtrasadasEstimada,
  });

  factory DashboardOperacionalKpis.fromJson(Map<String, dynamic> json) {
    return DashboardOperacionalKpis(
      contratosAtivos: json['contratos_ativos'] as int? ?? 0,
      contratosTotal: json['contratos_total'] as int? ?? 0,
      contratosVencendo30Dias:
          json['contratos_vencendo_30_dias'] as int? ?? 0,
      tarefasTotal: json['tarefas_total'] as int? ?? 0,
      tarefasAtrasadasEstimada:
          json['tarefas_atrasadas_estimada'] as int? ?? 0,
    );
  }
}

class DashboardExecutivoData {
  final DashboardExecutivoKpis kpis;

  DashboardExecutivoData({required this.kpis});

  factory DashboardExecutivoData.fromJson(Map<String, dynamic> json) {
    return DashboardExecutivoData(
      kpis: DashboardExecutivoKpis.fromJson(
        json['kpis'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class DashboardOperacionalData {
  final DashboardOperacionalKpis kpis;

  DashboardOperacionalData({required this.kpis});

  factory DashboardOperacionalData.fromJson(Map<String, dynamic> json) {
    return DashboardOperacionalData(
      kpis: DashboardOperacionalKpis.fromJson(
        json['kpis'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class DashboardService {
  final ApiClient apiClient;

  DashboardService(this.apiClient);

  Future<DashboardExecutivoData> fetchExecutivo() async {
    // No front web, a chamada é apiFetch("/contratos/dashboard/executivo/")
    // com API_BASE = ".../api". Aqui precisamos prefixar com /api.
    final resp =
        await apiClient.get('/api/contratos/dashboard/executivo/');
    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao carregar dashboard executivo (${resp.statusCode})',
      );
    }
    final data =
        jsonDecode(resp.body) as Map<String, dynamic>;
    return DashboardExecutivoData.fromJson(data);
  }

  Future<DashboardOperacionalData> fetchOperacional() async {
    final resp =
        await apiClient.get('/api/contratos/dashboard/operacional/');
    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao carregar dashboard operacional (${resp.statusCode})',
      );
    }
    final data =
        jsonDecode(resp.body) as Map<String, dynamic>;
    return DashboardOperacionalData.fromJson(data);
  }
}

