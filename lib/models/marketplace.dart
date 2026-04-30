int _intVal(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return 0;
}

class MarketplaceSubGrupo {
  final int id;
  final int grupo;
  final String nome;
  final String descricao;
  final int ordem;
  final bool ativo;

  MarketplaceSubGrupo({
    required this.id,
    required this.grupo,
    required this.nome,
    required this.descricao,
    required this.ordem,
    required this.ativo,
  });

  factory MarketplaceSubGrupo.fromJson(Map<String, dynamic> json) {
    return MarketplaceSubGrupo(
      id: _intVal(json['id']),
      grupo: _intVal(json['grupo']),
      nome: (json['nome'] ?? '') as String,
      descricao: (json['descricao'] ?? '') as String,
      ordem: _intVal(json['ordem']),
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

class MarketplaceGrupo {
  final int id;
  final String nome;
  final String descricao;
  final int ordem;
  final bool ativo;
  final List<MarketplaceSubGrupo> subgrupos;

  MarketplaceGrupo({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.ordem,
    required this.ativo,
    required this.subgrupos,
  });

  factory MarketplaceGrupo.fromJson(Map<String, dynamic> json) {
    final raw = json['subgrupos'];
    final subs = <MarketplaceSubGrupo>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          subs.add(MarketplaceSubGrupo.fromJson(e));
        }
      }
    }
    return MarketplaceGrupo(
      id: _intVal(json['id']),
      nome: (json['nome'] ?? '') as String,
      descricao: (json['descricao'] ?? '') as String,
      ordem: _intVal(json['ordem']),
      ativo: json['ativo'] as bool? ?? true,
      subgrupos: subs,
    );
  }
}

class MarketplaceProduto {
  final int id;
  final int grupo;
  final int subgrupo;
  final String descricaoCurta;
  final String descricaoLonga;
  final bool ativo;
  final String? precoValorAtual;
  final String? precoPeriodo;

  MarketplaceProduto({
    required this.id,
    required this.grupo,
    required this.subgrupo,
    required this.descricaoCurta,
    required this.descricaoLonga,
    required this.ativo,
    this.precoValorAtual,
    this.precoPeriodo,
  });

  factory MarketplaceProduto.fromJson(Map<String, dynamic> json) {
    return MarketplaceProduto(
      id: _intVal(json['id']),
      grupo: _intVal(json['grupo']),
      subgrupo: _intVal(json['subgrupo']),
      descricaoCurta: (json['descricao_curta'] ?? '') as String,
      descricaoLonga: (json['descricao_longa'] ?? '') as String,
      ativo: json['ativo'] as bool? ?? true,
      precoValorAtual: json['preco_valor_atual']?.toString(),
      precoPeriodo: json['preco_periodo']?.toString(),
    );
  }
}

class MarketplaceCestaItem {
  final int id;
  final int cliente;
  final int catalogoProduto;
  final String? produtoDescricaoCurta;
  final String vigenciaInicio;
  final String vigenciaFim;
  final String criadoEm;

  MarketplaceCestaItem({
    required this.id,
    required this.cliente,
    required this.catalogoProduto,
    this.produtoDescricaoCurta,
    required this.vigenciaInicio,
    required this.vigenciaFim,
    required this.criadoEm,
  });

  factory MarketplaceCestaItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceCestaItem(
      id: _intVal(json['id']),
      cliente: _intVal(json['cliente']),
      catalogoProduto: _intVal(json['catalogo_produto']),
      produtoDescricaoCurta: json['produto_descricao_curta'] as String?,
      vigenciaInicio: (json['vigencia_inicio'] ?? '') as String,
      vigenciaFim: (json['vigencia_fim'] ?? '') as String,
      criadoEm: (json['criado_em'] ?? '') as String,
    );
  }
}

class MarketplaceSaldoCliente {
  final int id;
  final int cliente;
  final String? clienteNome;
  final String creditoDisponivel;

  MarketplaceSaldoCliente({
    required this.id,
    required this.cliente,
    this.clienteNome,
    required this.creditoDisponivel,
  });

  factory MarketplaceSaldoCliente.fromJson(Map<String, dynamic> json) {
    return MarketplaceSaldoCliente(
      id: _intVal(json['id']),
      cliente: _intVal(json['cliente']),
      clienteNome: json['cliente_nome'] as String?,
      creditoDisponivel: (json['credito_disponivel'] ?? '0').toString(),
    );
  }
}

class MarketplaceMovimentacaoFinanceira {
  final int id;
  final int cliente;
  final String tipo;
  final String valor;
  final String descricao;
  final String saldoAposMovimento;
  final int? catalogoProduto;
  final String? produtoDescricaoCurta;
  final String criadoEm;

  MarketplaceMovimentacaoFinanceira({
    required this.id,
    required this.cliente,
    required this.tipo,
    required this.valor,
    required this.descricao,
    required this.saldoAposMovimento,
    this.catalogoProduto,
    this.produtoDescricaoCurta,
    required this.criadoEm,
  });

  factory MarketplaceMovimentacaoFinanceira.fromJson(Map<String, dynamic> json) {
    return MarketplaceMovimentacaoFinanceira(
      id: _intVal(json['id']),
      cliente: _intVal(json['cliente']),
      tipo: (json['tipo'] ?? '') as String,
      valor: (json['valor'] ?? '0').toString(),
      descricao: (json['descricao'] ?? '') as String,
      saldoAposMovimento: (json['saldo_apos_movimento'] ?? '0').toString(),
      catalogoProduto: json['catalogo_produto'] == null
          ? null
          : _intVal(json['catalogo_produto']),
      produtoDescricaoCurta: json['produto_descricao_curta'] as String?,
      criadoEm: (json['criado_em'] ?? '') as String,
    );
  }
}
