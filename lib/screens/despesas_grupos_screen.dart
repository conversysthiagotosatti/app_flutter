import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'despesa_detalhe_screen.dart';

const _kExpenseClienteId = 'expense_selected_cliente_id';

/// Resumo de agrupamentos (`/api/expenses/group-summary/`), como `ExpenseGroupList.tsx`.
class DespesasGruposScreen extends StatefulWidget {
  final ApiClient apiClient;

  const DespesasGruposScreen({super.key, required this.apiClient});

  @override
  State<DespesasGruposScreen> createState() => _DespesasGruposScreenState();
}

class _DespesasGruposScreenState extends State<DespesasGruposScreen> {
  late final ExpenseEnterpriseService _svc;
  bool _loading = true;
  String? _error;
  List<ExpenseClienteRow> _companies = [];
  int? _clienteId;
  List<ExpenseGroupSummaryRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
      });
      if (pick != null) await _loadGroups(pick);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _persistCliente(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kExpenseClienteId, id);
  }

  Future<void> _loadGroups(int clienteId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final g = await _svc.fetchGroupSummary(clienteId);
      if (!mounted) return;
      setState(() {
        _rows = g;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openGrupo(String titulo) async {
    final cid = _clienteId;
    if (cid == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _GrupoDetalhePage(
          apiClient: widget.apiClient,
          clienteId: cid,
          agrupamentoTitulo: titulo,
        ),
      ),
    );
    if (mounted) await _loadGroups(cid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expenseGroupListTitle),
      backgroundColor: bg,
      body: _loading && _companies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_companies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<int>(
                      initialValue: _clienteId,
                      decoration: _ddDecoration(l10n.expenseSelectClient),
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
                        await _loadGroups(id);
                      },
                    ),
                  ),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clienteId == null
                          ? null
                          : () => _loadGroups(_clienteId!),
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: Text(
                        l10n.expenseRefresh,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      l10n.expenseLoadError(_error!),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _rows.isEmpty
                      ? Center(
                          child: Text(
                            l10n.expenseEmptyList,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _rows.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final r = _rows[i];
                            return ListTile(
                              title: Text(
                                r.agrupamentoTitulo,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${r.expenseCount} · ${r.totalAmount} · rascunhos: ${r.draftCount}',
                                style: TextStyle(color: Colors.blueGrey[200]),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.white38,
                              ),
                              onTap: () => _openGrupo(r.agrupamentoTitulo),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  InputDecoration _ddDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
    );
  }
}

class _GrupoDetalhePage extends StatefulWidget {
  final ApiClient apiClient;
  final int clienteId;
  final String agrupamentoTitulo;

  const _GrupoDetalhePage({
    required this.apiClient,
    required this.clienteId,
    required this.agrupamentoTitulo,
  });

  @override
  State<_GrupoDetalhePage> createState() => _GrupoDetalhePageState();
}

class _GrupoDetalhePageState extends State<_GrupoDetalhePage> {
  late final ExpenseEnterpriseService _svc;
  bool _loading = true;
  bool _submitting = false;
  List<ExpenseEnterpriseRow> _drafts = [];

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _svc.fetchExpenses(
        widget.clienteId,
        status: 'draft',
        agrupamentoTitulo: widget.agrupamentoTitulo,
      );
      if (!mounted) return;
      setState(() {
        _drafts = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _submitBatch(AppLocalizations l10n) async {
    setState(() => _submitting = true);
    try {
      final res = await _svc.submitExpenseGroup(
        widget.clienteId,
        widget.agrupamentoTitulo,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lote'),
          content: SingleChildScrollView(
            child: Text(
              'Enviadas: ${res.submitted}\n'
              'Auto-aprovadas: ${res.autoApproved}\n'
              'Pendentes: ${res.pendingApproval}\n'
              '${res.errors.isEmpty ? '' : '\nErros:\n${const JsonEncoder.withIndent('  ').convert(res.errors)}'}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(
        context,
        '${l10n.expenseGroupDetailTitle}: ${widget.agrupamentoTitulo}',
      ),
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _drafts.isEmpty || _submitting
            ? null
            : () => _submitBatch(l10n),
        icon: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        label: Text(l10n.expenseGroupSubmitBatch),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.expenseGroupMembers,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _drafts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = _drafts[i];
                      return ListTile(
                        title: Text(
                          r.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          r.amount,
                          style: TextStyle(color: Colors.blueGrey[200]),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DespesaDetalheScreen(
                                apiClient: widget.apiClient,
                                clienteId: widget.clienteId,
                                expenseId: r.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
