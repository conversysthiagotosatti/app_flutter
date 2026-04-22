import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../widgets/conversys_app_bar.dart';
import 'helpdesk_analytics_screen.dart';
import 'helpdesk_chamados_screen.dart';
import 'helpdesk_copilot_screen.dart';

class HelpdeskModuleScreen extends StatelessWidget {
  final ApiClient apiClient;

  const HelpdeskModuleScreen({super.key, required this.apiClient});

  void _openAnalytics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HelpdeskAnalyticsScreen(apiClient: apiClient),
      ),
    );
  }

  void _openChamados(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HelpdeskChamadosScreen(apiClient: apiClient),
      ),
    );
  }

  void _openCopilot(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HelpdeskCopilotScreen(apiClient: apiClient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);
    const iconBg = Color(0xFF0F172A);
    const labelColor = Colors.white;

    final options = [
      (
        'Analytics',
        Icons.analytics_outlined,
        (BuildContext ctx) => _openAnalytics(ctx),
      ),
      (
        'Chamados',
        Icons.support_agent,
        (BuildContext ctx) => _openChamados(ctx),
      ),
      ('Copilot IA', Icons.bolt, (BuildContext ctx) => _openCopilot(ctx)),
    ];

    return Scaffold(
      appBar: conversysAppBar(
        context,
        AppLocalizations.of(context)!.helpdeskTitle,
      ),
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
