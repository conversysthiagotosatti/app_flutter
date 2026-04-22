import 'subcliente.dart';

class Cliente {
  final int id;
  final String nome;
  final String? documento;
  final String? email;
  final String? telefone;
  final bool ativo;
  final bool isProspecto;
  final String? logotipo;
  final String? codigoIntegracao;
  final int? idSoftdesk;
  final int? cidadeId;
  final String? endereco;
  final String? enderecoNumero;
  final String? enderecoCompl;
  final String? bairro;
  final String? cep;
  final String? sidebarMenuBgColor;
  final String? sidebarMenuTextColor;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final List<Subcliente> subclientes;

  Cliente({
    required this.id,
    required this.nome,
    this.documento,
    this.email,
    this.telefone,
    required this.ativo,
    required this.isProspecto,
    this.logotipo,
    this.codigoIntegracao,
    this.idSoftdesk,
    this.cidadeId,
    this.endereco,
    this.enderecoNumero,
    this.enderecoCompl,
    this.bairro,
    this.cep,
    this.sidebarMenuBgColor,
    this.sidebarMenuTextColor,
    this.criadoEm,
    this.atualizadoEm,
    this.subclientes = const [],
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    final ativo = json['ativo'] as bool? ?? true;
    final bool isProspecto;
    if (json.containsKey('is_prospecto')) {
      isProspecto = json['is_prospecto'] as bool? ?? true;
    } else {
      // Payloads antigos/minimos (ex.: contrato) sem o campo: compatível com default do Django.
      isProspecto = true;
    }

    final subs = json['subclientes'];
    final List<Subcliente> subclientes;
    if (subs is List) {
      subclientes = subs
          .map((e) => Subcliente.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      subclientes = const [];
    }

    return Cliente(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
      documento: json['documento'] as String?,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      ativo: ativo,
      isProspecto: isProspecto,
      logotipo: json['logotipo']?.toString(),
      codigoIntegracao: json['codigo_integracao'] as String?,
      idSoftdesk: json['id_softdesk'] as int?,
      cidadeId: json['cidade'] as int?,
      endereco: json['endereco'] as String?,
      enderecoNumero: json['endereco_numero'] as String?,
      enderecoCompl: json['endereco_compl'] as String?,
      bairro: json['bairro'] as String?,
      cep: json['cep'] as String?,
      sidebarMenuBgColor: json['sidebar_menu_bg_color'] as String?,
      sidebarMenuTextColor: json['sidebar_menu_text_color'] as String?,
      criadoEm: _parseDate(json['criado_em']),
      atualizadoEm: _parseDate(json['atualizado_em']),
      subclientes: subclientes,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }
}
