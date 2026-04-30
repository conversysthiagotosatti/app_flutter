import '../models/assets_conversys.dart';

enum AssetsProdSortKey {
  nome,
  marca,
  modelo,
  tipo,
  codigoInterno,
  ativo,
  atualizadoEm,
  descricao,
  fichaTecnica,
}

enum AssetsAssetSortKey {
  produto,
  serialNumber,
  partNumber,
  nomeExibicao,
  atualizadoEm,
}

enum AssetsMovSortKey {
  criadoEm,
  assetLabel,
  motivoNome,
  destinoNome,
  responsavel,
  registradoPorNome,
  observacao,
}

int _cmpDateIso(String a, String b) {
  final da = DateTime.tryParse(a);
  final db = DateTime.tryParse(b);
  if (da == null && db == null) return 0;
  if (da == null) return -1;
  if (db == null) return 1;
  return da.compareTo(db);
}

int compareAssetsProdutos(
  ProdutoConversys a,
  ProdutoConversys b,
  AssetsProdSortKey key,
  bool asc,
) {
  final m = asc ? 1 : -1;
  switch (key) {
    case AssetsProdSortKey.nome:
      return m * a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    case AssetsProdSortKey.marca:
      return m *
          (a.marca).toLowerCase().compareTo((b.marca).toLowerCase());
    case AssetsProdSortKey.modelo:
      return m *
          (a.modelo).toLowerCase().compareTo((b.modelo).toLowerCase());
    case AssetsProdSortKey.tipo:
      return m * a.tipo.compareTo(b.tipo);
    case AssetsProdSortKey.codigoInterno:
      return m *
          a.codigoInterno
              .toLowerCase()
              .compareTo(b.codigoInterno.toLowerCase());
    case AssetsProdSortKey.ativo:
      if (a.ativo == b.ativo) return 0;
      return m * (a.ativo ? 1 : -1);
    case AssetsProdSortKey.atualizadoEm:
      return m * _cmpDateIso(a.atualizadoEm, b.atualizadoEm);
    case AssetsProdSortKey.descricao:
      return m *
          (a.descricao)
              .toLowerCase()
              .compareTo((b.descricao).toLowerCase());
    case AssetsProdSortKey.fichaTecnica:
      return m *
          (a.fichaTecnica)
              .toLowerCase()
              .compareTo((b.fichaTecnica).toLowerCase());
  }
}

int compareAssetsRows(
  AssetConversys a,
  AssetConversys b,
  AssetsAssetSortKey key,
  bool asc,
  Map<int, String> produtoNomeMap,
) {
  final m = asc ? 1 : -1;
  String nomeProd(int id) =>
      (produtoNomeMap[id] ?? '#$id').toLowerCase();
  switch (key) {
    case AssetsAssetSortKey.produto:
      return m *
          nomeProd(a.produto).compareTo(nomeProd(b.produto));
    case AssetsAssetSortKey.serialNumber:
      return m *
          a.serialNumber
              .toLowerCase()
              .compareTo(b.serialNumber.toLowerCase());
    case AssetsAssetSortKey.partNumber:
      return m *
          a.partNumber
              .toLowerCase()
              .compareTo(b.partNumber.toLowerCase());
    case AssetsAssetSortKey.nomeExibicao:
      return m *
          a.nomeExibicao
              .toLowerCase()
              .compareTo(b.nomeExibicao.toLowerCase());
    case AssetsAssetSortKey.atualizadoEm:
      return m * _cmpDateIso(a.atualizadoEm, b.atualizadoEm);
  }
}

String movimentacaoAssetLabel(
  MovimentacaoAssetConversys m,
  List<AssetConversys> assetsList,
  Map<int, String> produtoNomeMap,
) {
  AssetConversys? a;
  for (final x in assetsList) {
    if (x.id == m.asset) {
      a = x;
      break;
    }
  }
  if (a == null) return '#${m.asset}';
  final bits = [a.serialNumber, a.partNumber]
      .where((x) => x.trim().isNotEmpty)
      .join(' / ');
  final tag = bits.isEmpty ? 'ID ${a.id}' : bits;
  final nome = a.nomeExibicao.trim();
  final prod = produtoNomeMap[a.produto] ?? 'Produto #${a.produto}';
  return nome.isNotEmpty ? '$nome — $tag ($prod)' : '$tag ($prod)';
}

int compareMovRows(
  MovimentacaoAssetConversys a,
  MovimentacaoAssetConversys b,
  AssetsMovSortKey key,
  bool asc,
  List<AssetConversys> assetsList,
  Map<int, String> produtoNomeMap,
) {
  final m = asc ? 1 : -1;
  switch (key) {
    case AssetsMovSortKey.criadoEm:
      return m * _cmpDateIso(a.criadoEm, b.criadoEm);
    case AssetsMovSortKey.assetLabel:
      return m *
          movimentacaoAssetLabel(a, assetsList, produtoNomeMap)
              .toLowerCase()
              .compareTo(
                movimentacaoAssetLabel(b, assetsList, produtoNomeMap)
                    .toLowerCase(),
              );
    case AssetsMovSortKey.motivoNome:
      return m *
          (a.motivoNome)
              .toLowerCase()
              .compareTo((b.motivoNome).toLowerCase());
    case AssetsMovSortKey.destinoNome:
      return m *
          (a.destinoNome ?? '')
              .toLowerCase()
              .compareTo((b.destinoNome ?? '').toLowerCase());
    case AssetsMovSortKey.responsavel:
      return m *
          (a.responsavel)
              .toLowerCase()
              .compareTo((b.responsavel).toLowerCase());
    case AssetsMovSortKey.registradoPorNome:
      return m *
          (a.registradoPorNome ?? '')
              .toLowerCase()
              .compareTo((b.registradoPorNome ?? '').toLowerCase());
    case AssetsMovSortKey.observacao:
      return m *
          (a.observacao)
              .toLowerCase()
              .compareTo((b.observacao).toLowerCase());
  }
}
