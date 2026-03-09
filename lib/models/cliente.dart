class Cliente {
  final int id;
  final String nome;
  final String? documento;
  final String? email;
  final String? telefone;
  final bool ativo;

  Cliente({
    required this.id,
    required this.nome,
    this.documento,
    this.email,
    this.telefone,
    required this.ativo,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
      documento: json['documento'] as String?,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

