import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../widgets/conversys_app_bar.dart';
import 'em_desenvolvimento_screen.dart';
import 'propostas_list_screen.dart';
import 'propostas_copilot_screen.dart';
import 'notificacoes_screen.dart';
import 'clientes_prospectos_screen.dart';
import 'produto_rastreamento_movimentacao_screen.dart';

class PropostasModuleScreen extends StatelessWidget {
  final ApiClient apiClient;

  const PropostasModuleScreen({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);
    const iconBg = Color(0xFF0F172A);
    const labelColor = Colors.white;
    final l10n = AppLocalizations.of(context)!;

    final options = [
      (
        'Propostas',
        Icons.description_outlined,
        (BuildContext ctx) => PropostasListaScreen(apiClient: apiClient),
      ),
      (
        l10n.tarefasTracking,
        Icons.inventory_2_outlined,
        (BuildContext ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) =>
                  ProdutoRastreamentoMovimentacaoScreen(apiClient: apiClient),
            ),
          );
        },
      ),
      (
        'Copilot IA',
        Icons.bolt,
        (BuildContext ctx) => PropostasCopilotScreen(apiClient: apiClient),
      ),
      (
        'Institucionais',
        Icons.apartment_outlined,
        (BuildContext ctx) => const EmDesenvolvimentoScreen(titulo: 'Institucionais'),
      ),
      (
        'Parceiros',
        Icons.people_alt_outlined,
        (BuildContext ctx) => const EmDesenvolvimentoScreen(titulo: 'Parceiros'),
      ),
      (
        'Clientes / Prospectos',
        Icons.people_outline,
        (BuildContext ctx) => ClientesProspectosScreen(apiClient: apiClient),
      ),
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: conversysAppBar(context, 
        'Propostas',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: apiClient),
            ),
          );
        },
      ),
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
                            color: labelColor,
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

