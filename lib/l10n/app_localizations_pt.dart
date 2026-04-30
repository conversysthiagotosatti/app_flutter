// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Conversys';

  @override
  String get language => 'Idioma';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get loginSubtitle =>
      'Acesse para gerenciar os módulos disponíveis para o seu cliente.';

  @override
  String get usernameOrEmail => 'Usuário ou e-mail';

  @override
  String get usernameRequired => 'Informe o usuário';

  @override
  String get password => 'Senha';

  @override
  String get passwordRequired => 'Informe a senha';

  @override
  String get signIn => 'Entrar';

  @override
  String get invalidCredentials =>
      'Credenciais inválidas ou acesso ao cliente não permitido.';

  @override
  String get blueHuddleTitle => 'The Blue Huddle';

  @override
  String get taglineConversys => 'Uma linha projetada pela Conversys';

  @override
  String get predefinedArchitectures =>
      'Arquiteturas pré-definidas de tecnologia';

  @override
  String get servicesIntro =>
      'Acesse seus serviços ativos abaixo ou explore novas soluções integradas da Conversys.';

  @override
  String get myServices => 'Meus serviços';

  @override
  String get noModulesForUser => 'Nenhum módulo disponível para este usuário.';

  @override
  String get moduleDefaultName => 'Módulo';

  @override
  String get statusActive => 'ATIVO';

  @override
  String get accessConsole => 'Acessar console';

  @override
  String get notifications => 'Notificações';

  @override
  String get profile => 'Perfil';

  @override
  String get signOut => 'Sair';

  @override
  String get navClients => 'Clientes';

  @override
  String get navContracts => 'Contratos';

  @override
  String get navTasks => 'Tarefas';

  @override
  String moduleUnavailable(String name) {
    return 'O módulo \"$name\" ainda não está disponível no app mobile.';
  }

  @override
  String get inDevelopment => 'Em desenvolvimento';

  @override
  String get tarefasDashboard => 'Dashboard';

  @override
  String get tarefasTracking => 'Rastreamento e movimentação';

  @override
  String get tarefasCalendar => 'Calendário';

  @override
  String get tarefasCopilot => 'Copilot IA';

  @override
  String get tarefasAnalyzeAi => 'Analisar com IA';

  @override
  String get tarefasRegisterEpic => 'Cadastrar Épico';

  @override
  String get tarefasNewTask => 'Nova tarefa';

  @override
  String get tarefasKanban => 'Kanban';

  @override
  String get tarefasReports => 'Relatórios';

  @override
  String get tarefasDocuments => 'Documentos';

  @override
  String get tarefasKanbanTitle => 'Kanban de tarefas';

  @override
  String get stockTrackingTitle => 'Rastreamento e movimentação';

  @override
  String get stockTrackingIntro =>
      'Consulte o produto pelo serial ou escolha no catálogo. Registre mudanças de local com motivo e destino.';

  @override
  String get serialLabel => 'Serial';

  @override
  String get serialNumber => 'Número de série';

  @override
  String get serialRequired => 'Informe ou leia o número de série.';

  @override
  String get search => 'Buscar';

  @override
  String get readQrCode => 'Ler QR Code';

  @override
  String get qrOnlyMobile =>
      'Leitura de QR está disponível no app Android/iOS.';

  @override
  String get catalogTitle => 'Catálogo de produtos rastreados';

  @override
  String get catalogFilterHint => 'Filtrar por serial ou local…';

  @override
  String get movementHistory => 'Histórico de movimentações';

  @override
  String get noMovementsYet => 'Nenhuma movimentação registrada ainda.';

  @override
  String get newMovement => 'Nova movimentação';

  @override
  String get motivesAdminHint =>
      'Cadastre motivos no Django Admin (Motivos de movimentação).';

  @override
  String get motive => 'Motivo';

  @override
  String get selectOption => 'Selecione';

  @override
  String get selectMotive => 'Selecione o motivo da movimentação.';

  @override
  String get registeredLocationsHint =>
      'Locais cadastrados (toque para preencher o destino)';

  @override
  String get destinationRequired => 'Informe o local de destino.';

  @override
  String get destinationLocation => 'Local de destino';

  @override
  String get observationsOptional => 'Observações / detalhes (opcional)';

  @override
  String get registerMovement => 'Registrar movimentação';

  @override
  String get movementSaved => 'Movimentação registrada.';

  @override
  String get selectedProduct => 'Produto selecionado';

  @override
  String get client => 'Cliente';

  @override
  String get subclient => 'Subcliente';

  @override
  String get currentLocation => 'Local atual';

  @override
  String get flashlightTooltip => 'Lanterna';

  @override
  String get scanQrTitle => 'Ler QR Code';

  @override
  String get scanQrHint =>
      'Aponte para o QR do produto. Pode ser só o serial em texto ou um link com ?sn=';

  @override
  String get serialLookupIntro =>
      'Consulte o cadastro de estoque pelo número de série (mesmo modelo do Django: Rastreamento serial).';

  @override
  String get serialTrackTitle => 'Rastrear produto';

  @override
  String get productAllocationHeading => 'Produto / alocação';

  @override
  String get stockUnitLabel => 'Unidade de estoque';

  @override
  String get observationsLabel => 'Observações';

  @override
  String get updatedAtLabel => 'Atualizado em';

  @override
  String get subclientBranchLabel => 'Subcliente / filial';

  @override
  String get enterSerialHint => 'Digite ou use o leitor de QR';

  @override
  String get helpdeskTitle => 'Helpdesk';

  @override
  String motivesLoadError(String error) {
    return 'Erro ao carregar motivos: $error';
  }

  @override
  String get movementFrom => 'de:';

  @override
  String movementAuthor(String name) {
    return 'por $name';
  }

  @override
  String get expenseModuleTitle => 'Despesas';

  @override
  String get expenseListTile => 'Lista';

  @override
  String get expenseApprovalsTile => 'Aprovações';

  @override
  String get expensePaymentsTile => 'Pagamentos';

  @override
  String get expenseDashboardTile => 'Dashboard';

  @override
  String get expenseNoCompanies =>
      'Nenhum cliente disponível para despesas. Verifique seu vínculo no portal.';

  @override
  String get expenseSelectClient => 'Cliente';

  @override
  String get expenseStatusFilter => 'Status';

  @override
  String get expenseStatusAll => 'Todos';

  @override
  String get expenseStatusDraft => 'Rascunho';

  @override
  String get expenseStatusPending => 'Pendente';

  @override
  String get expenseStatusApproved => 'Aprovada';

  @override
  String get expenseStatusRejected => 'Rejeitada';

  @override
  String get expenseStatusAudited => 'Auditada';

  @override
  String get expenseStatusPaid => 'Paga';

  @override
  String get expenseNew => 'Nova despesa';

  @override
  String get expenseEdit => 'Editar';

  @override
  String get expenseDetail => 'Detalhe';

  @override
  String get expenseFieldTitle => 'Título';

  @override
  String get expenseFieldDescription => 'Descrição';

  @override
  String get expenseFieldAmount => 'Valor';

  @override
  String get expenseFieldDate => 'Data';

  @override
  String get expenseFieldLocation => 'Local';

  @override
  String get expenseTipoDespesa => 'Tipo de despesa';

  @override
  String get expenseCentroCusto => 'Centro de custo (opcional)';

  @override
  String get expenseContractId => 'ID do contrato (opcional)';

  @override
  String get expenseResponsible => 'Responsável (opcional)';

  @override
  String get expenseReceipt => 'Comprovante';

  @override
  String get expensePickFile => 'Escolher arquivo';

  @override
  String get expenseSaveDraft => 'Salvar rascunho';

  @override
  String get expenseSubmitApproval => 'Enviar para aprovação';

  @override
  String get expenseDelete => 'Excluir';

  @override
  String get expenseApprove => 'Aprovar';

  @override
  String get expenseReject => 'Rejeitar';

  @override
  String get expenseMarkAudited => 'Marcar auditada';

  @override
  String get expenseMarkPaid => 'Marcar paga';

  @override
  String get expenseCommentHint => 'Comentário (opcional)';

  @override
  String get expenseAuditTitle => 'Histórico';

  @override
  String get expenseRiskScore => 'Score de risco';

  @override
  String get expenseOpenReceipt => 'Abrir comprovante';

  @override
  String get expenseDuplicateWarning =>
      'Comprovante possivelmente duplicado. Continuar mesmo assim?';

  @override
  String get expenseAnalyticsHint =>
      'Resumo numérico retornado pela API (mesmo endpoint do portal).';

  @override
  String expenseLoadError(String message) {
    return 'Erro: $message';
  }

  @override
  String get expenseEmptyList => 'Nenhuma despesa neste filtro.';

  @override
  String get expenseTitleRequired => 'Informe o título.';

  @override
  String get expenseAmountInvalid =>
      'Informe um valor numérico maior que zero.';

  @override
  String get expenseAuthor => 'Autor';

  @override
  String get expenseDeleteConfirm => 'Excluir este rascunho permanentemente?';

  @override
  String get expenseGroupsTile => 'Agrupamentos';

  @override
  String get expenseBatchImportTile => 'Importar lote';

  @override
  String get expenseAuditModuleTile => 'Auditoria';

  @override
  String get expenseRefresh => 'Atualizar';

  @override
  String get expenseGroupListTitle => 'Agrupamentos (rascunhos)';

  @override
  String get expenseGroupDetailTitle => 'Lote';

  @override
  String get expenseGroupSubmitBatch => 'Enviar lote para aprovação';

  @override
  String get expenseGroupMembers => 'Despesas no lote';

  @override
  String get expensePendingGroupsTitle => 'Grupos pendentes';

  @override
  String get expenseByExpenseTitle => 'Por despesa';

  @override
  String get expenseApproveGroup => 'Aprovar grupo';

  @override
  String get expenseRejectGroup => 'Rejeitar grupo';

  @override
  String get expensePaymentsScreenTitle => 'Pagamentos (financeiro)';

  @override
  String get expenseSelectAll => 'Selecionar todas';

  @override
  String get expenseDeselectAll => 'Limpar seleção';

  @override
  String get expenseExportCsv => 'Copiar CSV';

  @override
  String get expenseExportCsvDone =>
      'CSV copiado para a área de transferência.';

  @override
  String get expenseApplyReturn => 'Aplicar retorno CSV';

  @override
  String get expenseSapSend => 'Enviar ao SAP';

  @override
  String get expenseSapBulk => 'SAP selecionadas';

  @override
  String get expenseFinanceApprove => 'Aprovar (financeiro)';

  @override
  String get expenseFinanceReject => 'Rejeitar (financeiro)';

  @override
  String get expenseAnomaliesTitle => 'Anomalias';

  @override
  String get expenseExtractedTitle => 'Dados extraídos (OCR)';

  @override
  String get expenseApprovalsChainTitle => 'Aprovações por nível';

  @override
  String get expenseAgrupamentoTitulo => 'Agrupamento';

  @override
  String get expenseBatchImportHint =>
      'Informe o título do agrupamento e selecione imagens de comprovantes. Serão criadas despesas em rascunho (OCR + classificação quando disponível).';

  @override
  String get expenseOcrFill => 'Preencher com OCR';

  @override
  String get expenseClassifyTipo => 'Sugerir tipo (IA)';

  @override
  String get expenseStatusPendingFinance => 'Pend. financeiro';

  @override
  String get expenseStatusFinanceApproved => 'Aprov. financeiro';

  @override
  String get expenseStatusFinanceRejected => 'Rej. financeiro';

  @override
  String get expenseDateFrom => 'Data inicial';

  @override
  String get expenseDateTo => 'Data final';

  @override
  String get expenseClearPeriod => 'Limpar período';

  @override
  String get expenseApplyReturnResult => 'Resultado do retorno';

  @override
  String get expenseSelectOne => 'Selecione ao menos uma despesa.';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get assetsModuleTitle => 'Controle de assets';

  @override
  String get assetsNoClient => 'Selecione um cliente para continuar.';

  @override
  String get assetsTabProducts => 'Produtos';

  @override
  String get assetsTabAssets => 'Ativos';

  @override
  String get assetsTabMovements => 'Movimentações';

  @override
  String get assetsInsertProduct => 'Novo produto';

  @override
  String get assetsFieldName => 'Nome';

  @override
  String get assetsFieldBrand => 'Marca';

  @override
  String get assetsFieldModel => 'Modelo';

  @override
  String get assetsFieldInternalCode => 'Código interno';

  @override
  String get assetsFieldType => 'Tipo';

  @override
  String get assetsTypeHardware => 'Hardware';

  @override
  String get assetsTypeService => 'Serviço';

  @override
  String get assetsFieldDescription => 'Descrição';

  @override
  String get assetsFieldDatasheet => 'Ficha técnica (URL)';

  @override
  String get assetsFieldManual => 'Manual (arquivo)';

  @override
  String get assetsSaveProduct => 'Salvar produto';

  @override
  String get assetsInsertAsset => 'Novo ativo';

  @override
  String get assetsFilterByProduct => 'Produto';

  @override
  String get assetsSerial => 'Número de série';

  @override
  String get assetsPartNumber => 'Part number';

  @override
  String get assetsDisplayName => 'Nome de exibição';

  @override
  String get assetsMovPrereq =>
      'Cadastre produtos, ativos e ao menos um motivo de movimentação.';

  @override
  String get assetsNewMovement => 'Nova movimentação';

  @override
  String get assetsColAsset => 'Ativo';

  @override
  String get assetsMotivo => 'Motivo';

  @override
  String get assetsDestino => 'Destino';

  @override
  String get assetsResponsible => 'Responsável';

  @override
  String get assetsObservation => 'Observação';

  @override
  String get assetsSaveMovement => 'Registrar movimentação';

  @override
  String get assetsEditAsset => 'Editar ativo';

  @override
  String get assetsEditProduct => 'Editar produto';

  @override
  String get assetsColActive => 'Ativo';

  @override
  String get assetsFilterSearch => 'Buscar…';

  @override
  String get assetsFilterSearchAssets => 'Buscar ativos…';

  @override
  String get assetsAllProducts => 'Todos os produtos';

  @override
  String get assetsFilterTipoAll => 'Todos os tipos';

  @override
  String get assetsFilterAtivoAll => 'Todos';

  @override
  String get assetsFilterAtivoYes => 'Somente ativos';

  @override
  String get assetsFilterAtivoNo => 'Somente inativos';

  @override
  String get assetsYesShort => 'Sim';

  @override
  String get assetsNoShort => 'Não';

  @override
  String get assetsProductTrackingHint => 'Ver ativos deste produto';
}
