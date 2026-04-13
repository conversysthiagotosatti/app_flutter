import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../services/api_client.dart';
import 'notificacoes_screen.dart';

class ModulesScreen extends StatelessWidget {
  final List<dynamic> modules;

  const ModulesScreen({super.key, required this.modules});

  IconData _iconForModule(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cliente')) return Icons.business;
    if (lower.contains('proposta')) return Icons.receipt_long;
    if (lower.contains('contrato')) return Icons.description_outlined;
    if (lower.contains('tarefa')) return Icons.check_circle_outline;
    if (lower.contains('helpdesk')) return Icons.support_agent;
    if (lower.contains('softdesk')) return Icons.desktop_windows_outlined;
    return Icons.apps;
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final theme = Theme.of(context);

    const backgroundTop = Color(0xFF020617); // bem escuro
    const backgroundBottom = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);
    const accent = Color(0xFF005AFF);

    return Scaffold(
      backgroundColor: backgroundTop,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundTop, backgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar com logo / título simples
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.blur_circular,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'The Blue Huddle',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_none,
                          color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                NotificacoesScreen(apiClient: apiClient),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Hero / cabeçalho
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uma linha projetada pela Conversys',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.blue[200],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Arquiteturas pré-definidas de tecnologia',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acesse seus serviços ativos abaixo ou explore novas soluções integradas da Conversys.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blueGrey[200],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Meus serviços',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: modules.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum módulo disponível para este usuário.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 4 / 3,
                          ),
                          itemCount: modules.length,
                          itemBuilder: (context, index) {
                            final raw = modules[index];
                            final nome = (raw is Map &&
                                    raw['nome'] is String)
                                ? raw['nome'] as String
                                : 'Módulo';
                            final descricao = (raw is Map &&
                                    raw['descricao'] is String)
                                ? raw['descricao'] as String
                                : '';

                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HomeScreen(
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: cardBorder,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.white.withOpacity(0.05),
                                          ),
                                          child: Icon(
                                            _iconForModule(nome),
                                            color: Colors.blue[200],
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            color:
                                                Colors.green.withOpacity(0.1),
                                            border: Border.all(
                                              color: Colors.greenAccent
                                                  .withOpacity(0.4),
                                            ),
                                          ),
                                          child: const Text(
                                            'ATIVO',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.greenAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      nome,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    if (descricao.isNotEmpty)
                                      Text(
                                        descricao,
                                        style: TextStyle(
                                          color: Colors.blueGrey[200],
                                          fontSize: 11,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const Spacer(),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: accent,
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => HomeScreen(
                                                initialIndex: index,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Acessar console',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

