class Notificacao {
  final int id;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime? criadaEm;

  Notificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    this.criadaEm,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    DateTime? criada;
    final rawCriada = json['criada_em'] ?? json['created_at'];
    if (rawCriada is String && rawCriada.isNotEmpty) {
      try {
        criada = DateTime.parse(rawCriada);
      } catch (_) {
        criada = null;
      }
    }

    return Notificacao(
      id: json['id'] as int,
      titulo: (json['titulo'] ?? json['title'] ?? '') as String,
      mensagem: (json['mensagem'] ?? json['message'] ?? '') as String,
      lida: (json['lida'] ?? json['read'] ?? false) as bool,
      criadaEm: criada,
    );
  }
}

