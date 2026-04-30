import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Estilo visual (hub escuro vs AppBar claro).
enum UserAccountMenuStyle {
  hubDark,
  appBarLight,
}

/// Avatar do usuário: ao toque abre o painel com as mesmas ações do portal
/// (`Header.tsx`: dados + Configurações + Sair).
class UserAccountMenuButton extends StatelessWidget {
  final ApiClient apiClient;
  final UserAccountMenuStyle style;

  const UserAccountMenuButton({
    super.key,
    required this.apiClient,
    this.style = UserAccountMenuStyle.appBarLight,
  });

  static String? _absoluteMediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final t = path.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base = ApiClient.baseUrl.replaceAll(RegExp(r'/$'), '');
    if (t.startsWith('/')) return '$base$t';
    return '$base/$t';
  }

  static String _displayName(Map<String, dynamic> me) {
    final fn = me['first_name']?.toString().trim() ?? '';
    final ln = me['last_name']?.toString().trim() ?? '';
    final u = me['username']?.toString() ?? '';
    final c = '$fn $ln'.trim();
    if (c.isNotEmpty) return c;
    return u.isNotEmpty ? u : '—';
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    final a = parts.first[0];
    final last = parts.last;
    if (last.isEmpty) return a.toUpperCase();
    return (a + last[0]).toUpperCase();
  }

  static String? _roleForCliente(
    List<dynamic>? memberships,
    int? clienteId,
  ) {
    if (memberships == null || clienteId == null) return null;
    for (final m in memberships) {
      if (m is! Map<String, dynamic>) continue;
      final id = m['cliente_id'];
      int? cid;
      if (id is int) {
        cid = id;
      } else if (id is num) {
        cid = id.toInt();
      }
      if (cid == clienteId) {
        final r = m['role'];
        return r is String ? r : null;
      }
    }
    return null;
  }

  static String? _roleLabel(AppLocalizations l10n, String? code) {
    switch (code) {
      case 'LIDER':
        return l10n.userRoleLider;
      case 'GERENTE_PROJETO':
        return l10n.userRoleGerenteProjeto;
      case 'ANALISTA':
        return l10n.userRoleAnalista;
      default:
        return code;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.headerLogout),
        content: Text(l10n.headerLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.headerLogout),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await AuthService(apiClient).logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(apiClient: apiClient),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = style == UserAccountMenuStyle.hubDark;
    final clienteId = await apiClient.loadAuthClienteId();

    Map<String, dynamic>? me;
    String? err;
    try {
      final r = await apiClient.get('/api/auth/me/');
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        if (d is Map<String, dynamic>) me = d;
      } else {
        err = 'HTTP ${r.statusCode}';
      }
    } catch (e) {
      err = '$e';
    }

    if (!context.mounted) return;

    final name = me != null ? _displayName(me) : l10n.profile;
    final email = me?['email']?.toString() ?? '';
    final roleCode =
        me != null ? _roleForCliente(me['memberships'] as List<dynamic>?, clienteId) : null;
    final roleLabel = _roleLabel(l10n, roleCode);
    final avatarUrl = _absoluteMediaUrl(
      me?['avatar']?.toString() ?? me?['foto']?.toString(),
    );
    final token = await apiClient.getAccessToken();

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final panelBg = isDark ? const Color(0xFF0F172A) : Colors.white;
        final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
        final textMuted = isDark ? Colors.white60 : const Color(0xFF64748B);
        final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Material(
            color: panelBg,
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF005AFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: avatarUrl != null && token != null
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                headers: {
                                  'Authorization': 'Bearer $token',
                                },
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    _initials(name),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  _initials(name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: textMain,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                            if (roleLabel != null && roleLabel.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF005AFF).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF005AFF).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  roleLabel.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: Color(0xFF005AFF),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      err,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                Divider(height: 1, color: border),
                ListTile(
                  leading: Icon(Icons.settings_outlined, color: textMain),
                  title: Text(
                    l10n.headerSettings,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openSettings(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFEC4899)),
                  title: Text(
                    l10n.headerLogout,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEC4899),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _logout(context);
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = style == UserAccountMenuStyle.hubDark;
    final ring = isDark ? Colors.white24 : Colors.black12;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _openMenu(context),
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF005AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isDark ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(color: ring, width: 1),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF005AFF).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            width: isDark ? 36 : 40,
            height: isDark ? 36 : 40,
            child: Icon(
              Icons.person,
              size: isDark ? 20 : 22,
              color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
