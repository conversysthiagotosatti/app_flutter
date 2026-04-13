import 'proposta_anexo.dart';
import 'proposta_item.dart';
import 'proposta_produto.dart';

class PropostaDetalhe {
  final int id;
  final int cliente;
  final String? clienteNome;
  final String? codigoInterno;
  final String titulo;
  final String descricao;
  final String? descricaoTecnica;
  final String? descricaoComercial;
  final String? descricaoMemoriaCalculo;
  final String valorTotal;
  final String status;
  final String? dataValidade;
  final String? criadoEm;

  final String? tipoProposta; // tecnica | comercial | contrato | memoria_calculo
  final List<int> parceiros;
  final List<PropostaItem>? itens;
  final List<PropostaProduto>? produtos;
  final List<PropostaAnexo>? anexos;

  const PropostaDetalhe({
    required this.id,
    required this.cliente,
    this.clienteNome,
    this.codigoInterno,
    required this.titulo,
    required this.descricao,
    this.descricaoTecnica,
    this.descricaoComercial,
    this.descricaoMemoriaCalculo,
    required this.valorTotal,
    required this.status,
    this.dataValidade,
    this.criadoEm,
    this.tipoProposta,
    required this.parceiros,
    this.itens,
    this.produtos,
    this.anexos,
  });

  factory PropostaDetalhe.fromJson(Map<String, dynamic> json) {
    return PropostaDetalhe(
      id: (json['id'] as num).toInt(),
      cliente: (json['cliente'] as num).toInt(),
      clienteNome: json['cliente_nome']?.toString(),
      codigoInterno: json['codigo_interno']?.toString(),
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      descricaoTecnica: json['descricao_tecnica']?.toString(),
      descricaoComercial: json['descricao_comercial']?.toString(),
      descricaoMemoriaCalculo: json['descricao_memoria_calculo']?.toString(),
      valorTotal: json['valor_total']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      dataValidade: json['data_validade']?.toString(),
      criadoEm: json['criado_em']?.toString(),
      tipoProposta: json['tipo_proposta']?.toString(),
      parceiros: (json['parceiros'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      itens: (json['itens'] as List?)
          ?.map((e) => PropostaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      produtos: (json['produtos'] as List?)
          ?.map((e) => PropostaProduto.fromJson(e as Map<String, dynamic>))
          .toList(),
      anexos: (json['anexos'] as List?)
          ?.map((e) => PropostaAnexo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

