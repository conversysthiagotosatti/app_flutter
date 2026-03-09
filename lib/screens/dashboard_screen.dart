import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/dashboard_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiClient apiClient;

  const DashboardScreen({super.key, required this.apiClient});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service;

  bool _loading = true;
  String? _error;
  DashboardExecutivoData? _exec;
  DashboardOperacionalData? _oper;

  @override
  void initState() {
    super.initState();
    _service = DashboardService(widget.apiClient);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final exec = await _service.fetchExecutivo();
      final oper = await _service.fetchOperacional();
      if (!mounted) return;
      setState(() {
        _exec = exec;
        _oper = oper;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exec = _exec;
    final oper = _oper;

    return Scaffold(
      appBar: conversysAppBar(
        'Dashboard de Tarefas',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Erro ao carregar dashboard: $_error',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Analytics · Visão executiva',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Métricas de performance, eficiência operacional e riscos processados em tempo real pela inteligência Conversys.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      if (exec != null && oper != null)
                        _buildKpiGrid(context, exec, oper),
                      const SizedBox(height: 24),
                      if (exec != null && oper != null)
                        _buildEficienciaSection(context, exec, oper),
                    ],
                  ),
      ),
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    DashboardExecutivoData exec,
    DashboardOperacionalData oper,
  ) {
    final kpisExec = exec.kpis;
    final kpisOper = oper.kpis;

    final contratosAtivos = kpisOper.contratosAtivos;
    final contratosTotal = kpisOper.contratosTotal;
    final horasApontadas = kpisExec.horasApontadasTotal;
    final horasPrevistas = kpisExec.horasPrevistasTotal;
    final tarefasAtrasadas = kpisOper.tarefasAtrasadasEstimada;
    final contratosVencendo = kpisOper.contratosVencendo30Dias;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3 / 2,
      children: [
        _kpiCard(
          context,
          titulo: 'Contratos ativos',
          valor: contratosAtivos.toString(),
          subtitulo: 'de $contratosTotal totais',
          icon: Icons.description_outlined,
          color: const Color(0xFF0EA5E9),
        ),
        _kpiCard(
          context,
          titulo: 'Horas apontadas',
          valor: horasApontadas.toStringAsFixed(1),
          subtitulo: horasPrevistas > 0
              ? 'de ${horasPrevistas.toStringAsFixed(0)} previstas'
              : 'Sem horas previstas',
          icon: Icons.access_time,
          color: const Color(0xFF10B981),
        ),
        _kpiCard(
          context,
          titulo: 'Tarefas atrasadas',
          valor: tarefasAtrasadas.toString(),
          subtitulo: 'em atenção imediata',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF97316),
        ),
        _kpiCard(
          context,
          titulo: 'Vencimentos (30d)',
          valor: contratosVencendo.toString(),
          subtitulo: 'contratos na reta final',
          icon: Icons.event_available_outlined,
          color: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEficienciaSection(
    BuildContext context,
    DashboardExecutivoData exec,
    DashboardOperacionalData oper,
  ) {
    final horasApontadas = exec.kpis.horasApontadasTotal;
    final horasPrevistas = exec.kpis.horasPrevistasTotal;
    final tarefasTotal = oper.kpis.tarefasTotal;

    final consumoPct =
        horasPrevistas > 0 ? (horasApontadas / horasPrevistas) * 100 : 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicadores de eficiência',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _gauge(
                  label: 'Consumo de horas',
                  value: consumoPct.clamp(0, 100).toDouble(),
                  suffix: '%',
                  color: const Color(0xFF10B981),
                ),
                _gauge(
                  label: 'Tarefas registradas',
                  value: tarefasTotal.toDouble(),
                  suffix: '',
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gauge({
    required String label,
    required double value,
    required String suffix,
    required Color color,
  }) {
    final display = value.isFinite ? value : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: suffix == '%'
                    ? (display / 100).clamp(0.0, 1.0)
                    : 1.0,
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: color.withOpacity(0.1),
              ),
              Center(
                child: Text(
                  '${display.toStringAsFixed(suffix == '%' ? 0 : 0)}$suffix',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 110,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

