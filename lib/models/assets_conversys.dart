class ProdutoConversys {
  final int id;
  final int cliente;
  final String nome;
  final String marca;
  final String modelo;
  final String descricao;
  final String fichaTecnica;
  final String? manualInstrucoes;
  final String codigoInterno;
  final String tipo;
  final bool ativo;
  final String criadoEm;
  final String atualizadoEm;

  ProdutoConversys({
    required this.id,
    required this.cliente,
    required this.nome,
    required this.marca,
    required this.modelo,
    required this.descricao,
    required this.fichaTecnica,
    this.manualInstrucoes,
    required this.codigoInterno,
    required this.tipo,
    required this.ativo,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory ProdutoConversys.fromJson(Map<String, dynamic> json) {
    return ProdutoConversys(
      id: json['id'] as int,
      cliente: json['cliente'] as int,
      nome: (json['nome'] ?? '') as String,
      marca: (json['marca'] ?? '') as String,
      modelo: (json['modelo'] ?? '') as String,
      descricao: (json['descricao'] ?? '') as String,
      fichaTecnica: (json['ficha_tecnica'] ?? '') as String,
      manualInstrucoes: json['manual_instrucoes'] as String?,
      codigoInterno: (json['codigo_interno'] ?? '') as String,
      tipo: (json['tipo'] ?? 'HARDWARE') as String,
      ativo: json['ativo'] as bool? ?? true,
      criadoEm: (json['criado_em'] ?? '') as String,
      atualizadoEm: (json['atualizado_em'] ?? '') as String,
    );
  }
}

class AssetConversys {
  final int id;
  final int produto;
  final int cliente;
  final String serialNumber;
  final String partNumber;
  final String nomeExibicao;
  final String observacoes;
  final String criadoEm;
  final String atualizadoEm;

  AssetConversys({
    required this.id,
    required this.produto,
    required this.cliente,
    required this.serialNumber,
    required this.partNumber,
    required this.nomeExibicao,
    required this.observacoes,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory AssetConversys.fromJson(Map<String, dynamic> json) {
    return AssetConversys(
      id: json['id'] as int,
      produto: json['produto'] as int,
      cliente: json['cliente'] as int,
      serialNumber: (json['serial_number'] ?? '') as String,
      partNumber: (json['part_number'] ?? '') as String,
      nomeExibicao: (json['nome_exibicao'] ?? '') as String,
      observacoes: (json['observacoes'] ?? '') as String,
      criadoEm: (json['criado_em'] ?? '') as String,
      atualizadoEm: (json['atualizado_em'] ?? '') as String,
    );
  }
}

class MovimentacaoAssetConversys {
  final int id;
  final int asset;
  final int motivo;
  final String motivoNome;
  final int? destino;
  final String? destinoNome;
  final String responsavel;
  final String observacao;
  final int? registradoPor;
  final String? registradoPorNome;
  final String criadoEm;

  MovimentacaoAssetConversys({
    required this.id,
    required this.asset,
    required this.motivo,
    required this.motivoNome,
    this.destino,
    this.destinoNome,
    required this.responsavel,
    required this.observacao,
    this.registradoPor,
    this.registradoPorNome,
    required this.criadoEm,
  });

  factory MovimentacaoAssetConversys.fromJson(Map<String, dynamic> json) {
    return MovimentacaoAssetConversys(
      id: json['id'] as int,
      asset: json['asset'] as int,
      motivo: json['motivo'] as int,
      motivoNome: (json['motivo_nome'] ?? '') as String,
      destino: json['destino'] as int?,
      destinoNome: json['destino_nome'] as String?,
      responsavel: (json['responsavel'] ?? '') as String,
      observacao: (json['observacao'] ?? '') as String,
      registradoPor: json['registrado_por'] as int?,
      registradoPorNome: json['registrado_por_nome'] as String?,
      criadoEm: (json['criado_em'] ?? '') as String,
    );
  }
}

class MotivoMovimentacaoMini {
  final int id;
  final String nome;
  final int ordem;

  MotivoMovimentacaoMini({
    required this.id,
    required this.nome,
    required this.ordem,
  });

  factory MotivoMovimentacaoMini.fromJson(Map<String, dynamic> json) {
    return MotivoMovimentacaoMini(
      id: json['id'] as int,
      nome: (json['nome'] ?? '') as String,
      ordem: json['ordem'] as int? ?? 0,
    );
  }
}

class LocalEstoqueRow {
  final int id;
  final String nome;
  final String codigo;
  final bool ativo;

  LocalEstoqueRow({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.ativo,
  });

  factory LocalEstoqueRow.fromJson(Map<String, dynamic> json) {
    return LocalEstoqueRow(
      id: json['id'] as int,
      nome: (json['nome'] ?? '') as String,
      codigo: (json['codigo'] ?? '') as String,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}
