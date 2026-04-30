import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/assets_conversys.dart';
import '../services/api_client.dart';
import '../services/assets_conversys_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'assets_control_sort.dart';
import 'notificacoes_screen.dart';

class _ClienteOption {
  final int id;
  final String nome;

  _ClienteOption({required this.id, required this.nome});
}

/// Controle de assets (portal: `AssetsControlModule.tsx`).
class AssetsControlModuleScreen extends StatefulWidget {
  final ApiClient apiClient;

  const AssetsControlModuleScreen({super.key, required this.apiClient});

  @override
  State<AssetsControlModuleScreen> createState() =>
      _AssetsControlModuleScreenState();
}

class _AssetsControlModuleScreenState extends State<AssetsControlModuleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final AssetsConversysService _svc;

  List<_ClienteOption> _clientes = [];
  int? _clienteId;
  bool _loadingClients = true;
  String? _clientErr;

  List<ProdutoConversys> _produtos = [];
  String _prodSearch = '';
  String _prodTipo = '';
  String _prodAtivo = 'all';

  /// Lista completa de ativos do cliente (igual ao portal: movimentações usam todos).
  List<AssetConversys> _allAssets = [];
  String _assetSearch = '';
  int? _assetProdutoFiltro;

  AssetsProdSortKey _prodSortKey = AssetsProdSortKey.nome;
  bool _prodSortAsc = true;

  AssetsAssetSortKey _assetSortKey = AssetsAssetSortKey.atualizadoEm;
  bool _assetSortAsc = false;

  AssetsMovSortKey _movSortKey = AssetsMovSortKey.criadoEm;
  bool _movSortAsc = false;

  List<MovimentacaoAssetConversys> _movs = [];
  String _movSearch = '';
  int? _movAssetFiltro;

  List<MotivoMovimentacaoMini> _motivos = [];
  List<LocalEstoqueRow> _locais = [];

  bool _busy = false;

  late final TextEditingController _prodSearchCtrl;
  late final TextEditingController _assetSearchCtrl;
  late final TextEditingController _movSearchCtrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _svc = AssetsConversysService(widget.apiClient);
    _prodSearchCtrl = TextEditingController();
    _assetSearchCtrl = TextEditingController();
    _movSearchCtrl = TextEditingController();
    _prodSearchCtrl.addListener(() {
      final t = _prodSearchCtrl.text;
      if (t != _prodSearch) setState(() => _prodSearch = t);
    });
    _assetSearchCtrl.addListener(() {
      final t = _assetSearchCtrl.text;
      if (t != _assetSearch) setState(() => _assetSearch = t);
    });
    _movSearchCtrl.addListener(() {
      final t = _movSearchCtrl.text;
      if (t != _movSearch) setState(() => _movSearch = t);
    });
    _bootstrap();
  }

  @override
  void dispose() {
    _prodSearchCtrl.dispose();
    _assetSearchCtrl.dispose();
    _movSearchCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _clearProdFilters() {
    setState(() {
      _prodTipo = '';
      _prodAtivo = 'all';
      _prodSearch = '';
    });
    _prodSearchCtrl.clear();
  }

  void _clearAssetFilters() {
    setState(() {
      _assetProdutoFiltro = null;
      _assetSearch = '';
    });
    _assetSearchCtrl.clear();
  }

  void _clearMovFilters() {
    setState(() {
      _movAssetFiltro = null;
      _movSearch = '';
    });
    _movSearchCtrl.clear();
    final cid = _clienteId;
    if (cid != null) _reloadMovs(cid);
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingClients = true;
      _clientErr = null;
    });
    try {
      final r = await widget.apiClient.get('/api/auth/me/clients/');
      if (r.statusCode != 200) {
        throw Exception('HTTP ${r.statusCode}');
      }
      final decoded = jsonDecode(r.body);
      if (decoded is! List) throw Exception('Lista inválida');
      final opts = <_ClienteOption>[];
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final id = e['cliente_id'];
        final nome = e['cliente_nome']?.toString() ?? '';
        int? cid;
        if (id is int) {
          cid = id;
        } else if (id is num) {
          cid = id.toInt();
        }
        if (cid != null && nome.isNotEmpty) {
          opts.add(_ClienteOption(id: cid, nome: nome));
        }
      }
      final saved = await widget.apiClient.loadAuthClienteId();
      int? pick = saved;
      if (pick != null && !opts.any((o) => o.id == pick)) pick = null;
      pick ??= opts.isNotEmpty ? opts.first.id : null;
      if (!mounted) return;
      setState(() {
        _clientes = opts;
        _clienteId = pick;
        _loadingClients = false;
      });
      if (pick != null) await _reloadAll(pick);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingClients = false;
        _clientErr = e.toString();
      });
    }
  }

  Future<void> _reloadAll(int cid) async {
    setState(() => _busy = true);
    try {
      final results = await Future.wait([
        _svc.fetchProdutos(cid),
        _svc.fetchAssets(cid),
        _svc.fetchMovimentacoes(cid, assetId: _movAssetFiltro),
        _svc.fetchMotivosMovimentacao(),
        _svc.fetchLocaisEstoque(cid),
      ]);
      if (!mounted) return;
      setState(() {
        _produtos = results[0] as List<ProdutoConversys>;
        _allAssets = results[1] as List<AssetConversys>;
        _movs = results[2] as List<MovimentacaoAssetConversys>;
        final motList =
            List<MotivoMovimentacaoMini>.from(results[3] as List<MotivoMovimentacaoMini>)
              ..sort((a, b) {
                final o = a.ordem.compareTo(b.ordem);
                return o != 0 ? o : a.nome.compareTo(b.nome);
              });
        _motivos = motList;
        _locais = results[4] as List<LocalEstoqueRow>;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _reloadMovs(int cid) async {
    final list = await _svc.fetchMovimentacoes(
      cid,
      assetId: _movAssetFiltro,
    );
    if (mounted) setState(() => _movs = list);
  }

  String _mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    final base = ApiClient.baseUrl.replaceAll(RegExp(r'/$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return '$base$p';
  }

  String _nomeProd(int id) {
    for (final p in _produtos) {
      if (p.id == id) return p.nome;
    }
    return '#$id';
  }

  String _assetLabel(AssetConversys a) {
    final bits = [a.serialNumber, a.partNumber]
        .where((x) => x.trim().isNotEmpty)
        .join(' / ');
    final tag = bits.isEmpty ? 'ID ${a.id}' : bits;
    final nome = a.nomeExibicao.trim();
    final prod = _nomeProd(a.produto);
    return nome.isNotEmpty ? '$nome — $tag ($prod)' : '$tag ($prod)';
  }

  Map<int, String> _produtoNomeMap() {
    final m = <int, String>{};
    for (final p in _produtos) {
      m[p.id] = p.nome;
    }
    return m;
  }

  String? _produtoTipo(int id) {
    for (final p in _produtos) {
      if (p.id == id) return p.tipo;
    }
    return null;
  }

  String _formatDt(BuildContext context, String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final loc = Localizations.localeOf(context);
    return DateFormat.yMd(loc.toLanguageTag()).add_Hm().format(dt.toLocal());
  }

  String _localLabel(LocalEstoqueRow l) {
    final c = l.codigo.trim();
    return c.isNotEmpty ? '${l.nome} ($c)' : l.nome;
  }

  void _cycleProdSort(AssetsProdSortKey key) {
    setState(() {
      if (_prodSortKey != key) {
        _prodSortKey = key;
        _prodSortAsc = key != AssetsProdSortKey.atualizadoEm;
      } else {
        _prodSortAsc = !_prodSortAsc;
      }
    });
  }

  void _cycleAssetSort(AssetsAssetSortKey key) {
    setState(() {
      if (_assetSortKey != key) {
        _assetSortKey = key;
        _assetSortAsc = key != AssetsAssetSortKey.atualizadoEm;
      } else {
        _assetSortAsc = !_assetSortAsc;
      }
    });
  }

  void _cycleMovSort(AssetsMovSortKey key) {
    setState(() {
      if (_movSortKey != key) {
        _movSortKey = key;
        _movSortAsc = key != AssetsMovSortKey.criadoEm;
      } else {
        _movSortAsc = !_movSortAsc;
      }
    });
  }

  Widget _sortHeaderIcon(AssetsProdSortKey key) {
    if (_prodSortKey != key) {
      return const Icon(Icons.unfold_more, size: 16, color: Colors.white38);
    }
    return Icon(
      _prodSortAsc ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
      color: Colors.tealAccent,
    );
  }

  Widget _sortHeaderIconAsset(AssetsAssetSortKey key) {
    if (_assetSortKey != key) {
      return const Icon(Icons.unfold_more, size: 16, color: Colors.white38);
    }
    return Icon(
      _assetSortAsc ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
      color: Colors.tealAccent,
    );
  }

  Widget _sortHeaderIconMov(AssetsMovSortKey key) {
    if (_movSortKey != key) {
      return const Icon(Icons.unfold_more, size: 16, color: Colors.white38);
    }
    return Icon(
      _movSortAsc ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
      color: Colors.tealAccent,
    );
  }

  List<ProdutoConversys> _produtosFiltradosSorted() {
    final filtered = _produtos.where((p) {
      if (_prodTipo.isNotEmpty && p.tipo != _prodTipo) return false;
      if (_prodAtivo == 'active' && !p.ativo) return false;
      if (_prodAtivo == 'inactive' && p.ativo) return false;
      final q = _prodSearch.trim().toLowerCase();
      if (q.isEmpty) return true;
      final blob = [
        p.nome,
        p.marca,
        p.modelo,
        p.codigoInterno,
        p.descricao,
        p.fichaTecnica,
      ].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
    filtered.sort(
      (a, b) => compareAssetsProdutos(a, b, _prodSortKey, _prodSortAsc),
    );
    return filtered;
  }

  List<AssetConversys> _assetsFiltradosSorted() {
    final map = _produtoNomeMap();
    final q = _assetSearch.trim().toLowerCase();
    final filtered = _allAssets.where((a) {
      if (_assetProdutoFiltro != null && a.produto != _assetProdutoFiltro) {
        return false;
      }
      if (q.isEmpty) return true;
      final blob = [
        '${a.produto}',
        map[a.produto] ?? '',
        a.serialNumber,
        a.partNumber,
        a.nomeExibicao,
        a.observacoes,
      ].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
    filtered.sort(
      (a, b) => compareAssetsRows(a, b, _assetSortKey, _assetSortAsc, map),
    );
    return filtered;
  }

  List<MovimentacaoAssetConversys> _movsFiltradasSorted() {
    final q = _movSearch.trim().toLowerCase();
    final map = _produtoNomeMap();
    final filtered = _movs.where((m) {
      if (q.isEmpty) return true;
      final label = movimentacaoAssetLabel(m, _allAssets, map);
      final blob = [
        label,
        m.motivoNome,
        m.destinoNome ?? '',
        m.responsavel,
        m.observacao,
        m.registradoPorNome ?? '',
      ].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
    filtered.sort(
      (a, b) => compareMovRows(
        a,
        b,
        _movSortKey,
        _movSortAsc,
        _allAssets,
        map,
      ),
    );
    return filtered;
  }

  Future<void> _openNovoProduto(AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null) return;
    final nome = TextEditingController();
    final marca = TextEditingController();
    final modelo = TextEditingController();
    final codigo = TextEditingController();
    final desc = TextEditingController();
    final ficha = TextEditingController();
    var tipo = 'HARDWARE';
    PlatformFile? manual;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (ctx, setSt) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.assetsInsertProduct,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _tf(nome, l10n.assetsFieldName),
                    _tf(marca, l10n.assetsFieldBrand),
                    _tf(modelo, l10n.assetsFieldModel),
                    _tf(codigo, l10n.assetsFieldInternalCode),
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      dropdownColor: const Color(0xFF0B1220),
                      style: const TextStyle(color: Colors.white),
                      decoration: _dec(l10n.assetsFieldType),
                      items: [
                        DropdownMenuItem(
                          value: 'HARDWARE',
                          child: Text(l10n.assetsTypeHardware),
                        ),
                        DropdownMenuItem(
                          value: 'SERVICO',
                          child: Text(l10n.assetsTypeService),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setSt(() => tipo = v);
                      },
                    ),
                    _tf(desc, l10n.assetsFieldDescription, maxLines: 2),
                    _tf(ficha, l10n.assetsFieldDatasheet, maxLines: 2),
                    ListTile(
                      title: Text(
                        manual?.name ?? l10n.assetsFieldManual,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.attach_file, color: Colors.teal),
                      onTap: () async {
                        final r = await FilePicker.platform.pickFiles(
                          withData: true,
                        );
                        if (r != null && r.files.isNotEmpty) {
                          setSt(() => manual = r.files.first);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        if (nome.text.trim().isEmpty) return;
                        try {
                          final files = <http.MultipartFile>[];
                          final picked = manual;
                          if (picked?.bytes != null) {
                            files.add(
                              http.MultipartFile.fromBytes(
                                'manual_instrucoes',
                                picked!.bytes!,
                                filename: picked.name,
                              ),
                            );
                          }
                          await _svc.createProduto(
                            cid,
                            fields: {
                              'nome': nome.text.trim(),
                              'tipo': tipo,
                              'codigo_interno': codigo.text.trim(),
                              'marca': marca.text.trim(),
                              'modelo': modelo.text.trim(),
                              'descricao': desc.text.trim(),
                              'ficha_tecnica': ficha.text.trim(),
                            },
                            files: files,
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        }
                      },
                      child: Text(l10n.assetsSaveProduct),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (ok == true && mounted) {
      await _reloadAll(cid);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        border: const OutlineInputBorder(),
      );

  Widget _tf(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _dec(label),
      ),
    );
  }

  Future<void> _openNovoAsset(AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null || _produtos.isEmpty) return;
    int? pid = _produtos.first.id;
    final sn = TextEditingController();
    final pn = TextEditingController();
    final nome = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.assetsInsertAsset,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: pid,
                      decoration: _dec(l10n.assetsFieldProduct),
                      dropdownColor: const Color(0xFF0B1220),
                      style: const TextStyle(color: Colors.white),
                      items: _produtos
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.nome} (${p.tipo})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSt(() => pid = v),
                    ),
                    _tf(sn, l10n.assetsSerial),
                    _tf(pn, l10n.assetsPartNumber),
                    _tf(nome, l10n.assetsDisplayName),
                    FilledButton(
                      onPressed: pid == null
                          ? null
                          : () async {
                              final tipoP = _produtoTipo(pid!);
                              if (tipoP == 'SERVICO' &&
                                  sn.text.trim().isEmpty &&
                                  pn.text.trim().isEmpty) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.assetsServiceSerialOrPart,
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              try {
                                await _svc.createAsset(cid, {
                                  'produto': pid,
                                  'serial_number': sn.text.trim(),
                                  'part_number': pn.text.trim(),
                                  'nome_exibicao': nome.text.trim(),
                                  'observacoes': '',
                                });
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('$e')),
                                  );
                                }
                              }
                            },
                      child: Text(l10n.assetsSaveAsset),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (ok == true && mounted) await _reloadAll(cid);
  }

  Future<void> _openNovaMov(AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null) return;
    if (_allAssets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.assetsAssetsEmpty)),
      );
      return;
    }
    int? aid;
    int? mid = _motivos.isEmpty ? null : _motivos.first.id;
    int? lid = _locais.isEmpty ? null : _locais.first.id;
    final resp = TextEditingController();
    final obs = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final canSubmit =
                aid != null && mid != null && lid != null;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.assetsNewMovement,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: aid,
                    decoration: _dec(l10n.assetsFieldSelectAsset),
                    dropdownColor: const Color(0xFF0B1220),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          l10n.assetsPickAsset,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ..._allAssets.map(
                        (a) => DropdownMenuItem<int?>(
                          value: a.id,
                          child: Text(
                            _assetLabel(a),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSt(() => aid = v),
                  ),
                  if (_motivos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        l10n.assetsNoMotives,
                        style: const TextStyle(color: Colors.amber, fontSize: 12),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: mid,
                      decoration: _dec(l10n.assetsMotivo),
                      dropdownColor: const Color(0xFF0B1220),
                      style: const TextStyle(color: Colors.white),
                      items: _motivos
                          .map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.nome),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSt(() => mid = v),
                    ),
                  if (_locais.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        l10n.assetsNoStockLocations,
                        style: const TextStyle(color: Colors.amber, fontSize: 12),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: lid,
                      decoration: _dec(l10n.assetsDestino),
                      dropdownColor: const Color(0xFF0B1220),
                      style: const TextStyle(color: Colors.white),
                      items: _locais
                          .map(
                            (l) => DropdownMenuItem(
                              value: l.id,
                              child: Text(_localLabel(l)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSt(() => lid = v),
                    ),
                  _tf(resp, l10n.assetsResponsible),
                  _tf(obs, l10n.assetsObservation, maxLines: 2),
                  FilledButton(
                    onPressed: !canSubmit
                        ? null
                        : () async {
                            try {
                              await _svc.createMovimentacao(cid, {
                                'asset': aid,
                                'motivo': mid,
                                'destino': lid,
                                'responsavel': resp.text.trim(),
                                'observacao': obs.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            }
                          },
                    child: Text(l10n.assetsSaveMovement),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (ok == true && mounted) await _reloadAll(cid);
  }

  Future<void> _editAsset(AssetConversys a, AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null) return;
    final sn = TextEditingController(text: a.serialNumber);
    final pn = TextEditingController(text: a.partNumber);
    final nome = TextEditingController(text: a.nomeExibicao);
    final obs = TextEditingController(text: a.observacoes);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.assetsEditAsset),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sn,
                decoration: InputDecoration(labelText: l10n.assetsSerial),
              ),
              TextField(
                controller: pn,
                decoration: InputDecoration(labelText: l10n.assetsPartNumber),
              ),
              TextField(
                controller: nome,
                decoration: InputDecoration(labelText: l10n.assetsDisplayName),
              ),
              TextField(
                controller: obs,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.assetsObservation),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await _svc.patchAsset(cid, a.id, {
          'serial_number': sn.text.trim(),
          'part_number': pn.text.trim(),
          'nome_exibicao': nome.text.trim(),
          'observacoes': obs.text.trim(),
        });
        await _reloadAll(cid);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        }
      }
    }
  }

  Future<void> _editProduto(ProdutoConversys p, AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null) return;
    final nome = TextEditingController(text: p.nome);
    final marca = TextEditingController(text: p.marca);
    final modelo = TextEditingController(text: p.modelo);
    final codigo = TextEditingController(text: p.codigoInterno);
    final desc = TextEditingController(text: p.descricao);
    final ficha = TextEditingController(text: p.fichaTecnica);
    var tipo = p.tipo;
    var ativo = p.ativo;
    PlatformFile? newManual;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: Text(l10n.assetsEditProduct),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nome,
                    decoration: InputDecoration(labelText: l10n.assetsFieldName),
                  ),
                  DropdownButton<String>(
                    value: tipo,
                    dropdownColor: const Color(0xFF0B1220),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem(
                        value: 'HARDWARE',
                        child: Text(l10n.assetsTypeHardware),
                      ),
                      DropdownMenuItem(
                        value: 'SERVICO',
                        child: Text(l10n.assetsTypeService),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setSt(() => tipo = v);
                    },
                  ),
                  TextField(
                    controller: codigo,
                    decoration: InputDecoration(
                      labelText: l10n.assetsFieldInternalCode,
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.assetsColActive),
                    value: ativo,
                    onChanged: (v) => setSt(() => ativo = v),
                  ),
                  TextField(
                    controller: marca,
                    decoration: InputDecoration(labelText: l10n.assetsFieldBrand),
                  ),
                  TextField(
                    controller: modelo,
                    decoration: InputDecoration(labelText: l10n.assetsFieldModel),
                  ),
                  TextField(
                    controller: desc,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.assetsFieldDescription,
                    ),
                  ),
                  TextField(
                    controller: ficha,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.assetsFieldDatasheet,
                    ),
                  ),
                  ListTile(
                    title: Text(
                      newManual?.name ?? l10n.assetsReplaceManualHint,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: const Icon(Icons.attach_file, color: Colors.teal),
                    onTap: () async {
                      final r = await FilePicker.platform.pickFiles(
                        withData: true,
                      );
                      if (r != null && r.files.isNotEmpty) {
                        setSt(() => newManual = r.files.first);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.continueLabel),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final files = <http.MultipartFile>[];
      final picked = newManual;
      if (picked?.bytes != null) {
        files.add(
          http.MultipartFile.fromBytes(
            'manual_instrucoes',
            picked!.bytes!,
            filename: picked.name,
          ),
        );
      }
      await _svc.patchProduto(
        cid,
        p.id,
        fields: {
          'nome': nome.text.trim(),
          'tipo': tipo,
          'codigo_interno': codigo.text.trim(),
          'marca': marca.text.trim(),
          'modelo': modelo.text.trim(),
          'descricao': desc.text.trim(),
          'ficha_tecnica': ficha.text.trim(),
          'ativo': ativo ? 'true' : 'false',
        },
        files: files,
      );
      await _reloadAll(cid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(
        context,
        l10n.assetsModuleTitle,
        userAccountMenuApiClient: widget.apiClient,
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      backgroundColor: bg,
      body: _loadingClients
          ? const Center(child: CircularProgressIndicator())
          : _clientes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _clientErr ?? l10n.assetsNoClient,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _clienteId,
                              decoration: InputDecoration(
                                labelText: l10n.expenseSelectClient,
                                labelStyle: const TextStyle(color: Colors.white54),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              dropdownColor: const Color(0xFF0B1220),
                              style: const TextStyle(color: Colors.white),
                              items: _clientes
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(
                                        c.nome,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) async {
                                if (id == null) return;
                                await widget.apiClient.saveAuthClienteContext(
                                  clienteId: id,
                                  clienteNome: _clientes
                                      .firstWhere((e) => e.id == id)
                                      .nome,
                                );
                                setState(() {
                                  _clienteId = id;
                                  _movAssetFiltro = null;
                                  _assetProdutoFiltro = null;
                                });
                                await _reloadAll(id);
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: _clienteId == null || _busy
                                ? null
                                : () => _reloadAll(_clienteId!),
                            icon: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabs,
                      labelColor: Colors.tealAccent,
                      unselectedLabelColor: Colors.white54,
                      tabs: [
                        Tab(text: l10n.assetsTabProducts),
                        Tab(text: l10n.assetsTabAssets),
                        Tab(text: l10n.assetsTabMovements),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _buildProdutosTab(context, l10n),
                          _buildAssetsTab(context, l10n),
                          _buildMovsTab(context, l10n),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _prodSortableHeader(String label, AssetsProdSortKey key) {
    return InkWell(
      onTap: () => _cycleProdSort(key),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 2),
          _sortHeaderIcon(key),
        ],
      ),
    );
  }

  Widget _assetSortableHeader(String label, AssetsAssetSortKey key) {
    return InkWell(
      onTap: () => _cycleAssetSort(key),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 2),
          _sortHeaderIconAsset(key),
        ],
      ),
    );
  }

  Widget _movSortableHeader(String label, AssetsMovSortKey key) {
    return InkWell(
      onTap: () => _cycleMovSort(key),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 2),
          _sortHeaderIconMov(key),
        ],
      ),
    );
  }

  Widget _buildProdutosTab(BuildContext context, AppLocalizations l10n) {
    final rows = _produtosFiltradosSorted();
    const emDash = '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prodSearchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.assetsFilterSearch,
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _prodTipo.isEmpty ? '' : _prodTipo,
                hint: Text(
                  l10n.assetsFilterTipoAll,
                  style: const TextStyle(color: Colors.white54),
                ),
                dropdownColor: const Color(0xFF0B1220),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(l10n.assetsFilterTipoAll),
                  ),
                  DropdownMenuItem(
                    value: 'HARDWARE',
                    child: Text(l10n.assetsTypeHardware),
                  ),
                  DropdownMenuItem(
                    value: 'SERVICO',
                    child: Text(l10n.assetsTypeService),
                  ),
                ],
                onChanged: (v) => setState(() => _prodTipo = v ?? ''),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: Text(l10n.assetsFilterAtivoAll),
                selected: _prodAtivo == 'all',
                onSelected: (_) => setState(() => _prodAtivo = 'all'),
              ),
              ChoiceChip(
                label: Text(l10n.assetsFilterAtivoYes),
                selected: _prodAtivo == 'active',
                onSelected: (_) => setState(() => _prodAtivo = 'active'),
              ),
              ChoiceChip(
                label: Text(l10n.assetsFilterAtivoNo),
                selected: _prodAtivo == 'inactive',
                onSelected: (_) => setState(() => _prodAtivo = 'inactive'),
              ),
              TextButton(
                onPressed: _clearProdFilters,
                child: Text(l10n.assetsClearFilters),
              ),
              TextButton.icon(
                onPressed: _clienteId == null || _busy
                    ? null
                    : () => _reloadAll(_clienteId!),
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
                label: Text(
                  l10n.expenseRefresh,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                onPressed: () => _openNovoProduto(l10n),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            _produtos.isEmpty
                ? l10n.assetsListProducts
                : '${l10n.assetsListProducts} (${rows.length}/${_produtos.length})',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _produtos.isEmpty
                          ? l10n.assetsProductsEmpty
                          : l10n.assetsEmptyProductsFiltered,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth.clamp(600, 1400),
                        ),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFF0F172A),
                            ),
                            dataTextStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            columnSpacing: 12,
                            columns: [
                              DataColumn(
                                label: _prodSortableHeader(
                                  l10n.assetsColName,
                                  AssetsProdSortKey.nome,
                                ),
                              ),
                              DataColumn(
                                label: _prodSortableHeader(
                                  l10n.assetsColBrand,
                                  AssetsProdSortKey.marca,
                                ),
                              ),
                              DataColumn(
                                label: _prodSortableHeader(
                                  l10n.assetsColModel,
                                  AssetsProdSortKey.modelo,
                                ),
                              ),
                              DataColumn(
                                label: _prodSortableHeader(
                                  l10n.assetsColDescription,
                                  AssetsProdSortKey.descricao,
                                ),
                              ),
                              DataColumn(
                                label: _prodSortableHeader(
                                  l10n.assetsColDatasheet,
                                  AssetsProdSortKey.fichaTecnica,
                                ),
                              ),
                              DataColumn(label: Text(l10n.assetsColManual)),
                              DataColumn(
                                label: _prodSortableHeader(
                                  l10n.assetsColType,
                                  AssetsProdSortKey.tipo,
                                ),
                              ),
                              DataColumn(
                                label: _prodSortableHeader(
                                  l10n.assetsColCode,
                                  AssetsProdSortKey.codigoInterno,
                                ),
                              ),
                              DataColumn(
                                label: _prodSortableHeader(
                                  l10n.assetsColActive,
                                  AssetsProdSortKey.ativo,
                                ),
                              ),
                              DataColumn(
                                label: _prodSortableHeader(
                                  l10n.assetsColUpdated,
                                  AssetsProdSortKey.atualizadoEm,
                                ),
                              ),
                              DataColumn(label: Text(l10n.assetsColTracking)),
                            ],
                            rows: rows.map((p) {
                              final href = _mediaUrl(p.manualInstrucoes);
                              return DataRow(
                                cells: [
                                  DataCell(Text(p.nome)),
                                  DataCell(Text(p.marca.isEmpty ? emDash : p.marca)),
                                  DataCell(Text(p.modelo.isEmpty ? emDash : p.modelo)),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 160),
                                      child: Text(
                                        p.descricao.isEmpty ? emDash : p.descricao,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 140),
                                      child: Text(
                                        p.fichaTecnica.isEmpty ? emDash : p.fichaTecnica,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    href.isEmpty
                                        ? const Text(emDash)
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.download,
                                              color: Colors.teal,
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              final u = Uri.tryParse(href);
                                              if (u != null) {
                                                await launchUrl(
                                                  u,
                                                  mode: LaunchMode.externalApplication,
                                                );
                                              }
                                            },
                                          ),
                                  ),
                                  DataCell(Text(p.tipo)),
                                  DataCell(
                                    Text(
                                      p.codigoInterno.isEmpty ? emDash : p.codigoInterno,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      p.ativo
                                          ? l10n.assetsYesShort
                                          : l10n.assetsNoShort,
                                      style: TextStyle(
                                        color: p.ativo
                                            ? Colors.greenAccent
                                            : Colors.white38,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _formatDt(context, p.atualizadoEm),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.account_tree_outlined,
                                            color: Colors.white54,
                                            size: 20,
                                          ),
                                          tooltip: l10n.assetsProductTrackingHint,
                                          onPressed: () {
                                            setState(() => _assetProdutoFiltro = p.id);
                                            _tabs.animateTo(1);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.white54,
                                            size: 20,
                                          ),
                                          onPressed: () => _editProduto(p, l10n),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAssetsTab(BuildContext context, AppLocalizations l10n) {
    final cid = _clienteId;
    final rows = _assetsFiltradosSorted();
    final map = _produtoNomeMap();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _assetSearchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.assetsFilterSearchAssets,
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int?>(
                  value: _assetProdutoFiltro,
                  decoration: InputDecoration(
                    labelText: l10n.assetsFilterByProductLabel,
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                    isDense: true,
                  ),
                  dropdownColor: const Color(0xFF0B1220),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.assetsAllProducts),
                    ),
                    ..._produtos.map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nome, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _assetProdutoFiltro = v),
                ),
              ),
              TextButton(
                onPressed: _clearAssetFilters,
                child: Text(l10n.assetsClearFilters),
              ),
              TextButton.icon(
                onPressed: cid == null || _busy
                    ? null
                    : () => _reloadAll(cid),
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
                label: Text(
                  l10n.expenseRefresh,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                onPressed: () => _openNovoAsset(l10n),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Text(
            _allAssets.isEmpty
                ? l10n.assetsListAssets
                : '${l10n.assetsListAssets} (${rows.length}/${_allAssets.length})',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    _allAssets.isEmpty
                        ? l10n.assetsAssetsEmpty
                        : l10n.assetsEmptyAssetsFiltered,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF0F172A),
                    ),
                    dataTextStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    columns: [
                      DataColumn(
                        label: _assetSortableHeader(
                          l10n.assetsColProduct,
                          AssetsAssetSortKey.produto,
                        ),
                      ),
                      DataColumn(
                        label: _assetSortableHeader(
                          l10n.assetsSerial,
                          AssetsAssetSortKey.serialNumber,
                        ),
                      ),
                      DataColumn(
                        label: _assetSortableHeader(
                          l10n.assetsPartNumber,
                          AssetsAssetSortKey.partNumber,
                        ),
                      ),
                      DataColumn(
                        label: _assetSortableHeader(
                          l10n.assetsDisplayName,
                          AssetsAssetSortKey.nomeExibicao,
                        ),
                      ),
                      DataColumn(
                        label: _assetSortableHeader(
                          l10n.assetsColUpdated,
                          AssetsAssetSortKey.atualizadoEm,
                        ),
                      ),
                      const DataColumn(label: Text('')),
                    ],
                    rows: rows.map((a) {
                      return DataRow(
                        onSelectChanged: (_) => _editAsset(a, l10n),
                        cells: [
                          DataCell(Text(map[a.produto] ?? '#${a.produto}')),
                          DataCell(Text(a.serialNumber.isEmpty ? '—' : a.serialNumber)),
                          DataCell(Text(a.partNumber.isEmpty ? '—' : a.partNumber)),
                          DataCell(Text(a.nomeExibicao.isEmpty ? '—' : a.nomeExibicao)),
                          DataCell(
                            Text(
                              _formatDt(context, a.atualizadoEm),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed: () => _editAsset(a, l10n),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMovsTab(BuildContext context, AppLocalizations l10n) {
    final cid = _clienteId;
    final rows = _movsFiltradasSorted();
    final map = _produtoNomeMap();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _movSearchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.assetsFilterSearchMovements,
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  value: _movAssetFiltro,
                  decoration: InputDecoration(
                    labelText: l10n.assetsFilterByAsset,
                    isDense: true,
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  dropdownColor: const Color(0xFF0B1220),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.assetsAllAssets),
                    ),
                    ..._allAssets.map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          _assetLabel(a),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) async {
                    setState(() => _movAssetFiltro = v);
                    if (cid != null) await _reloadMovs(cid);
                  },
                ),
              ),
              TextButton(
                onPressed: _clearMovFilters,
                child: Text(l10n.assetsClearFilters),
              ),
              TextButton.icon(
                onPressed: cid == null || _busy
                    ? null
                    : () => _reloadAll(cid),
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
                label: Text(
                  l10n.expenseRefresh,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                onPressed: () => _openNovaMov(l10n),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Text(
            _movs.isEmpty
                ? l10n.assetsMovementList
                : '${l10n.assetsMovementList} (${rows.length}/${_movs.length})',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    _movs.isEmpty
                        ? l10n.assetsNoMovements
                        : l10n.assetsEmptyMovementsFiltered,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFF0F172A),
                      ),
                      dataTextStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      columnSpacing: 14,
                      columns: [
                        DataColumn(
                          label: _movSortableHeader(
                            l10n.assetsColWhen,
                            AssetsMovSortKey.criadoEm,
                          ),
                        ),
                        DataColumn(
                          label: _movSortableHeader(
                            l10n.assetsFieldSelectAsset,
                            AssetsMovSortKey.assetLabel,
                          ),
                        ),
                        DataColumn(
                          label: _movSortableHeader(
                            l10n.assetsMotivo,
                            AssetsMovSortKey.motivoNome,
                          ),
                        ),
                        DataColumn(
                          label: _movSortableHeader(
                            l10n.assetsDestino,
                            AssetsMovSortKey.destinoNome,
                          ),
                        ),
                        DataColumn(
                          label: _movSortableHeader(
                            l10n.assetsResponsible,
                            AssetsMovSortKey.responsavel,
                          ),
                        ),
                        DataColumn(
                          label: _movSortableHeader(
                            l10n.assetsColRegisteredBy,
                            AssetsMovSortKey.registradoPorNome,
                          ),
                        ),
                        DataColumn(
                          label: _movSortableHeader(
                            l10n.assetsObservation,
                            AssetsMovSortKey.observacao,
                          ),
                        ),
                      ],
                      rows: rows.map((m) {
                        final assetTxt =
                            movimentacaoAssetLabel(m, _allAssets, map);
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                _formatDt(context, m.criadoEm),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Text(
                                  assetTxt,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(m.motivoNome.isEmpty ? '—' : m.motivoNome)),
                            DataCell(
                              Text(
                                (m.destinoNome ?? '').trim().isEmpty
                                    ? '—'
                                    : m.destinoNome!,
                              ),
                            ),
                            DataCell(
                              Text(
                                m.responsavel.trim().isEmpty ? '—' : m.responsavel,
                              ),
                            ),
                            DataCell(
                              Text(
                                (m.registradoPorNome ?? '').trim().isEmpty
                                    ? '—'
                                    : m.registradoPorNome!,
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  m.observacao.trim().isEmpty ? '—' : m.observacao,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
