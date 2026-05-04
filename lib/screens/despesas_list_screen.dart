import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';
import '../widgets/permitted_cliente_selector.dart';
import 'despesa_detalhe_screen.dart';
import 'despesa_form_screen.dart';

/// Filtros alinhados ao portal (`ExpenseList.tsx`): cliente da sessão (somente leitura),
/// status, período, agrupamentos só do usuário logado (`me_only`), lista filtrada pelo
/// mesmo usuário (`user_id` quando permitido pela API) e atualizar.
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
  String _period = '';
  String _agrupamento = '';
  String _dateFrom = '';
  String _dateTo = '';
  int? _loggedUserId;

  bool _loadingBootstrap = true;
  bool _loadingList = false;
  String? _error;
  bool _noSessionClient = false;

  int? _clienteId;
  String _clienteNome = '';
  List<String> _agrupamentoOptions = [];
  List<ExpenseEnterpriseRow> _rows = [];

  static const _inputBorder = Color(0xFF334155);
  static const _cardFill = Color(0xFF0B1220);

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _statusFilter = widget.initialStatus ?? '';
    _bootstrap();
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

  Future<void> _bootstrap() async {
    setState(() {
      _loadingBootstrap = true;
      _error = null;
      _noSessionClient = false;
    });
    try {
      final permitted = await fetchPermittedClientes(widget.apiClient);
      final cid = await widget.apiClient.loadAuthClienteId();
      if (cid == null || !permitted.any((p) => p.id == cid)) {
        if (!mounted) return;
        setState(() {
          _loadingBootstrap = false;
          _noSessionClient = true;
          _clienteId = null;
          _clienteNome = '';
        });
        return;
      }

      final nome = permitted.firstWhere((p) => p.id == cid).nome;
      final uid = await _svc.fetchAuthUserId();

      var agTitles = <String>[];
      try {
        agTitles = await _svc.fetchAgrupamentoTitulos(cid, meOnly: true);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _clienteId = cid;
        _clienteNome = nome;
        _loggedUserId = uid;
        _agrupamentoOptions = agTitles;
        _loadingBootstrap = false;
      });
      await _loadList();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingBootstrap = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadList() async {
    final cid = _clienteId;
    if (cid == null) return;
    setState(() {
      _loadingList = true;
      _error = null;
    });
    try {
      final p = _period.trim();
      final usePeriod = p.isNotEmpty && p != 'custom';
      final list = await _svc.fetchExpenses(
        cid,
        status: _statusFilter.isEmpty ? null : _statusFilter,
        agrupamentoTitulo: _agrupamento.trim().isEmpty ? null : _agrupamento.trim(),
        period: usePeriod ? p : null,
        dateFrom: p == 'custom' && _dateFrom.trim().isNotEmpty ? _dateFrom.trim() : null,
        dateTo: p == 'custom' && _dateTo.trim().isNotEmpty ? _dateTo.trim() : null,
        userId: (_loggedUserId != null && _loggedUserId! > 0) ? _loggedUserId : null,
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

  Future<void> _onStatusChanged(String? value) async {
    if (value == null) return;
    setState(() => _statusFilter = value);
    await _loadList();
  }

  Future<void> _onPeriodChanged(String? value) async {
    if (value == null) return;
    setState(() {
      _period = value;
      if (value != 'custom') {
        _dateFrom = '';
        _dateTo = '';
      }
    });
    await _loadList();
  }

  Future<void> _onAgrupamentoChanged(String? value) async {
    if (value == null) return;
    setState(() => _agrupamento = value);
    await _loadList();
  }

  Future<void> _pickDate(bool isFrom) async {
    final l10n = AppLocalizations.of(context)!;
    final initialStr = isFrom ? _dateFrom : _dateTo;
    final initial = DateTime.tryParse(initialStr) ?? DateTime.now();
    final first = DateTime(2000);
    final last = DateTime(2100);
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: isFrom ? l10n.expenseDateFrom : l10n.expenseDateTo,
    );
    if (d == null || !mounted) return;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final iso = '$y-$m-$day';
    setState(() {
      if (isFrom) {
        _dateFrom = iso;
      } else {
        _dateTo = iso;
      }
    });
    await _loadList();
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
      await _loadList();
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
    if (mounted && ok == true && cid == _clienteId) await _loadList();
  }

  InputDecoration _filterDecoration(AppLocalizations l10n, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _inputBorder),
      ),
      filled: true,
      fillColor: _cardFill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    if (_loadingBootstrap) {
      return Scaffold(
        appBar: conversysAppBar(context, l10n.expenseListTile),
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_noSessionClient) {
      return Scaffold(
        appBar: conversysAppBar(context, l10n.expenseListTile),
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.expenseListSelectClienteApp,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    if (_clienteId == null) {
      return Scaffold(
        appBar: conversysAppBar(context, l10n.expenseListTile),
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? l10n.expenseNoCompanies,
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

    final periodItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: '', child: Text(l10n.expenseFilterPeriodAll)),
      DropdownMenuItem(
        value: 'last_7_days',
        child: Text(l10n.expenseFilterPeriodLast7Days),
      ),
      DropdownMenuItem(
        value: 'current_month',
        child: Text(l10n.expenseFilterPeriodCurrentMonth),
      ),
      DropdownMenuItem(
        value: 'current_year',
        child: Text(l10n.expenseFilterPeriodCurrentYear),
      ),
      DropdownMenuItem(
        value: 'last_30_days',
        child: Text(l10n.expenseFilterPeriodLast30Days),
      ),
      DropdownMenuItem(
        value: 'last_year',
        child: Text(l10n.expenseFilterPeriodLastYear),
      ),
      DropdownMenuItem(
        value: 'custom',
        child: Text(l10n.expenseFilterPeriodCustom),
      ),
    ];

    final agrupItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: '', child: Text(l10n.expenseFilterGroupAll)),
      ..._agrupamentoOptions.map(
        (t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)),
      ),
    ];

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expenseListTile),
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        icon: const Icon(Icons.add),
        label: Text(l10n.expenseNew),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.expenseSessionClientLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _inputBorder),
                    ),
                    filled: true,
                    fillColor: _cardFill,
                  ),
                  child: Text(
                    _clienteNome.isNotEmpty ? _clienteNome : '—',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 168,
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: _filterDecoration(l10n, l10n.expenseStatusFilter),
                        dropdownColor: _cardFill,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        isExpanded: true,
                        items: statusItems,
                        onChanged: _onStatusChanged,
                      ),
                    ),
                    SizedBox(
                      width: 176,
                      child: DropdownButtonFormField<String>(
                        value: _period,
                        decoration: _filterDecoration(l10n, l10n.expenseFilterPeriod),
                        dropdownColor: _cardFill,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        isExpanded: true,
                        items: periodItems,
                        onChanged: _onPeriodChanged,
                      ),
                    ),
                    if (_period == 'custom') ...[
                      SizedBox(
                        width: 148,
                        child: OutlinedButton(
                          onPressed: _loadingList ? null : () => _pickDate(true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: _inputBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          ),
                          child: Text(
                            _dateFrom.isEmpty ? l10n.expenseDateFrom : _dateFrom,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 148,
                        child: OutlinedButton(
                          onPressed: _loadingList ? null : () => _pickDate(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: _inputBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          ),
                          child: Text(
                            _dateTo.isEmpty ? l10n.expenseDateTo : _dateTo,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: _agrupamento.isEmpty || agrupItems.any((e) => e.value == _agrupamento)
                            ? _agrupamento
                            : '',
                        decoration: _filterDecoration(l10n, l10n.expenseAgrupamentoTitulo),
                        dropdownColor: _cardFill,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        isExpanded: true,
                        items: agrupItems,
                        onChanged: _onAgrupamentoChanged,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _loadingList ? null : _loadList,
                      tooltip: l10n.expenseRefresh,
                      icon: _loadingList
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
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
            child: _loadingList && _rows.isEmpty
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
