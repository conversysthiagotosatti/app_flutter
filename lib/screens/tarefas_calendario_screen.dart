import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/timers_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';
import 'tarefas_apontamento_screen.dart';

class TarefasCalendarioScreen extends StatefulWidget {
  final ApiClient apiClient;

  const TarefasCalendarioScreen({super.key, required this.apiClient});

  @override
  State<TarefasCalendarioScreen> createState() =>
      _TarefasCalendarioScreenState();
}

class _TarefasCalendarioScreenState extends State<TarefasCalendarioScreen> {
  late final TimersService _service;

  DateTime _mesAtual = DateTime.now();
  bool _loading = true;
  String? _error;
  List<TimerApontamento> _apontamentos = const [];
  DateTime? _diaSelecionado;

  @override
  void initState() {
    super.initState();
    _service = TimersService(widget.apiClient);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inicio = DateTime(_mesAtual.year, _mesAtual.month, 1);
      final fim = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
      final itens = await _service.listar(inicio: inicio, fim: fim);
      if (!mounted) return;
      setState(() {
        _apontamentos = itens;
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

  Map<DateTime, double> get _horasPorDia {
    final mapa = <DateTime, double>{};
    for (final a in _apontamentos) {
      if (a.data == null || a.data!.isEmpty) continue;
      try {
        final partes = a.data!.split('-');
        if (partes.length != 3) continue;
        final ano = int.parse(partes[0]);
        final mes = int.parse(partes[1]);
        final dia = int.parse(partes[2]);
        final chave = DateTime(ano, mes, dia);
        mapa[chave] = (mapa[chave] ?? 0) + a.horas;
      } catch (_) {
        continue;
      }
    }
    return mapa;
  }

  Map<DateTime, List<TimerApontamento>> get _apontamentosPorDia {
    final mapa = <DateTime, List<TimerApontamento>>{};
    for (final a in _apontamentos) {
      if (a.data == null || a.data!.isEmpty) continue;
      try {
        final partes = a.data!.split('-');
        if (partes.length != 3) continue;
        final ano = int.parse(partes[0]);
        final mes = int.parse(partes[1]);
        final dia = int.parse(partes[2]);
        final chave = DateTime(ano, mes, dia);
        final lista = mapa[chave] ?? <TimerApontamento>[];
        lista.add(a);
        mapa[chave] = lista;
      } catch (_) {
        continue;
      }
    }
    return mapa;
  }

  void _mesAnterior() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1, 1);
    });
    _carregar();
  }

  void _proximoMes() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1, 1);
    });
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final horasPorDia = _horasPorDia;
    final apontamentosPorDia = _apontamentosPorDia;

    final primeiroDiaMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
    final ultimoDiaMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0);
    final inicioGrid = primeiroDiaMes.subtract(
      Duration(days: primeiroDiaMes.weekday % 7),
    );
    final fimGrid = ultimoDiaMes.add(
      Duration(days: 6 - (ultimoDiaMes.weekday % 7)),
    );

    final dias = <DateTime>[];
    for (
      var d = inicioGrid;
      d.isBefore(fimGrid.add(const Duration(days: 1)));
      d = d.add(const Duration(days: 1))
    ) {
      dias.add(d);
    }

    const background = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);

    return Scaffold(
      appBar: conversysAppBar(
        context,
        'Calendário de apontamentos',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      backgroundColor: background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_diaSelecionado == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Toque primeiro em um dia para adicionar a marcação.',
                ),
              ),
            );
            return;
          }
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => TarefasApontamentoScreen(
                apiClient: widget.apiClient,
                data: _diaSelecionado!,
              ),
            ),
          );
          if (created == true) {
            await _carregar();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Adicionar marcação'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _mesAnterior,
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                Text(
                  '${_mesAtual.month.toString().padLeft(2, '0')}/${_mesAtual.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: _proximoMes,
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Erro ao carregar apontamentos: $_error',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _SemanaLabel('Dom'),
                _SemanaLabel('Seg'),
                _SemanaLabel('Ter'),
                _SemanaLabel('Qua'),
                _SemanaLabel('Qui'),
                _SemanaLabel('Sex'),
                _SemanaLabel('Sáb'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: dias.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final dia = dias[index];
                  final bool mesAtualFlag = dia.month == _mesAtual.month;
                  final horas = horasPorDia[dia] ?? 0;
                  final selecionado =
                      _diaSelecionado != null &&
                      dia.year == _diaSelecionado!.year &&
                      dia.month == _diaSelecionado!.month &&
                      dia.day == _diaSelecionado!.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _diaSelecionado = dia;
                      });
                      final itensDia = apontamentosPorDia[dia] ?? const [];
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: const Color(0xFF020617),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (ctx) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Apontamentos de '
                                      '${dia.day.toString().padLeft(2, '0')}/'
                                      '${dia.month.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (itensDia.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Nenhum apontamento neste dia.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                else
                                  Flexible(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: itensDia.length,
                                      separatorBuilder: (_, _) => const Divider(
                                        color: Colors.white24,
                                        height: 12,
                                      ),
                                      itemBuilder: (context, index) {
                                        final a = itensDia[index];
                                        return ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 0,
                                              ),
                                          title: Text(
                                            a.tarefaTitulo,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${a.contratoTitulo}\n${a.usuarioNome}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                          trailing: Text(
                                            '${a.horas.toStringAsFixed(1)}h',
                                            style: const TextStyle(
                                              color: Colors.lightBlueAccent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: mesAtualFlag
                            ? cardColor
                            : cardColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selecionado
                              ? Colors.blueAccent
                              : cardBorder.withOpacity(horas > 0 ? 0.9 : 0.6),
                          width: selecionado ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dia.day.toString(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    mesAtualFlag ? 1 : 0.5,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (horas > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${horas.toStringAsFixed(1)}h',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemanaLabel extends StatelessWidget {
  final String texto;

  const _SemanaLabel(this.texto);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
