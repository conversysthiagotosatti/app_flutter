import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../widgets/conversys_app_bar.dart';
import 'despesas_dashboard_screen.dart';
import 'despesas_list_screen.dart';

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

    final options = <(String, IconData, void Function(BuildContext))>[
      (
        l10n.expenseListTile,
        Icons.list_alt_outlined,
        (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasListScreen(apiClient: apiClient),
            ),
          );
        },
      ),
      (
        l10n.expenseApprovalsTile,
        Icons.pending_actions_outlined,
        (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasListScreen(
                apiClient: apiClient,
                initialStatus: 'pending',
              ),
            ),
          );
        },
      ),
      (
        l10n.expensePaymentsTile,
        Icons.payments_outlined,
        (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasListScreen(
                apiClient: apiClient,
                initialStatus: 'approved',
              ),
            ),
          );
        },
      ),
      (
        l10n.expenseDashboardTile,
        Icons.insights_outlined,
        (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => DespesasDashboardScreen(apiClient: apiClient),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expenseModuleTitle),
      backgroundColor: background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 4 / 3,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
