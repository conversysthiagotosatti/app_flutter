import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/assets_conversys.dart';
import '../services/api_client.dart';
import '../services/assets_conversys_service.dart';
import '../widgets/conversys_app_bar.dart';
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

  List<AssetConversys> _assets = [];
  String _assetSearch = '';
  int? _assetProdutoFiltro;

  List<MovimentacaoAssetConversys> _movs = [];
  String _movSearch = '';
  int? _movAssetFiltro;

  List<MotivoMovimentacaoMini> _motivos = [];
  List<LocalEstoqueRow> _locais = [];

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _svc = AssetsConversysService(widget.apiClient);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
        _svc.fetchMovimentacoes(cid),
        _svc.fetchMotivosMovimentacao(),
        _svc.fetchLocaisEstoque(cid),
      ]);
      if (!mounted) return;
      setState(() {
        _produtos = results[0] as List<ProdutoConversys>;
        _assets = results[1] as List<AssetConversys>;
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

  Future<void> _reloadAssets(int cid) async {
    final list = await _svc.fetchAssets(
      cid,
      produtoId: _assetProdutoFiltro,
    );
    if (mounted) setState(() => _assets = list);
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

  List<ProdutoConversys> get _produtosFiltrados {
    return _produtos.where((p) {
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
    }).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  List<AssetConversys> get _assetsFiltrados {
    final q = _assetSearch.trim().toLowerCase();
    return _assets.where((a) {
      if (q.isEmpty) return true;
      final blob = [
        '${a.produto}',
        _nomeProd(a.produto),
        a.serialNumber,
        a.partNumber,
        a.nomeExibicao,
        a.observacoes,
      ].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList()
      ..sort(
        (a, b) => b.atualizadoEm.compareTo(a.atualizadoEm),
      );
  }

  List<MovimentacaoAssetConversys> get _movsFiltradas {
    final q = _movSearch.trim().toLowerCase();
    return _movs.where((m) {
      if (q.isEmpty) return true;
      AssetConversys? a;
      for (final x in _assets) {
        if (x.id == m.asset) {
          a = x;
          break;
        }
      }
      final label = a != null ? _assetLabel(a) : '#${m.asset}';
      final blob = [
        label,
        m.motivoNome,
        m.destinoNome ?? '',
        m.responsavel,
        m.observacao,
        m.registradoPorNome ?? '',
      ].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
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
                      decoration: _dec(l10n.assetsFilterByProduct),
                      dropdownColor: const Color(0xFF0B1220),
                      style: const TextStyle(color: Colors.white),
                      items: _produtos
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.nome,
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
                      child: Text(l10n.continueLabel),
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
    if (cid == null || _assets.isEmpty || _motivos.isEmpty || _locais.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.assetsMovPrereq)),
      );
      return;
    }
    int? aid = _assets.first.id;
    int? mid = _motivos.first.id;
    int? lid = _locais.first.id;
    final resp = TextEditingController();
    final obs = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
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
                  DropdownButtonFormField<int>(
                    initialValue: aid,
                    decoration: _dec(l10n.assetsColAsset),
                    dropdownColor: const Color(0xFF0B1220),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    isExpanded: true,
                    items: _assets
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              _assetLabel(a),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setSt(() => aid = v),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: mid,
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
                  DropdownButtonFormField<int>(
                    initialValue: lid,
                    decoration: _dec(l10n.assetsDestino),
                    dropdownColor: const Color(0xFF0B1220),
                    style: const TextStyle(color: Colors.white),
                    items: _locais
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text('${l.codigo} — ${l.nome}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setSt(() => lid = v),
                  ),
                  _tf(resp, l10n.assetsResponsible),
                  _tf(obs, l10n.assetsObservation, maxLines: 2),
                  FilledButton(
                    onPressed: aid == null || mid == null || lid == null
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
      await _svc.patchProduto(cid, p.id, fields: {
        'nome': nome.text.trim(),
        'tipo': tipo,
        'codigo_interno': codigo.text.trim(),
        'marca': marca.text.trim(),
        'modelo': modelo.text.trim(),
        'descricao': desc.text.trim(),
        'ficha_tecnica': ficha.text.trim(),
        'ativo': ativo ? 'true' : 'false',
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(
        context,
        l10n.assetsModuleTitle,
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
                                setState(() => _clienteId = id);
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
                          _buildProdutosTab(l10n),
                          _buildAssetsTab(l10n),
                          _buildMovsTab(l10n),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProdutosTab(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.assetsFilterSearch,
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _prodSearch = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _prodTipo.isEmpty ? '' : _prodTipo,
                hint: Text(l10n.assetsFilterTipoAll, style: const TextStyle(color: Colors.white54)),
                dropdownColor: const Color(0xFF0B1220),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  DropdownMenuItem(value: '', child: Text(l10n.assetsFilterTipoAll)),
                  DropdownMenuItem(value: 'HARDWARE', child: Text(l10n.assetsTypeHardware)),
                  DropdownMenuItem(value: 'SERVICO', child: Text(l10n.assetsTypeService)),
                ],
                onChanged: (v) => setState(() => _prodTipo = v ?? ''),
              ),
            ],
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 8),
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
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.teal),
              onPressed: () => _openNovoProduto(l10n),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _produtosFiltrados.length,
            itemBuilder: (context, i) {
              final p = _produtosFiltrados[i];
              final href = _mediaUrl(p.manualInstrucoes);
              return ListTile(
                title: Text(
                  p.nome,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${p.tipo} · ${p.codigoInterno} · ${p.ativo ? l10n.assetsYesShort : l10n.assetsNoShort}',
                  style: TextStyle(color: Colors.blueGrey[200], fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (href.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.teal),
                        onPressed: () async {
                          final u = Uri.tryParse(href);
                          if (u != null) {
                            await launchUrl(u, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.inventory_2_outlined, color: Colors.white54),
                      tooltip: l10n.assetsProductTrackingHint,
                      onPressed: () {
                        setState(() => _assetProdutoFiltro = p.id);
                        _tabs.animateTo(1);
                        final cid = _clienteId;
                        if (cid != null) _reloadAssets(cid);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white54),
                      onPressed: () => _editProduto(p, l10n),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsTab(AppLocalizations l10n) {
    final cid = _clienteId;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.assetsFilterSearchAssets,
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _assetSearch = v),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<int?>(
                  initialValue: _assetProdutoFiltro,
                  decoration: InputDecoration(
                    labelText: l10n.assetsAllProducts,
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                    isDense: true,
                  ),
                  dropdownColor: const Color(0xFF0B1220),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('—', style: TextStyle(color: Colors.white70)),
                    ),
                    ..._produtos.map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nome, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) async {
                    setState(() => _assetProdutoFiltro = v);
                    if (cid != null) await _reloadAssets(cid);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                onPressed: () => _openNovoAsset(l10n),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _assetsFiltrados.length,
            itemBuilder: (context, i) {
              final a = _assetsFiltrados[i];
              return ListTile(
                title: Text(
                  _assetLabel(a),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                subtitle: Text(
                  a.atualizadoEm,
                  style: TextStyle(color: Colors.blueGrey[300], fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white54),
                  onPressed: () => _editAsset(a, l10n),
                ),
                onTap: () => _editAsset(a, l10n),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovsTab(AppLocalizations l10n) {
    final cid = _clienteId;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.assetsFilterSearch,
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _movSearch = v),
                ),
              ),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<int?>(
                  initialValue: _movAssetFiltro,
                  decoration: InputDecoration(
                    labelText: l10n.assetsColAsset,
                    isDense: true,
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  dropdownColor: const Color(0xFF0B1220),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('—', style: TextStyle(color: Colors.white70)),
                    ),
                    ..._assets.map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '#${a.id}',
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
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                onPressed: () => _openNovaMov(l10n),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _movsFiltradas.length,
            itemBuilder: (context, i) {
              final m = _movsFiltradas[i];
              return ListTile(
                title: Text(
                  m.motivoNome,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${m.criadoEm}\n${m.destinoNome ?? '—'} · ${m.responsavel}',
                  style: TextStyle(color: Colors.blueGrey[200], fontSize: 11),
                ),
                isThreeLine: true,
              );
            },
          ),
        ),
      ],
    );
  }
}
