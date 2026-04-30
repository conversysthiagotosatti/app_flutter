import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/settings_service.dart';

/// Configurações alinhadas ao portal (`SettingsModal.tsx`): perfil, clientes,
/// equipe (criar usuário), segurança (trocar senha) e design (quando permitido).
class SettingsScreen extends StatefulWidget {
  final ApiClient apiClient;

  const SettingsScreen({super.key, required this.apiClient});

  /// URL absoluta para avatar/logos relativos à API (mesma regra do portal).
  static String? absoluteMediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final t = path.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base = ApiClient.baseUrl.replaceAll(RegExp(r'/$'), '');
    if (t.startsWith('/')) return '$base$t';
    return '$base/$t';
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _svc;
  Map<String, dynamic>? _me;
  int? _activeClienteId;
  bool _loading = true;
  String? _bootstrapErr;

  List<Map<String, dynamic>> _sapDept = [];
  List<Map<String, dynamic>> _usersPick = [];

  bool get _isStaff => _me?['is_staff'] == true;

  bool _canEditDesign() {
    final cid = _activeClienteId;
    final m = _me?['memberships'];
    if (cid == null || m is! List) return false;
    for (final x in m) {
      if (x is! Map<String, dynamic>) continue;
      final id = x['cliente_id'];
      int? i;
      if (id is int) i = id;
      else if (id is num) i = id.toInt();
      if (i == cid && x['pode_alterar_design'] == true) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _svc = SettingsService(widget.apiClient);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _bootstrapErr = null;
    });
    try {
      final cid = await widget.apiClient.loadAuthClienteId();
      final me = await _svc.fetchMe(clienteId: cid);
      List<Map<String, dynamic>> sap = const [];
      List<Map<String, dynamic>> users = const [];
      if (me['is_staff'] == true) {
        try {
          sap = await _svc.fetchDepartamentosSap();
        } catch (_) {}
      }
      try {
        users = await _svc.fetchUsers();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _me = me;
        _activeClienteId = cid;
        _sapDept = sap;
        _usersPick = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bootstrapErr = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.headerSettings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_bootstrapErr != null || _me == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.headerSettings)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_bootstrapErr ?? l10n.settingsLoadError),
          ),
        ),
      );
    }

    final showDesign = _canEditDesign();
    final n = showDesign ? 5 : 4;

    return DefaultTabController(
      key: ValueKey(n),
      length: n,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.headerSettings),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.settingsTabProfile),
              Tab(text: l10n.settingsTabClients),
              Tab(text: l10n.settingsTabTeam),
              Tab(text: l10n.settingsTabSecurity),
              if (showDesign) Tab(text: l10n.settingsTabDesign),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SettingsProfileTab(
              apiClient: widget.apiClient,
              svc: _svc,
              me: _me!,
              sapDept: _sapDept,
              onSaved: (m) => setState(() => _me = m),
            ),
            _SettingsClientsTab(
              svc: _svc,
              usersPick: _usersPick,
              onChanged: _bootstrap,
            ),
            _SettingsTeamTab(
              svc: _svc,
              isStaff: _isStaff,
              sapDept: _sapDept,
              usersPick: _usersPick,
            ),
            _SettingsSecurityTab(svc: _svc),
            if (showDesign)
              _SettingsDesignTab(
                svc: _svc,
                clienteId: _activeClienteId!,
                onSaved: _bootstrap,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsProfileTab extends StatefulWidget {
  final ApiClient apiClient;
  final SettingsService svc;
  final Map<String, dynamic> me;
  final List<Map<String, dynamic>> sapDept;
  final void Function(Map<String, dynamic>) onSaved;

  const _SettingsProfileTab({
    required this.apiClient,
    required this.svc,
    required this.me,
    required this.sapDept,
    required this.onSaved,
  });

  @override
  State<_SettingsProfileTab> createState() => _SettingsProfileTabState();
}

class _SettingsProfileTabState extends State<_SettingsProfileTab> {
  late final TextEditingController _fn;
  late final TextEditingController _ln;
  late final TextEditingController _em;
  late final TextEditingController _sapUser;
  late final TextEditingController _sapDeptCode;
  int? _sapDeptId;
  String? _avatarPickPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.me;
    _fn = TextEditingController(text: m['first_name']?.toString() ?? '');
    _ln = TextEditingController(text: m['last_name']?.toString() ?? '');
    _em = TextEditingController(text: m['email']?.toString() ?? '');
    _sapUser = TextEditingController(text: (m['codigo_usuario_sap'] ?? '').toString().trim());
    _sapDeptCode = TextEditingController(text: (m['codigo_departamento_sap'] ?? '').toString().trim());
    final did = m['departamento_sap_id'];
    if (did is int) {
      _sapDeptId = did;
    } else if (did is num) {
      _sapDeptId = did.toInt();
    }
  }

  @override
  void dispose() {
    _fn.dispose();
    _ln.dispose();
    _em.dispose();
    _sapUser.dispose();
    _sapDeptCode.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() => _saving = true);
    try {
      final fields = <String, String>{
        'first_name': _fn.text.trim(),
        'last_name': _ln.text.trim(),
        'email': _em.text.trim(),
        'codigo_usuario_sap': _sapUser.text.trim(),
      };
      if (widget.me['is_staff'] == true) {
        fields['departamento_sap_id'] =
            _sapDeptId == null ? '' : '$_sapDeptId';
      } else {
        fields['codigo_departamento_sap'] = _sapDeptCode.text.trim();
      }
      final files = <http.MultipartFile>[];
      if (_avatarPickPath != null) {
        files.add(await http.MultipartFile.fromPath('avatar', _avatarPickPath!));
      }
      final updated = await widget.svc.patchMe(fields: fields, files: files);
      widget.onSaved(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsProfileSaved)),
        );
      }
      setState(() => _avatarPickPath = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.settingsProfileError}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = widget.me;
    final username = m['username']?.toString() ?? '';
    final tipo = m['tipo_usuario']?.toString();
    final staff = m['is_staff'] == true;
    final remoteUrl = SettingsScreen.absoluteMediaUrl(
        m['avatar']?.toString() ?? m['foto']?.toString());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (tipo != null && tipo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Chip(
              label: Text('${l10n.settingsTipoUsuario}: $tipo'),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: _avatarPickPath != null
                      ? FileImage(File(_avatarPickPath!))
                      : null,
                  child: _avatarPickPath != null
                      ? null
                      : remoteUrl != null
                          ? ClipOval(
                              child: FutureBuilder<String?>(
                                future: widget.apiClient.getAccessToken(),
                                builder: (context, snap) {
                                  return Image.network(
                                    remoteUrl,
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                    headers: snap.data != null
                                        ? {
                                            'Authorization':
                                                'Bearer ${snap.data}',
                                          }
                                        : null,
                                    errorBuilder: (context, error, st) {
                                      return Center(
                                        child: Text(
                                          '${(_fn.text.isNotEmpty ? _fn.text[0] : '?').toUpperCase()}'
                                          '${(_ln.text.isNotEmpty ? _ln.text[0] : '')}',
                                          style: const TextStyle(
                                              fontSize: 28),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            )
                          : Text(
                              '${(_fn.text.isNotEmpty ? _fn.text[0] : '?').toUpperCase()}'
                              '${(_ln.text.isNotEmpty ? _ln.text[0] : '')}',
                              style: const TextStyle(fontSize: 28),
                            ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.camera_alt, size: 20),
                  onPressed: () async {
                    final r = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: false,
                    );
                    final p = r?.files.single.path;
                    if (p != null) setState(() => _avatarPickPath = p);
                  },
                  tooltip: l10n.settingsPickAvatar,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settingsLoginReadonly,
                      style: Theme.of(context).textTheme.labelSmall),
                  Text(username, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _fn,
          decoration: InputDecoration(labelText: l10n.settingsFirstName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ln,
          decoration: InputDecoration(labelText: l10n.settingsLastName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _em,
          decoration: InputDecoration(labelText: l10n.settingsContactEmail),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        Text(l10n.settingsSapUserCode,
            style: Theme.of(context).textTheme.titleSmall),
        TextField(controller: _sapUser),
        const SizedBox(height: 12),
        if (staff) ...[
          Text(l10n.settingsSapDeptSelect,
              style: Theme.of(context).textTheme.titleSmall),
          DropdownButtonFormField<int?>(
            value: _sapDeptId,
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text(l10n.settingsSapNone),
              ),
              ...widget.sapDept.map((d) {
                final id = d['id'];
                int? i;
                if (id is int) {
                  i = id;
                } else if (id is num) {
                  i = id.toInt();
                }
                if (i == null) return null;
                final code = d['code']?.toString() ?? '';
                final name = d['name']?.toString() ?? '';
                return DropdownMenuItem<int?>(
                  value: i,
                  child: Text('$code — $name'),
                );
              }).whereType<DropdownMenuItem<int?>>(),
            ],
            onChanged: (v) => setState(() => _sapDeptId = v),
          ),
        ] else ...[
          Text(l10n.settingsSapDeptCode,
              style: Theme.of(context).textTheme.titleSmall),
          TextField(controller: _sapDeptCode),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : () => _save(l10n),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(l10n.settingsSaveProfile),
        ),
      ],
    );
  }
}

class _SettingsSecurityTab extends StatefulWidget {
  final SettingsService svc;

  const _SettingsSecurityTab({required this.svc});

  @override
  State<_SettingsSecurityTab> createState() => _SettingsSecurityTabState();
}

class _SettingsSecurityTabState extends State<_SettingsSecurityTab> {
  final _cur = TextEditingController();
  final _nw = TextEditingController();
  final _cf = TextEditingController();
  bool _show = false;
  bool _loading = false;

  @override
  void dispose() {
    _cur.dispose();
    _nw.dispose();
    _cf.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (_cur.text.isEmpty || _nw.text.isEmpty || _cf.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsPasswordFillAll)),
      );
      return;
    }
    if (_nw.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsPasswordTooShort)),
      );
      return;
    }
    if (_nw.text != _cf.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsPasswordMismatch)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.svc.changePassword(
        oldPassword: _cur.text,
        newPassword: _nw.text,
      );
      _cur.clear();
      _nw.clear();
      _cf.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsPasswordChanged)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.settingsPasswordIntro),
        const SizedBox(height: 16),
        TextField(
          controller: _cur,
          obscureText: !_show,
          decoration: InputDecoration(labelText: l10n.settingsCurrentPassword),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nw,
          obscureText: !_show,
          decoration: InputDecoration(labelText: l10n.settingsNewPassword),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cf,
          obscureText: !_show,
          decoration: InputDecoration(labelText: l10n.settingsConfirmNewPassword),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _show = !_show),
          icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
          label: Text(_show ? l10n.settingsHidePassword : l10n.settingsShowPassword),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : () => _submit(l10n),
          child: Text(_loading ? l10n.settingsPasswordChanging : l10n.settingsChangePasswordButton),
        ),
      ],
    );
  }
}

class _SettingsClientsTab extends StatefulWidget {
  final SettingsService svc;
  final List<Map<String, dynamic>> usersPick;
  final Future<void> Function() onChanged;

  const _SettingsClientsTab({
    required this.svc,
    required this.usersPick,
    required this.onChanged,
  });

  @override
  State<_SettingsClientsTab> createState() => _SettingsClientsTabState();
}

class _SettingsClientsTabState extends State<_SettingsClientsTab> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  Map<String, dynamic>? _edit;
  final _nome = TextEditingController();
  final _doc = TextEditingController();
  final _email = TextEditingController();
  final _fone = TextEditingController();
  final _menuUrl = TextEditingController();
  final _frameUrl = TextEditingController();
  int? _finApprId;
  final List<_SubRow> _subs = [];
  Set<int> _initialSubIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _disposeSubs() {
    for (final r in _subs) {
      r.nome.dispose();
      r.cnpj.dispose();
    }
    _subs.clear();
  }

  @override
  void dispose() {
    _nome.dispose();
    _doc.dispose();
    _email.dispose();
    _fone.dispose();
    _menuUrl.dispose();
    _frameUrl.dispose();
    _disposeSubs();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      _list = await widget.svc.fetchClientes();
    } catch (_) {
      _list = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openNew() {
    setState(() {
      _edit = {'isNew': true};
      _nome.clear();
      _doc.clear();
      _email.clear();
      _fone.clear();
      _menuUrl.clear();
      _frameUrl.clear();
      _finApprId = null;
      _disposeSubs();
      _initialSubIds = {};
    });
  }

  void _openEdit(Map<String, dynamic> cli) {
    setState(() {
      _edit = Map<String, dynamic>.from(cli);
      _nome.text = cli['nome']?.toString() ?? '';
      _doc.text = cli['documento']?.toString() ?? '';
      _email.text = cli['email']?.toString() ?? '';
      _fone.text = cli['telefone']?.toString() ?? '';
      _menuUrl.text = cli['logotipo_menu_url']?.toString() ?? '';
      _frameUrl.text = cli['logotipo_frame_url']?.toString() ?? '';
      final efa = cli['expense_finance_approver_id'];
      if (efa is int) {
        _finApprId = efa;
      } else if (efa is num) {
        _finApprId = efa.toInt();
      } else {
        _finApprId = null;
      }
      _disposeSubs();
      _initialSubIds = {};
      final subs = cli['subclientes'];
      if (subs is List) {
        for (final s in subs) {
          if (s is! Map<String, dynamic>) continue;
          final id = s['id'];
          int? sid;
          if (id is int) sid = id;
          else if (id is num) sid = id.toInt();
          if (sid != null) _initialSubIds.add(sid);
          _subs.add(_SubRow(
            id: sid,
            nome: TextEditingController(text: s['nome']?.toString() ?? ''),
            cnpj: TextEditingController(text: s['cnpj']?.toString() ?? ''),
          ));
        }
      }
    });
  }

  Future<void> _saveClient(AppLocalizations l10n) async {
    if (_nome.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final fields = <String, String>{
        'nome': _nome.text.trim(),
        'documento': _doc.text.trim(),
        'email': _email.text.trim(),
        'telefone': _fone.text.trim(),
        'logotipo_menu_url': _menuUrl.text.trim(),
        'logotipo_frame_url': _frameUrl.text.trim(),
      };
      if (_finApprId != null) {
        fields['expense_finance_approver_id'] = '$_finApprId';
      } else if (_edit != null && _edit!['isNew'] != true) {
        fields['expense_finance_approver_id'] = '';
      }

      final isNew = _edit?['isNew'] == true;
      int? cid;
      if (!isNew) {
        final id = _edit!['id'];
        if (id is int) cid = id;
        else if (id is num) cid = id.toInt();
      }

      if (isNew) {
        await widget.svc.createCliente(fields: fields, files: const []);
        await _reload();
        widget.onChanged();
        if (mounted) setState(() => _edit = null);
      } else if (cid != null) {
        await widget.svc.updateCliente(cid, fields: fields, files: const []);
        for (final oldId in _initialSubIds) {
          final still = _subs.any((r) => r.id == oldId);
          if (!still) {
            await widget.svc.deleteSubcliente(cid, oldId);
          }
        }
        for (final r in _subs) {
          final nm = r.nome.text.trim();
          final cj = r.cnpj.text.trim();
          if (nm.isEmpty) continue;
          if (r.id != null) {
            await widget.svc.updateSubcliente(cid, r.id!, nome: nm, cnpj: cj);
          } else {
            await widget.svc.createSubcliente(cid, nome: nm, cnpj: cj);
          }
        }
        await _reload();
        widget.onChanged();
        if (mounted) setState(() => _edit = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteClient(AppLocalizations l10n) async {
    final id = _edit?['id'];
    int? cid;
    if (id is int) cid = id;
    else if (id is num) cid = id.toInt();
    if (cid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDeleteClient),
        content: Text(l10n.settingsDeleteClientConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsDeleteClient),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.svc.deleteCliente(cid);
      await _reload();
      widget.onChanged();
      if (mounted) setState(() => _edit = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_edit != null) {
      final isNew = _edit!['isNew'] == true;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _edit = null),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  isNew ? l10n.settingsNewClient : l10n.settingsEditClient,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          TextField(
            controller: _nome,
            decoration: InputDecoration(labelText: '${l10n.settingsClientName} *'),
          ),
          TextField(
            controller: _doc,
            decoration: InputDecoration(labelText: l10n.settingsClientDocument),
          ),
          TextField(
            controller: _email,
            decoration: InputDecoration(labelText: l10n.settingsClientEmail),
          ),
          TextField(
            controller: _fone,
            decoration: InputDecoration(labelText: l10n.settingsClientPhone),
          ),
          TextField(
            controller: _menuUrl,
            decoration: InputDecoration(labelText: l10n.settingsMenuLogoUrl),
          ),
          TextField(
            controller: _frameUrl,
            decoration: InputDecoration(labelText: l10n.settingsFrameLogoUrl),
          ),
          if (!isNew) ...[
            const SizedBox(height: 12),
            Text(l10n.settingsFinanceApprover,
                style: Theme.of(context).textTheme.titleSmall),
            DropdownButtonFormField<int?>(
              value: _finApprId,
              items: [
                DropdownMenuItem<int?>(value: null, child: Text(l10n.settingsNoneOption)),
                ...widget.usersPick.map((u) {
                  final id = u['id'];
                  int? i;
                  if (id is int) i = id;
                  else if (id is num) i = id.toInt();
                  if (i == null) return null;
                  return DropdownMenuItem<int?>(
                    value: i,
                    child: Text(u['username']?.toString() ?? '$i'),
                  );
                }).whereType<DropdownMenuItem<int?>>(),
              ],
              onChanged: (v) => setState(() => _finApprId = v),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.settingsSubclientes,
              style: Theme.of(context).textTheme.titleSmall),
          ..._subs.asMap().entries.map((e) {
            final r = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: r.nome,
                      decoration: InputDecoration(labelText: l10n.settingsSubclienteName),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: r.cnpj,
                      decoration: InputDecoration(labelText: l10n.settingsSubclienteCnpj),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      r.nome.dispose();
                      r.cnpj.dispose();
                      _subs.removeAt(e.key);
                    }),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _subs.add(_SubRow())),
            icon: const Icon(Icons.add),
            label: Text(l10n.settingsAddSubcliente),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (!isNew)
                TextButton(
                  onPressed: () => _deleteClient(l10n),
                  child: Text(l10n.settingsDeleteClient),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : () => _saveClient(l10n),
                child: Text(_saving ? '…' : l10n.settingsSaveClient),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(l10n.settingsClientsTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.tonal(
                onPressed: _openNew,
                child: Text(l10n.settingsNewClient),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _list.length,
            itemBuilder: (ctx, i) {
              final c = _list[i];
              return ListTile(
                title: Text(c['nome']?.toString() ?? ''),
                subtitle: Text(c['documento']?.toString() ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openEdit(c),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubRow {
  final int? id;
  final TextEditingController nome;
  final TextEditingController cnpj;

  _SubRow({this.id, TextEditingController? nome, TextEditingController? cnpj})
      : nome = nome ?? TextEditingController(),
        cnpj = cnpj ?? TextEditingController();
}

class _SettingsTeamTab extends StatefulWidget {
  final SettingsService svc;
  final bool isStaff;
  final List<Map<String, dynamic>> sapDept;
  final List<Map<String, dynamic>> usersPick;

  const _SettingsTeamTab({
    required this.svc,
    required this.isStaff,
    required this.sapDept,
    required this.usersPick,
  });

  @override
  State<_SettingsTeamTab> createState() => _SettingsTeamTabState();
}

class _SettingsTeamTabState extends State<_SettingsTeamTab> {
  final _user = TextEditingController();
  final _email = TextEditingController();
  final _nome = TextEditingController();
  final _sobrenome = TextEditingController();
  final _pass = TextEditingController();
  final _idSd = TextEditingController();
  final _sapCod = TextEditingController();
  final _sapDeptFree = TextEditingController();
  int? _sapDeptId;
  int? _aprovId;
  int? _aprovFinId;
  final List<_MemRow> _mems = [_MemRow()];
  List<Map<String, dynamic>> _clientesOpt = [];
  bool _loadingC = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  @override
  void dispose() {
    _user.dispose();
    _email.dispose();
    _nome.dispose();
    _sobrenome.dispose();
    _pass.dispose();
    _idSd.dispose();
    _sapCod.dispose();
    _sapDeptFree.dispose();
    super.dispose();
  }

  Future<void> _loadClientes() async {
    try {
      _clientesOpt = await widget.svc.fetchClientes();
    } catch (_) {
      _clientesOpt = [];
    }
    if (mounted) setState(() => _loadingC = false);
  }

  Future<void> _create(AppLocalizations l10n) async {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsPasswordFillAll)),
      );
      return;
    }
    final memberships = <Map<String, dynamic>>[];
    for (final m in _mems) {
      if (m.clienteId != null) {
        memberships.add({'cliente': m.clienteId, 'role': m.role});
      }
    }
    if (memberships.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsTeamNeedMembership)),
      );
      return;
    }
    final body = <String, dynamic>{
      'username': _user.text.trim(),
      'email': _email.text.trim(),
      'nome': _nome.text.trim(),
      'sobrenome': _sobrenome.text.trim(),
      'password': _pass.text,
      'memberships': memberships,
    };
    final sd = _idSd.text.trim();
    if (sd.isNotEmpty && int.tryParse(sd) != null) {
      body['id_softdesk'] = int.parse(sd);
    }
    if (_sapCod.text.trim().isNotEmpty) {
      body['codigo_usuario_sap'] = _sapCod.text.trim();
    }
    if (widget.isStaff && _sapDeptId != null) {
      body['departamento_sap_id'] = _sapDeptId;
    } else if (!widget.isStaff && _sapDeptFree.text.trim().isNotEmpty) {
      body['codigo_departamento_sap'] = _sapDeptFree.text.trim();
    }
    if (_aprovId != null) body['usuario_aprovador_despesas_id'] = _aprovId;
    if (_aprovFinId != null) {
      body['usuario_aprovador_despesas_financeiro_id'] = _aprovFinId;
    }
    setState(() => _submitting = true);
    try {
      await widget.svc.createUser(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsTeamSuccess)),
        );
      }
      _user.clear();
      _email.clear();
      _nome.clear();
      _sobrenome.clear();
      _pass.clear();
      _idSd.clear();
      _sapCod.clear();
      _sapDeptFree.clear();
      setState(() {
        _sapDeptId = null;
        _aprovId = null;
        _aprovFinId = null;
        _mems.clear();
        _mems.add(_MemRow());
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loadingC) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.settingsTeamTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(
          controller: _user,
          decoration: InputDecoration(labelText: '${l10n.settingsUsername} *'),
        ),
        TextField(
          controller: _email,
          decoration: InputDecoration(labelText: l10n.settingsContactEmail),
        ),
        TextField(controller: _nome, decoration: InputDecoration(labelText: l10n.settingsFirstName)),
        TextField(controller: _sobrenome, decoration: InputDecoration(labelText: l10n.settingsLastName)),
        TextField(controller: _idSd, decoration: InputDecoration(labelText: l10n.settingsIdSoftdesk), keyboardType: TextInputType.number),
        TextField(controller: _sapCod, decoration: InputDecoration(labelText: l10n.settingsSapUserCode)),
        if (widget.isStaff)
          DropdownButtonFormField<int?>(
            value: _sapDeptId,
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(l10n.settingsSapNone)),
              ...widget.sapDept.map((d) {
                final id = d['id'];
                int? i;
                if (id is int) {
                  i = id;
                } else if (id is num) {
                  i = id.toInt();
                }
                if (i == null) return null;
                return DropdownMenuItem<int?>(
                  value: i,
                  child: Text('${d['code']} — ${d['name']}'),
                );
              }).whereType<DropdownMenuItem<int?>>(),
            ],
            onChanged: (v) => setState(() => _sapDeptId = v),
            decoration: InputDecoration(labelText: l10n.settingsSapDeptSelect),
          )
        else
          TextField(
            controller: _sapDeptFree,
            decoration: InputDecoration(labelText: l10n.settingsSapDeptCode),
          ),
        DropdownButtonFormField<int?>(
          value: _aprovId,
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(l10n.settingsNoneOption)),
            ...widget.usersPick.map((u) {
              final id = u['id'];
              int? i;
              if (id is int) i = id;
              else if (id is num) i = id.toInt();
              if (i == null) return null;
              return DropdownMenuItem<int?>(
                value: i,
                child: Text(u['username']?.toString() ?? '$i'),
              );
            }).whereType<DropdownMenuItem<int?>>(),
          ],
          onChanged: (v) => setState(() => _aprovId = v),
          decoration: InputDecoration(labelText: l10n.settingsExpenseApprover),
        ),
        DropdownButtonFormField<int?>(
          value: _aprovFinId,
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(l10n.settingsNoneOption)),
            ...widget.usersPick.map((u) {
              final id = u['id'];
              int? i;
              if (id is int) i = id;
              else if (id is num) i = id.toInt();
              if (i == null) return null;
              return DropdownMenuItem<int?>(
                value: i,
                child: Text(u['username']?.toString() ?? '$i'),
              );
            }).whereType<DropdownMenuItem<int?>>(),
          ],
          onChanged: (v) => setState(() => _aprovFinId = v),
          decoration: InputDecoration(labelText: l10n.settingsFinanceApprover),
        ),
        TextField(
          controller: _pass,
          obscureText: true,
          decoration: InputDecoration(labelText: '${l10n.settingsPassword} *'),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Text(l10n.settingsAddMembership, style: Theme.of(context).textTheme.titleSmall),
        ..._mems.asMap().entries.map((e) {
          final m = e.value;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  DropdownButtonFormField<int?>(
                    value: m.clienteId,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n.settingsSelectCliente),
                      ),
                      ..._clientesOpt.map((c) {
                        final id = c['id'];
                        int? i;
                        if (id is int) i = id;
                        else if (id is num) i = id.toInt();
                        if (i == null) return null;
                        return DropdownMenuItem<int?>(
                          value: i,
                          child: Text(c['nome']?.toString() ?? '$i'),
                        );
                      }).whereType<DropdownMenuItem<int?>>(),
                    ],
                    onChanged: (v) => setState(() => m.clienteId = v),
                  ),
                  DropdownButtonFormField<String>(
                    value: m.role,
                    decoration: InputDecoration(labelText: l10n.settingsSelectRole),
                    items: ['LIDER', 'GERENTE_PROJETO', 'ANALISTA']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => m.role = v ?? 'ANALISTA'),
                  ),
                  if (_mems.length > 1)
                    TextButton(
                      onPressed: () => setState(() => _mems.removeAt(e.key)),
                      child: Text(l10n.settingsRemoveMembership),
                    ),
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _mems.add(_MemRow())),
          icon: const Icon(Icons.add),
          label: Text(l10n.settingsAddMembership),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _submitting ? null : () => _create(l10n),
          child: Text(_submitting ? l10n.settingsTeamCreating : l10n.settingsTeamCreate),
        ),
      ],
    );
  }
}

class _MemRow {
  int? clienteId;
  String role = 'ANALISTA';
}

class _SettingsDesignTab extends StatefulWidget {
  final SettingsService svc;
  final int clienteId;
  final Future<void> Function() onSaved;

  const _SettingsDesignTab({
    required this.svc,
    required this.clienteId,
    required this.onSaved,
  });

  @override
  State<_SettingsDesignTab> createState() => _SettingsDesignTabState();
}

class _SettingsDesignTabState extends State<_SettingsDesignTab> {
  final _bg = TextEditingController();
  final _tx = TextEditingController();
  final _hd = TextEditingController();
  final _menuUrl = TextEditingController();
  final _frameUrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bg.dispose();
    _tx.dispose();
    _hd.dispose();
    _menuUrl.dispose();
    _frameUrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await widget.svc.fetchCliente(widget.clienteId);
      if (!mounted) return;
      setState(() {
        _bg.text = c['sidebar_menu_bg_color']?.toString() ?? '';
        _tx.text = c['sidebar_menu_text_color']?.toString() ?? '';
        _hd.text = c['helpdesk_novo_chamado_bg_color']?.toString() ?? '';
        _menuUrl.text = c['logotipo_menu_url']?.toString() ?? '';
        _frameUrl.text = c['logotipo_frame_url']?.toString() ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() => _saving = true);
    try {
      await widget.svc.updateCliente(
        widget.clienteId,
        fields: {
          'sidebar_menu_bg_color': _bg.text.trim(),
          'sidebar_menu_text_color': _tx.text.trim(),
          'helpdesk_novo_chamado_bg_color': _hd.text.trim(),
          'logotipo_menu_url': _menuUrl.text.trim(),
          'logotipo_frame_url': _frameUrl.text.trim(),
        },
        files: const [],
      );
      await widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsProfileSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.settingsDesignTitle, style: Theme.of(context).textTheme.titleLarge),
        TextField(
          controller: _bg,
          decoration: InputDecoration(labelText: l10n.settingsMenuBg),
        ),
        TextField(
          controller: _tx,
          decoration: InputDecoration(labelText: l10n.settingsMenuText),
        ),
        TextField(
          controller: _hd,
          decoration: InputDecoration(labelText: l10n.settingsHelpdeskNewBg),
        ),
        TextField(
          controller: _menuUrl,
          decoration: InputDecoration(labelText: l10n.settingsMenuLogoUrl),
        ),
        TextField(
          controller: _frameUrl,
          decoration: InputDecoration(labelText: l10n.settingsFrameLogoUrl),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : () => _save(l10n),
          child: Text(_saving ? '…' : l10n.settingsDesignSave),
        ),
      ],
    );
  }
}
