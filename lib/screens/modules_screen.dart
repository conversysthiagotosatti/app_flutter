import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../services/api_client.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class ModulesScreen extends StatelessWidget {
  final List<dynamic> modules;

  const ModulesScreen({super.key, required this.modules});

  IconData _iconForModule(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cliente')) return Icons.business;
    if (lower.contains('contrato')) return Icons.description_outlined;
    if (lower.contains('tarefa')) return Icons.check_circle_outline;
    if (lower.contains('helpdesk')) return Icons.support_agent;
    if (lower.contains('softdesk')) return Icons.desktop_windows_outlined;
    return Icons.apps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conversysAppBar(
        'Módulos disponíveis',
        onNotificationsTap: () {
          final client = ApiClient();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: client),
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: modules.isEmpty
            ? const Center(
                child: Text('Nenhum módulo disponível para este usuário.'),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 4 / 3,
                ),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final raw = modules[index];
                  final nome = (raw is Map && raw['nome'] is String)
                      ? raw['nome'] as String
                      : 'Módulo';
                  final descricao = (raw is Map && raw['descricao'] is String)
                      ? raw['descricao'] as String
                      : '';

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _iconForModule(nome),
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              nome,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (descricao.isNotEmpty)
                              Text(
                                descricao,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
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

