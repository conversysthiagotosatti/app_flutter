import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../utils/expense_cliente_selection.dart';
import '../widgets/permitted_cliente_selector.dart';
import 'despesa_form_screen.dart';
import 'despesas_aprovacoes_screen.dart';
import 'despesas_auditoria_screen.dart';
import 'despesas_dashboard_screen.dart';
import 'despesas_grupos_screen.dart';
import 'despesas_importacao_lote_screen.dart';
import 'despesas_list_screen.dart';
import 'despesas_pagamentos_screen.dart';

class DespesasModuleScreen extends StatelessWidget {
  final ApiClient apiClient;

  const DespesasModuleScreen({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);
    const iconBg = Color(0xFF0F172A);
    final l10n = AppLocalizations.of(context)!;

    Future<int?> pickClienteForNewExpense(BuildContext outer) async {
      try {
        final list = await fetchPermittedClientes(apiClient);
        if (!outer.mounted) return null;
        if (list.isEmpty) return null;
        if (list.length == 1) return list.first.id;
        final prefs = await SharedPreferences.getInstance();
        int? saved = prefs.getInt(kExpenseSelectedClienteIdKey);
        saved ??= await apiClient.loadAuthClienteId();
        if (saved != null && list.any((c) => c.id == saved)) {
          return saved;
        }
        if (!outer.mounted) return null;
        int? chosen;
        await showDialog<void>(
          context: outer,
          builder: (ctx) {
            return AlertDialog(
              title: Text(l10n.expenseSelectClient),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: list
                      .map(
                        (c) => ListTile(
                          title: Text(c.nome),
                          onTap: () {
                            chosen = c.id;
                            Navigator.pop(ctx);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        );
        return chosen;
      } catch (_) {
        return null;
      }
    }

    final options = <(String, IconData, Future<void> Function(BuildContext))>[
      (
        l10n.expenseListTile,
        Icons.list_alt_outlined,
        (ctx) async {
          await Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasListScreen(apiClient: apiClient),
            ),
          );
        },
      ),
      (
        l10n.expenseNew,
        Icons.add_circle_outline,
        (ctx) async {
          final cid = await pickClienteForNewExpense(ctx);
          if (cid == null || !ctx.mounted) return;
          await Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesaFormScreen(
                apiClient: apiClient,
                clienteId: cid,
              ),
            ),
          );
        },
      ),
      (
        l10n.expenseApprovalsTile,
        Icons.pending_actions_outlined,
        (ctx) async {
          await Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasAprovacoesScreen(apiClient: apiClient),
            ),
          );
        },
      ),
      (
        l10n.expensePaymentsTile,
        Icons.payments_outlined,
        (ctx) async {
          await Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasPagamentosScreen(apiClient: apiClient),
            ),
          );
        },
      ),
      (
        l10n.expenseGroupsTile,
        Icons.folder_copy_outlined,
        (ctx) async {
          await Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasGruposScreen(apiClient: apiClient),
            ),
          );
        },
      ),
      (
        l10n.expenseBatchImportTile,
        Icons.upload_file_outlined,
        (ctx) async {
          await Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasImportacaoLoteScreen(apiClient: apiClient),
            ),
          );
        },
      ),
      (
        l10n.expenseAuditModuleTile,
        Icons.history_edu_outlined,
        (ctx) async {
          await Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasAuditoriaScreen(apiClient: apiClient),
            ),
          );
        },
      ),
      (
        l10n.expenseDashboardTile,
        Icons.insights_outlined,
        (ctx) async {
          await Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasDashboardScreen(apiClient: apiClient),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final (label, icon, onTap) = options[index];
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onTap(context),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: Colors.blue[200]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
