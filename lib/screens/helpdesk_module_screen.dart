import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/conversys_app_bar.dart';
import 'em_desenvolvimento_screen.dart';
import 'helpdesk_analytics_screen.dart';
import 'helpdesk_chamados_screen.dart';

class HelpdeskModuleScreen extends StatelessWidget {
  final ApiClient apiClient;

  const HelpdeskModuleScreen({super.key, required this.apiClient});

  void _openAnalytics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HelpdeskAnalyticsScreen(
          apiClient: apiClient,
        ),
      ),
    );
  }

  void _openChamados(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HelpdeskChamadosScreen(
          apiClient: apiClient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    ];

    return Scaffold(
      appBar: conversysAppBar('Helpdesk'),
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
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTap(context),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

