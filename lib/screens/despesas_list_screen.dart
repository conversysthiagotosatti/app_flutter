import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'despesa_detalhe_screen.dart';
import 'despesa_form_screen.dart';

const _kExpenseClienteId = 'expense_selected_cliente_id';

class DespesasListScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String? initialStatus;

  const DespesasListScreen({
    super.key,
    required this.apiClient,
    this.initialStatus,
  });

  @override
  State<DespesasListScreen> createState() => _DespesasListScreenState();
}

class _DespesasListScreenState extends State<DespesasListScreen> {
  late final ExpenseEnterpriseService _svc;
  late String _statusFilter;

  bool _loadingCompanies = true;
  bool _loadingList = false;
  String? _error;
  List<ExpenseClienteRow> _companies = [];
  List<ExpenseEnterpriseRow> _rows = [];
  int? _clienteId;

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _statusFilter = widget.initialStatus ?? '';
    _loadCompanies();
  }

  String _statusLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'draft':
        return l10n.expenseStatusDraft;
      case 'pending':
        return l10n.expenseStatusPending;
      case 'approved':
        return l10n.expenseStatusApproved;
      case 'rejected':
        return l10n.expenseStatusRejected;
      case 'audited':
        return l10n.expenseStatusAudited;
      case 'paid':
        return l10n.expenseStatusPaid;
      case 'pending_finance':
        return l10n.expenseStatusPendingFinance;
      case 'finance_approved':
        return l10n.expenseStatusFinanceApproved;
      case 'finance_rejected':
        return l10n.expenseStatusFinanceRejected;
      default:
        return code;
    }
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _loadingCompanies = true;
      _error = null;
    });
    try {
      final list = await _svc.fetchCompanies();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_kExpenseClienteId);
      int? pick = saved;
      if (pick != null && !list.any((c) => c.id == pick)) {
        pick = null;
      }
      pick ??= list.isNotEmpty ? list.first.id : null;
      if (!mounted) return;
      setState(() {
        _companies = list;
        _clienteId = pick;
        _loadingCompanies = false;
      });
      if (pick != null) {
        await _loadList(pick);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCompanies = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _persistCliente(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kExpenseClienteId, id);
  }

  Future<void> _loadList(int clienteId) async {
    setState(() {
      _loadingList = true;
      _error = null;
    });
    try {
      final list = await _svc.fetchExpenses(
        clienteId,
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _onClienteChanged(int? id) async {
    if (id == null) return;
    await _persistCliente(id);
    setState(() => _clienteId = id);
    await _loadList(id);
  }

  Future<void> _onStatusChanged(String? value) async {
    if (value == null) return;
    setState(() => _statusFilter = value);
    final cid = _clienteId;
    if (cid != null) await _loadList(cid);
  }

  Future<void> _openDetail(ExpenseEnterpriseRow row) async {
    final cid = _clienteId;
    if (cid == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DespesaDetalheScreen(
          apiClient: widget.apiClient,
          clienteId: cid,
          expenseId: row.id,
        ),
      ),
    );
    if (mounted && cid == _clienteId) {
      await _loadList(cid);
    }
  }

  Future<void> _openNew() async {
    final cid = _clienteId;
    if (cid == null) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DespesaFormScreen(
          apiClient: widget.apiClient,
          clienteId: cid,
        ),
      ),
    );
    if (mounted && ok == true && cid == _clienteId) await _loadList(cid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    if (_loadingCompanies) {
      return Scaffold(
        appBar: conversysAppBar(context, l10n.expenseListTile),
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_companies.isEmpty) {
      return Scaffold(
        appBar: conversysAppBar(context, l10n.expenseListTile),
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.expenseNoCompanies,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    final statusItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: '', child: Text(l10n.expenseStatusAll)),
      DropdownMenuItem(value: 'draft', child: Text(l10n.expenseStatusDraft)),
      DropdownMenuItem(
        value: 'pending',
        child: Text(l10n.expenseStatusPending),
      ),
      DropdownMenuItem(
        value: 'approved',
        child: Text(l10n.expenseStatusApproved),
      ),
      DropdownMenuItem(
        value: 'pending_finance',
        child: Text(l10n.expenseStatusPendingFinance),
      ),
      DropdownMenuItem(
        value: 'finance_approved',
        child: Text(l10n.expenseStatusFinanceApproved),
      ),
      DropdownMenuItem(
        value: 'finance_rejected',
        child: Text(l10n.expenseStatusFinanceRejected),
      ),
      DropdownMenuItem(
        value: 'rejected',
        child: Text(l10n.expenseStatusRejected),
      ),
      DropdownMenuItem(
        value: 'audited',
        child: Text(l10n.expenseStatusAudited),
      ),
      DropdownMenuItem(value: 'paid', child: Text(l10n.expenseStatusPaid)),
    ];

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expenseListTile),
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _clienteId == null ? null : _openNew,
        icon: const Icon(Icons.add),
        label: Text(l10n.expenseNew),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _clienteId,
                  decoration: InputDecoration(
                    labelText: l10n.expenseSelectClient,
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
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
                  onChanged: _onClienteChanged,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: InputDecoration(
                    labelText: l10n.expenseStatusFilter,
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                  dropdownColor: const Color(0xFF0B1220),
                  style: const TextStyle(color: Colors.white),
                  items: statusItems,
                  onChanged: _onStatusChanged,
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.expenseLoadError(_error!),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: _loadingList
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? Center(
                        child: Text(
                          l10n.expenseEmptyList,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = _rows[i];
                          return ListTile(
                            title: Text(
                              r.title,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${r.amount} · ${_statusLabel(l10n, r.status)}',
                              style: TextStyle(color: Colors.blueGrey[200]),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.white38,
                            ),
                            onTap: () => _openDetail(r),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
