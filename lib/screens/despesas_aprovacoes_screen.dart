import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'despesa_detalhe_screen.dart';

const _kExpenseClienteId = 'expense_selected_cliente_id';

/// Aprovações por grupo + por despesa (`ExpenseApproval.tsx`).
class DespesasAprovacoesScreen extends StatefulWidget {
  final ApiClient apiClient;

  const DespesasAprovacoesScreen({super.key, required this.apiClient});

  @override
  State<DespesasAprovacoesScreen> createState() =>
      _DespesasAprovacoesScreenState();
}

class _DespesasAprovacoesScreenState extends State<DespesasAprovacoesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final ExpenseEnterpriseService _svc;

  List<ExpenseClienteRow> _companies = [];
  int? _clienteId;
  bool _loading = true;

  List<ExpensePendingGroupRow> _groups = [];
  bool _groupsBusy = false;

  List<ExpenseEnterpriseRow> _expenses = [];
  bool _expBusy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final list = await _svc.fetchCompanies();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_kExpenseClienteId);
      int? pick = saved;
      if (pick != null && !list.any((c) => c.id == pick)) pick = null;
      pick ??= list.isNotEmpty ? list.first.id : null;
      if (!mounted) return;
      setState(() {
        _companies = list;
        _clienteId = pick;
        _loading = false;
      });
      if (pick != null) {
        await Future.wait([_loadGroups(pick), _loadExpenses(pick)]);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persistCliente(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kExpenseClienteId, id);
  }

  Future<void> _loadGroups(int cid) async {
    setState(() => _groupsBusy = true);
    try {
      final g = await _svc.fetchPendingGroups(cid);
      if (!mounted) return;
      setState(() {
        _groups = g;
        _groupsBusy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _groupsBusy = false);
    }
  }

  Future<void> _loadExpenses(int cid) async {
    setState(() => _expBusy = true);
    try {
      final p1 = await _svc.fetchExpenses(cid, status: 'pending');
      final p2 = await _svc.fetchExpenses(cid, status: 'pending_finance');
      final seen = <int>{};
      final merged = <ExpenseEnterpriseRow>[];
      for (final r in [...p1, ...p2]) {
        if (seen.add(r.id)) merged.add(r);
      }
      if (!mounted) return;
      setState(() {
        _expenses = merged;
        _expBusy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _expBusy = false);
    }
  }

  String _st(AppLocalizations l10n, String code) {
    switch (code) {
      case 'pending':
        return l10n.expenseStatusPending;
      case 'pending_finance':
        return l10n.expenseStatusPendingFinance;
      default:
        return code;
    }
  }

  Future<String?> _comment(String title, AppLocalizations l10n) async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          decoration: InputDecoration(hintText: l10n.expenseCommentHint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    return v;
  }

  Future<void> _actGroup(
    String titulo,
    bool approve,
    AppLocalizations l10n,
  ) async {
    final cid = _clienteId;
    if (cid == null) return;
    final com = await _comment(
      approve ? l10n.expenseApproveGroup : l10n.expenseRejectGroup,
      l10n,
    );
    if (com == null) return;
    try {
      if (approve) {
        await _svc.approvePendingGroup(cid, titulo, comment: com);
      } else {
        await _svc.rejectPendingGroup(cid, titulo, comment: com);
      }
      if (!mounted) return;
      await _loadGroups(cid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expenseApprovalsTile),
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_companies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<int>(
                      initialValue: _clienteId,
                      decoration: InputDecoration(
                        labelText: l10n.expenseSelectClient,
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      dropdownColor: const Color(0xFF0B1220),
                      style: const TextStyle(color: Colors.white),
                      items: _companies
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) async {
                        if (id == null) return;
                        await _persistCliente(id);
                        setState(() => _clienteId = id);
                        await Future.wait([_loadGroups(id), _loadExpenses(id)]);
                      },
                    ),
                  ),
                TabBar(
                  controller: _tabs,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    Tab(text: l10n.expensePendingGroupsTitle),
                    Tab(text: l10n.expenseByExpenseTitle),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _groupsBusy
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _groups.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final g = _groups[i];
                                return Card(
                                  color: const Color(0xFF0B1220),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.agrupamentoTitulo,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${g.expenseCount} · ${g.totalAmount}',
                                          style: TextStyle(
                                            color: Colors.blueGrey[200],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            FilledButton(
                                              onPressed: () => _actGroup(
                                                g.agrupamentoTitulo,
                                                true,
                                                l10n,
                                              ),
                                              child: Text(
                                                l10n.expenseApproveGroup,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              onPressed: () => _actGroup(
                                                g.agrupamentoTitulo,
                                                false,
                                                l10n,
                                              ),
                                              child: Text(
                                                l10n.expenseRejectGroup,
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
                      _expBusy
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _expenses.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final r = _expenses[i];
                                return ListTile(
                                  title: Text(
                                    r.title,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    '${r.amount} · ${_st(l10n, r.status)}',
                                    style: TextStyle(
                                      color: Colors.blueGrey[200],
                                    ),
                                  ),
                                  onTap: () async {
                                    final cid = _clienteId;
                                    if (cid == null) return;
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DespesaDetalheScreen(
                                          apiClient: widget.apiClient,
                                          clienteId: cid,
                                          expenseId: r.id,
                                        ),
                                      ),
                                    );
                                    if (mounted) {
                                      await Future.wait([
                                        _loadGroups(cid),
                                        _loadExpenses(cid),
                                      ]);
                                    }
                                  },
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
