import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../utils/expense_cliente_selection.dart';

class PermittedCliente {
  final int id;
  final String nome;

  const PermittedCliente({required this.id, required this.nome});
}

/// Clientes permitidos ao usuário (`GET /api/auth/me/clients/`, mesmo contrato do marketplace).
Future<List<PermittedCliente>> fetchPermittedClientes(ApiClient apiClient) async {
  final r = await apiClient.get('/api/auth/me/clients/');
  if (r.statusCode != 200) {
    throw Exception('HTTP ${r.statusCode}');
  }
  final decoded = jsonDecode(r.body);
  if (decoded is! List) return [];
  final out = <PermittedCliente>[];
  for (final e in decoded) {
    if (e is! Map<String, dynamic>) continue;
    final id = e['cliente_id'];
    final nome = e['cliente_nome']?.toString() ?? '';
    int? cid;
    if (id is int) {
      cid = id;
    } else if (id is num) {
      cid = id.toInt();
    }
    if (cid != null && nome.isNotEmpty) {
      out.add(PermittedCliente(id: cid, nome: nome));
    }
  }
  return out;
}

/// Dropdown compacto para a AppBar (módulo Despesas).
class PermittedClienteSelector extends StatefulWidget {
  final ApiClient apiClient;

  const PermittedClienteSelector({super.key, required this.apiClient});

  @override
  State<PermittedClienteSelector> createState() => _PermittedClienteSelectorState();
}

class _PermittedClienteSelectorState extends State<PermittedClienteSelector> {
  bool _loading = true;
  String? _err;
  List<PermittedCliente> _list = [];
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final list = await fetchPermittedClientes(widget.apiClient);
      final prefs = await SharedPreferences.getInstance();
      int? pick = prefs.getInt(kExpenseSelectedClienteIdKey);
      pick ??= await widget.apiClient.loadAuthClienteId();
      if (pick != null &&
          (list.isEmpty || !list.any((c) => c.id == pick))) {
        pick = null;
      }
      pick ??= list.isNotEmpty ? list.first.id : null;
      if (!mounted) return;
      setState(() {
        _list = list;
        _selectedId = pick;
        _loading = false;
      });
      if (pick != null) {
        final nome = list.firstWhere((c) => c.id == pick).nome;
        await persistExpenseModuleClienteSelection(
          widget.apiClient,
          pick,
          nome,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _err = e.toString();
      });
    }
  }

  Future<void> _onPick(int? id) async {
    if (id == null) return;
    PermittedCliente? row;
    for (final c in _list) {
      if (c.id == id) {
        row = c;
        break;
      }
    }
    if (row == null) return;
    setState(() => _selectedId = id);
    await persistExpenseModuleClienteSelection(
      widget.apiClient,
      row.id,
      row.nome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fg = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;

    if (_loading) {
      return SizedBox(
        height: 28,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg.withValues(alpha: 0.85),
            ),
          ),
        ),
      );
    }
    if (_err != null) {
      return Text(
        _err!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12),
      );
    }
    if (_list.isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 13),
      );
    }
    if (_list.length == 1) {
      return Text(
        _list.first.nome,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg.withValues(alpha: 0.95),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Theme.of(context).colorScheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isDense: true,
          isExpanded: true,
          value: _selectedId,
          icon: Icon(Icons.arrow_drop_down, color: fg.withValues(alpha: 0.9)),
          hint: Text(
            l10n.expenseSelectClient,
            style: TextStyle(color: fg.withValues(alpha: 0.75), fontSize: 13),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          items: _list
              .map(
                (c) => DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(
                    c.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => _onPick(v),
        ),
      ),
    );
  }
}
