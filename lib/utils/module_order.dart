/// Ordem alinhada ao menu lateral do portal (de cima para baixo):
/// Home → Propostas → Projetos → Help Desk → Cloud → Observabilidade → Mist → Obs. Brain → Logs.
/// No grid "Meus serviços" (2 colunas), a sequência percorre esquerda→direita, linha a linha.
List<dynamic> orderModulesLikeWeb(List<dynamic> modules) {
  num rankOf(String nome) {
    final n = nome.toLowerCase().trim();
    // 0 Home
    if (n.contains('home') ||
        n.contains('início') ||
        n.contains('inicio')) {
      return 0;
    }
    // 1 Propostas
    if (n.contains('proposta')) return 1;
    // 2 Projetos
    if (n.contains('projeto') ||
        n.contains('tarefa') ||
        n.contains('board')) {
      return 2;
    }
    // 2.3 Assets / patrimônio (próximo a projetos no portal)
    if (n.contains('asset') ||
        n.contains('patrim') ||
        n.contains('invent')) {
      return 2.3;
    }
    // 2.5 Despesas (entre projetos e help desk, alinhado ao portal)
    if (n.contains('despesa') || n.contains('expense')) return 2.5;
    if (n.contains('marketplace')) return 2.6;
    // 3 Help Desk
    if (n.contains('helpdesk') || n.contains('help desk')) return 3;
    // 4 Cloud
    if (n.contains('cloud')) return 4;
    // 7 Obs. Brain (antes de "observability" genérico)
    if (n.contains('brain') ||
        n.contains('obs. brain') ||
        n.contains('observability brain')) {
      return 7;
    }
    // 5 Observabilidade
    if (n.contains('observabilidade') ||
        n.contains('zabbix') ||
        n.contains('grafana')) {
      return 5;
    }
    if (n.contains('observability')) return 5;
    // 6 Mist
    if (n.contains('mist')) return 6;
    // 8 Logs
    if (n.contains('logs')) return 8;
    if (n.contains('cliente')) return 100;
    return 999;
  }

  final copy = List<dynamic>.from(modules);
  copy.sort((a, b) {
    final na = (a is Map && a['nome'] is String) ? a['nome'] as String : '';
    final nb = (b is Map && b['nome'] is String) ? b['nome'] as String : '';
    final ra = rankOf(na);
    final rb = rankOf(nb);
    if (ra != rb) return ra.compareTo(rb);
    return na.toLowerCase().compareTo(nb.toLowerCase());
  });
  return copy;
}
