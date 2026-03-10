import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/helpdesk_dashboard_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class HelpdeskAnalyticsScreen extends StatefulWidget {
  final ApiClient apiClient;

  const HelpdeskAnalyticsScreen({
    super.key,
    required this.apiClient,
  });

  @override
  State<HelpdeskAnalyticsScreen> createState() =>
      _HelpdeskAnalyticsScreenState();
}

class _HelpdeskAnalyticsScreenState extends State<HelpdeskAnalyticsScreen> {
  late final HelpdeskDashboardService _service;

  bool _loading = true;
  String? _error;
  HelpdeskResumo? _resumo;
  List<ProblemaRecorrente> _recorrentes = const [];

  @override
  void initState() {
    super.initState();
    _service = HelpdeskDashboardService(widget.apiClient);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resumo = await _service.fetchResumo();
      final rec = await _service.fetchRecorrentes();
      if (!mounted) return;
      setState(() {
        _resumo = resumo;
        _recorrentes = rec;
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
    final resumo = _resumo;

    return Scaffold(
      appBar: conversysAppBar(
        'Helpdesk · Analytics',
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
                          'Erro ao carregar analytics: $_error',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Analytics · Helpdesk',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saúde do SLA, severidade e distribuição dos chamados, usando os mesmos dados do painel web.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      if (resumo != null) _buildKpis(context, resumo),
                      const SizedBox(height: 24),
                      if (resumo != null) _buildSlaSection(context, resumo),
                      const SizedBox(height: 24),
                      if (resumo != null)
                        _buildPrioridadeSection(context, resumo),
                      const SizedBox(height: 24),
                      if (_recorrentes.isNotEmpty)
                        _buildRecorrentesSection(context, _recorrentes),
                    ],
                  ),
      ),
    );
  }

  Widget _buildKpis(BuildContext context, HelpdeskResumo resumo) {
    final ativos =
        resumo.abertos + resumo.emAtendimento + resumo.aguardando;

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
          titulo: 'Chamados ativos',
          valor: ativos.toString(),
          subtitulo: '${resumo.total} no período',
          icon: Icons.inbox_outlined,
          color: const Color(0xFF0EA5E9),
        ),
        _kpiCard(
          context,
          titulo: 'SLA cumprido',
          valor: '${resumo.slaCompliance.toStringAsFixed(0)}%',
          subtitulo: 'Meta 90%',
          icon: Icons.trending_up,
          color: const Color(0xFF10B981),
        ),
        _kpiCard(
          context,
          titulo: 'Fora do SLA',
          valor: resumo.slaVencido.toString(),
          subtitulo:
              '${resumo.slaProximoVencer} prestes a vencer',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF97316),
        ),
        _kpiCard(
          context,
          titulo: 'Sem atendente',
          valor: resumo.semAtendente.toString(),
          subtitulo: 'necessitam atribuição',
          icon: Icons.person_off_outlined,
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

  Widget _buildSlaSection(BuildContext context, HelpdeskResumo resumo) {
    final compliance = resumo.slaCompliance.clamp(0, 100).toDouble();
    final vencido = resumo.slaVencido;
    final proximo = resumo.slaProximoVencer;

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
              'Saúde do SLA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: compliance / 100.0,
                        strokeWidth: 8,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                Color(0xFF10B981)),
                        backgroundColor:
                            const Color(0xFF10B981).withOpacity(0.1),
                      ),
                      Center(
                        child: Text(
                          '${compliance.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chamados dentro do SLA',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fora do SLA: $vencido · Prestes a vencer: $proximo',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioridadeSection(
    BuildContext context,
    HelpdeskResumo resumo,
  ) {
    final total = resumo.total > 0 ? resumo.total : 1;

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
              'Severidade por prioridade',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Column(
              children: resumo.porPrioridade.map((item) {
                final prioridade = item['prioridade'] as String? ?? '';
                final qt = item['total'] as int? ?? 0;
                final pct = (qt / total * 100).clamp(0, 100);
                Color cor;
                switch (prioridade) {
                  case 'CRITICA':
                    cor = const Color(0xFFEF4444);
                    break;
                  case 'ALTA':
                    cor = const Color(0xFFF97316);
                    break;
                  case 'MEDIA':
                    cor = const Color(0xFF3B82F6);
                    break;
                  case 'BAIXA':
                    cor = const Color(0xFF94A3B8);
                    break;
                  default:
                    cor = const Color(0xFFCBD5E1);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          prioridade,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct / 100.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: cor,
                                borderRadius:
                                    BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$qt',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecorrentesSection(
    BuildContext context,
    List<ProblemaRecorrente> recorrentes,
  ) {
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
              'Problemas recorrentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Column(
              children: recorrentes.map((p) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    p.cliente.isNotEmpty ? p.cliente : 'Cliente',
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    p.categoria.isNotEmpty
                        ? p.categoria
                        : 'Categoria',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    '${p.total}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

