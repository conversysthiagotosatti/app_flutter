import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conversys'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Padrão do sistema'**
  String get languageSystem;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acesse para gerenciar os módulos disponíveis para o seu cliente.'**
  String get loginSubtitle;

  /// No description provided for @usernameOrEmail.
  ///
  /// In pt, this message translates to:
  /// **'Usuário ou e-mail'**
  String get usernameOrEmail;

  /// No description provided for @usernameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o usuário'**
  String get usernameRequired;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a senha'**
  String get passwordRequired;

  /// No description provided for @signIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get signIn;

  /// No description provided for @invalidCredentials.
  ///
  /// In pt, this message translates to:
  /// **'Credenciais inválidas ou acesso ao cliente não permitido.'**
  String get invalidCredentials;

  /// No description provided for @blueHuddleTitle.
  ///
  /// In pt, this message translates to:
  /// **'The Blue Huddle'**
  String get blueHuddleTitle;

  /// No description provided for @taglineConversys.
  ///
  /// In pt, this message translates to:
  /// **'Uma linha projetada pela Conversys'**
  String get taglineConversys;

  /// No description provided for @predefinedArchitectures.
  ///
  /// In pt, this message translates to:
  /// **'Arquiteturas pré-definidas de tecnologia'**
  String get predefinedArchitectures;

  /// No description provided for @servicesIntro.
  ///
  /// In pt, this message translates to:
  /// **'Acesse seus serviços ativos abaixo ou explore novas soluções integradas da Conversys.'**
  String get servicesIntro;

  /// No description provided for @myServices.
  ///
  /// In pt, this message translates to:
  /// **'Meus serviços'**
  String get myServices;

  /// No description provided for @noModulesForUser.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum módulo disponível para este usuário.'**
  String get noModulesForUser;

  /// No description provided for @moduleDefaultName.
  ///
  /// In pt, this message translates to:
  /// **'Módulo'**
  String get moduleDefaultName;

  /// No description provided for @statusActive.
  ///
  /// In pt, this message translates to:
  /// **'ATIVO'**
  String get statusActive;

  /// No description provided for @accessConsole.
  ///
  /// In pt, this message translates to:
  /// **'Acessar console'**
  String get accessConsole;

  /// No description provided for @notifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @signOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get signOut;

  /// No description provided for @navClients.
  ///
  /// In pt, this message translates to:
  /// **'Clientes'**
  String get navClients;

  /// No description provided for @navContracts.
  ///
  /// In pt, this message translates to:
  /// **'Contratos'**
  String get navContracts;

  /// No description provided for @navTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get navTasks;

  /// No description provided for @moduleUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'O módulo \"{name}\" ainda não está disponível no app mobile.'**
  String moduleUnavailable(String name);

  /// No description provided for @inDevelopment.
  ///
  /// In pt, this message translates to:
  /// **'Em desenvolvimento'**
  String get inDevelopment;

  /// No description provided for @tarefasDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get tarefasDashboard;

  /// No description provided for @tarefasTracking.
  ///
  /// In pt, this message translates to:
  /// **'Rastreamento e movimentação'**
  String get tarefasTracking;

  /// No description provided for @tarefasCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Calendário'**
  String get tarefasCalendar;

  /// No description provided for @tarefasCopilot.
  ///
  /// In pt, this message translates to:
  /// **'Copilot IA'**
  String get tarefasCopilot;

  /// No description provided for @tarefasAnalyzeAi.
  ///
  /// In pt, this message translates to:
  /// **'Analisar com IA'**
  String get tarefasAnalyzeAi;

  /// No description provided for @tarefasRegisterEpic.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar Épico'**
  String get tarefasRegisterEpic;

  /// No description provided for @tarefasNewTask.
  ///
  /// In pt, this message translates to:
  /// **'Nova tarefa'**
  String get tarefasNewTask;

  /// No description provided for @tarefasKanban.
  ///
  /// In pt, this message translates to:
  /// **'Kanban'**
  String get tarefasKanban;

  /// No description provided for @tarefasReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get tarefasReports;

  /// No description provided for @tarefasDocuments.
  ///
  /// In pt, this message translates to:
  /// **'Documentos'**
  String get tarefasDocuments;

  /// No description provided for @tarefasKanbanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Kanban de tarefas'**
  String get tarefasKanbanTitle;

  /// No description provided for @stockTrackingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Rastreamento e movimentação'**
  String get stockTrackingTitle;

  /// No description provided for @stockTrackingIntro.
  ///
  /// In pt, this message translates to:
  /// **'Consulte o produto pelo serial ou escolha no catálogo. Registre mudanças de local com motivo e destino.'**
  String get stockTrackingIntro;

  /// No description provided for @serialLabel.
  ///
  /// In pt, this message translates to:
  /// **'Serial'**
  String get serialLabel;

  /// No description provided for @serialNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número de série'**
  String get serialNumber;

  /// No description provided for @serialRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe ou leia o número de série.'**
  String get serialRequired;

  /// No description provided for @search.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @readQrCode.
  ///
  /// In pt, this message translates to:
  /// **'Ler QR Code'**
  String get readQrCode;

  /// No description provided for @qrOnlyMobile.
  ///
  /// In pt, this message translates to:
  /// **'Leitura de QR está disponível no app Android/iOS.'**
  String get qrOnlyMobile;

  /// No description provided for @catalogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Catálogo de produtos rastreados'**
  String get catalogTitle;

  /// No description provided for @catalogFilterHint.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por serial ou local…'**
  String get catalogFilterHint;

  /// No description provided for @movementHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de movimentações'**
  String get movementHistory;

  /// No description provided for @noMovementsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação registrada ainda.'**
  String get noMovementsYet;

  /// No description provided for @newMovement.
  ///
  /// In pt, this message translates to:
  /// **'Nova movimentação'**
  String get newMovement;

  /// No description provided for @motivesAdminHint.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre motivos no Django Admin (Motivos de movimentação).'**
  String get motivesAdminHint;

  /// No description provided for @motive.
  ///
  /// In pt, this message translates to:
  /// **'Motivo'**
  String get motive;

  /// No description provided for @selectOption.
  ///
  /// In pt, this message translates to:
  /// **'Selecione'**
  String get selectOption;

  /// No description provided for @selectMotive.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o motivo da movimentação.'**
  String get selectMotive;

  /// No description provided for @registeredLocationsHint.
  ///
  /// In pt, this message translates to:
  /// **'Locais cadastrados (toque para preencher o destino)'**
  String get registeredLocationsHint;

  /// No description provided for @destinationRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o local de destino.'**
  String get destinationRequired;

  /// No description provided for @destinationLocation.
  ///
  /// In pt, this message translates to:
  /// **'Local de destino'**
  String get destinationLocation;

  /// No description provided for @observationsOptional.
  ///
  /// In pt, this message translates to:
  /// **'Observações / detalhes (opcional)'**
  String get observationsOptional;

  /// No description provided for @registerMovement.
  ///
  /// In pt, this message translates to:
  /// **'Registrar movimentação'**
  String get registerMovement;

  /// No description provided for @movementSaved.
  ///
  /// In pt, this message translates to:
  /// **'Movimentação registrada.'**
  String get movementSaved;

  /// No description provided for @selectedProduct.
  ///
  /// In pt, this message translates to:
  /// **'Produto selecionado'**
  String get selectedProduct;

  /// No description provided for @client.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get client;

  /// No description provided for @subclient.
  ///
  /// In pt, this message translates to:
  /// **'Subcliente'**
  String get subclient;

  /// No description provided for @currentLocation.
  ///
  /// In pt, this message translates to:
  /// **'Local atual'**
  String get currentLocation;

  /// No description provided for @flashlightTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Lanterna'**
  String get flashlightTooltip;

  /// No description provided for @scanQrTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ler QR Code'**
  String get scanQrTitle;

  /// No description provided for @scanQrHint.
  ///
  /// In pt, this message translates to:
  /// **'Aponte para o QR do produto. Pode ser só o serial em texto ou um link com ?sn='**
  String get scanQrHint;

  /// No description provided for @serialLookupIntro.
  ///
  /// In pt, this message translates to:
  /// **'Consulte o cadastro de estoque pelo número de série (mesmo modelo do Django: Rastreamento serial).'**
  String get serialLookupIntro;

  /// No description provided for @serialTrackTitle.
  ///
  /// In pt, this message translates to:
  /// **'Rastrear produto'**
  String get serialTrackTitle;

  /// No description provided for @productAllocationHeading.
  ///
  /// In pt, this message translates to:
  /// **'Produto / alocação'**
  String get productAllocationHeading;

  /// No description provided for @stockUnitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade de estoque'**
  String get stockUnitLabel;

  /// No description provided for @observationsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get observationsLabel;

  /// No description provided for @updatedAtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Atualizado em'**
  String get updatedAtLabel;

  /// No description provided for @subclientBranchLabel.
  ///
  /// In pt, this message translates to:
  /// **'Subcliente / filial'**
  String get subclientBranchLabel;

  /// No description provided for @enterSerialHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite ou use o leitor de QR'**
  String get enterSerialHint;

  /// No description provided for @helpdeskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Helpdesk'**
  String get helpdeskTitle;

  /// No description provided for @motivesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar motivos: {error}'**
  String motivesLoadError(String error);

  /// No description provided for @movementFrom.
  ///
  /// In pt, this message translates to:
  /// **'de:'**
  String get movementFrom;

  /// No description provided for @movementAuthor.
  ///
  /// In pt, this message translates to:
  /// **'por {name}'**
  String movementAuthor(String name);

  /// No description provided for @expenseModuleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get expenseModuleTitle;

  /// No description provided for @expenseListTile.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get expenseListTile;

  /// No description provided for @expenseApprovalsTile.
  ///
  /// In pt, this message translates to:
  /// **'Aprovações'**
  String get expenseApprovalsTile;

  /// No description provided for @expensePaymentsTile.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos'**
  String get expensePaymentsTile;

  /// No description provided for @expenseDashboardTile.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get expenseDashboardTile;

  /// No description provided for @expenseNoCompanies.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cliente disponível para despesas. Verifique seu vínculo no portal.'**
  String get expenseNoCompanies;

  /// No description provided for @expenseSelectClient.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get expenseSelectClient;

  /// No description provided for @expenseStatusFilter.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get expenseStatusFilter;

  /// No description provided for @expenseStatusAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get expenseStatusAll;

  /// No description provided for @expenseStatusDraft.
  ///
  /// In pt, this message translates to:
  /// **'Rascunho'**
  String get expenseStatusDraft;

  /// No description provided for @expenseStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get expenseStatusPending;

  /// No description provided for @expenseStatusApproved.
  ///
  /// In pt, this message translates to:
  /// **'Aprovada'**
  String get expenseStatusApproved;

  /// No description provided for @expenseStatusRejected.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitada'**
  String get expenseStatusRejected;

  /// No description provided for @expenseStatusAudited.
  ///
  /// In pt, this message translates to:
  /// **'Auditada'**
  String get expenseStatusAudited;

  /// No description provided for @expenseStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Paga'**
  String get expenseStatusPaid;

  /// No description provided for @expenseNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova despesa'**
  String get expenseNew;

  /// No description provided for @expenseEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get expenseEdit;

  /// No description provided for @expenseDetail.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe'**
  String get expenseDetail;

  /// No description provided for @expenseFieldTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get expenseFieldTitle;

  /// No description provided for @expenseFieldDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get expenseFieldDescription;

  /// No description provided for @expenseFieldAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get expenseFieldAmount;

  /// No description provided for @expenseFieldDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get expenseFieldDate;

  /// No description provided for @expenseFieldLocation.
  ///
  /// In pt, this message translates to:
  /// **'Local'**
  String get expenseFieldLocation;

  /// No description provided for @expenseTipoDespesa.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de despesa'**
  String get expenseTipoDespesa;

  /// No description provided for @expenseCentroCusto.
  ///
  /// In pt, this message translates to:
  /// **'Centro de custo (opcional)'**
  String get expenseCentroCusto;

  /// No description provided for @expenseContractId.
  ///
  /// In pt, this message translates to:
  /// **'ID do contrato (opcional)'**
  String get expenseContractId;

  /// No description provided for @expenseResponsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável (opcional)'**
  String get expenseResponsible;

  /// No description provided for @expenseReceipt.
  ///
  /// In pt, this message translates to:
  /// **'Comprovante'**
  String get expenseReceipt;

  /// No description provided for @expensePickFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolher arquivo'**
  String get expensePickFile;

  /// No description provided for @expenseSaveDraft.
  ///
  /// In pt, this message translates to:
  /// **'Salvar rascunho'**
  String get expenseSaveDraft;

  /// No description provided for @expenseSubmitApproval.
  ///
  /// In pt, this message translates to:
  /// **'Enviar para aprovação'**
  String get expenseSubmitApproval;

  /// No description provided for @expenseDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get expenseDelete;

  /// No description provided for @expenseApprove.
  ///
  /// In pt, this message translates to:
  /// **'Aprovar'**
  String get expenseApprove;

  /// No description provided for @expenseReject.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar'**
  String get expenseReject;

  /// No description provided for @expenseMarkAudited.
  ///
  /// In pt, this message translates to:
  /// **'Marcar auditada'**
  String get expenseMarkAudited;

  /// No description provided for @expenseMarkPaid.
  ///
  /// In pt, this message translates to:
  /// **'Marcar paga'**
  String get expenseMarkPaid;

  /// No description provided for @expenseCommentHint.
  ///
  /// In pt, this message translates to:
  /// **'Comentário (opcional)'**
  String get expenseCommentHint;

  /// No description provided for @expenseAuditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get expenseAuditTitle;

  /// No description provided for @expenseRiskScore.
  ///
  /// In pt, this message translates to:
  /// **'Score de risco'**
  String get expenseRiskScore;

  /// No description provided for @expenseOpenReceipt.
  ///
  /// In pt, this message translates to:
  /// **'Abrir comprovante'**
  String get expenseOpenReceipt;

  /// No description provided for @expenseDuplicateWarning.
  ///
  /// In pt, this message translates to:
  /// **'Comprovante possivelmente duplicado. Continuar mesmo assim?'**
  String get expenseDuplicateWarning;

  /// No description provided for @expenseAnalyticsHint.
  ///
  /// In pt, this message translates to:
  /// **'Resumo numérico retornado pela API (mesmo endpoint do portal).'**
  String get expenseAnalyticsHint;

  /// No description provided for @expenseLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {message}'**
  String expenseLoadError(String message);

  /// No description provided for @expenseEmptyList.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma despesa neste filtro.'**
  String get expenseEmptyList;

  /// No description provided for @expenseTitleRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o título.'**
  String get expenseTitleRequired;

  /// No description provided for @expenseAmountInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe um valor numérico maior que zero.'**
  String get expenseAmountInvalid;

  /// No description provided for @expenseAuthor.
  ///
  /// In pt, this message translates to:
  /// **'Autor'**
  String get expenseAuthor;

  /// No description provided for @expenseDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir este rascunho permanentemente?'**
  String get expenseDeleteConfirm;

  /// No description provided for @expenseGroupsTile.
  ///
  /// In pt, this message translates to:
  /// **'Agrupamentos'**
  String get expenseGroupsTile;

  /// No description provided for @expenseBatchImportTile.
  ///
  /// In pt, this message translates to:
  /// **'Importar lote'**
  String get expenseBatchImportTile;

  /// No description provided for @expenseAuditModuleTile.
  ///
  /// In pt, this message translates to:
  /// **'Auditoria'**
  String get expenseAuditModuleTile;

  /// No description provided for @expenseRefresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get expenseRefresh;

  /// No description provided for @expenseGroupListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Agrupamentos (rascunhos)'**
  String get expenseGroupListTitle;

  /// No description provided for @expenseGroupDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lote'**
  String get expenseGroupDetailTitle;

  /// No description provided for @expenseGroupSubmitBatch.
  ///
  /// In pt, this message translates to:
  /// **'Enviar lote para aprovação'**
  String get expenseGroupSubmitBatch;

  /// No description provided for @expenseGroupMembers.
  ///
  /// In pt, this message translates to:
  /// **'Despesas no lote'**
  String get expenseGroupMembers;

  /// No description provided for @expensePendingGroupsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Grupos pendentes'**
  String get expensePendingGroupsTitle;

  /// No description provided for @expenseByExpenseTitle.
  ///
  /// In pt, this message translates to:
  /// **'Por despesa'**
  String get expenseByExpenseTitle;

  /// No description provided for @expenseApproveGroup.
  ///
  /// In pt, this message translates to:
  /// **'Aprovar grupo'**
  String get expenseApproveGroup;

  /// No description provided for @expenseRejectGroup.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar grupo'**
  String get expenseRejectGroup;

  /// No description provided for @expensePaymentsScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos (financeiro)'**
  String get expensePaymentsScreenTitle;

  /// No description provided for @expenseSelectAll.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar todas'**
  String get expenseSelectAll;

  /// No description provided for @expenseDeselectAll.
  ///
  /// In pt, this message translates to:
  /// **'Limpar seleção'**
  String get expenseDeselectAll;

  /// No description provided for @expenseExportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Copiar CSV'**
  String get expenseExportCsv;

  /// No description provided for @expenseExportCsvDone.
  ///
  /// In pt, this message translates to:
  /// **'CSV copiado para a área de transferência.'**
  String get expenseExportCsvDone;

  /// No description provided for @expenseApplyReturn.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar retorno CSV'**
  String get expenseApplyReturn;

  /// No description provided for @expenseSapSend.
  ///
  /// In pt, this message translates to:
  /// **'Enviar ao SAP'**
  String get expenseSapSend;

  /// No description provided for @expenseSapBulk.
  ///
  /// In pt, this message translates to:
  /// **'SAP selecionadas'**
  String get expenseSapBulk;

  /// No description provided for @expenseFinanceApprove.
  ///
  /// In pt, this message translates to:
  /// **'Aprovar (financeiro)'**
  String get expenseFinanceApprove;

  /// No description provided for @expenseFinanceReject.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar (financeiro)'**
  String get expenseFinanceReject;

  /// No description provided for @expenseAnomaliesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Anomalias'**
  String get expenseAnomaliesTitle;

  /// No description provided for @expenseExtractedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dados extraídos (OCR)'**
  String get expenseExtractedTitle;

  /// No description provided for @expenseApprovalsChainTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aprovações por nível'**
  String get expenseApprovalsChainTitle;

  /// No description provided for @expenseAgrupamentoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Agrupamento'**
  String get expenseAgrupamentoTitulo;

  /// No description provided for @expenseBatchImportHint.
  ///
  /// In pt, this message translates to:
  /// **'Informe o título do agrupamento e selecione imagens de comprovantes. Serão criadas despesas em rascunho (OCR + classificação quando disponível).'**
  String get expenseBatchImportHint;

  /// No description provided for @expenseOcrFill.
  ///
  /// In pt, this message translates to:
  /// **'Preencher com OCR'**
  String get expenseOcrFill;

  /// No description provided for @expenseClassifyTipo.
  ///
  /// In pt, this message translates to:
  /// **'Sugerir tipo (IA)'**
  String get expenseClassifyTipo;

  /// No description provided for @expenseStatusPendingFinance.
  ///
  /// In pt, this message translates to:
  /// **'Pend. financeiro'**
  String get expenseStatusPendingFinance;

  /// No description provided for @expenseStatusFinanceApproved.
  ///
  /// In pt, this message translates to:
  /// **'Aprov. financeiro'**
  String get expenseStatusFinanceApproved;

  /// No description provided for @expenseStatusFinanceRejected.
  ///
  /// In pt, this message translates to:
  /// **'Rej. financeiro'**
  String get expenseStatusFinanceRejected;

  /// No description provided for @expenseDateFrom.
  ///
  /// In pt, this message translates to:
  /// **'Data inicial'**
  String get expenseDateFrom;

  /// No description provided for @expenseDateTo.
  ///
  /// In pt, this message translates to:
  /// **'Data final'**
  String get expenseDateTo;

  /// No description provided for @expenseClearPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Limpar período'**
  String get expenseClearPeriod;

  /// No description provided for @expenseApplyReturnResult.
  ///
  /// In pt, this message translates to:
  /// **'Resultado do retorno'**
  String get expenseApplyReturnResult;

  /// No description provided for @expenseSelectOne.
  ///
  /// In pt, this message translates to:
  /// **'Selecione ao menos uma despesa.'**
  String get expenseSelectOne;

  /// No description provided for @continueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @assetsModuleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Controle de assets'**
  String get assetsModuleTitle;

  /// No description provided for @assetsNoClient.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um cliente para continuar.'**
  String get assetsNoClient;

  /// No description provided for @assetsTabProducts.
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get assetsTabProducts;

  /// No description provided for @assetsTabAssets.
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get assetsTabAssets;

  /// No description provided for @assetsTabMovements.
  ///
  /// In pt, this message translates to:
  /// **'Movimentações'**
  String get assetsTabMovements;

  /// No description provided for @assetsInsertProduct.
  ///
  /// In pt, this message translates to:
  /// **'Novo produto'**
  String get assetsInsertProduct;

  /// No description provided for @assetsFieldName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get assetsFieldName;

  /// No description provided for @assetsFieldBrand.
  ///
  /// In pt, this message translates to:
  /// **'Marca'**
  String get assetsFieldBrand;

  /// No description provided for @assetsFieldModel.
  ///
  /// In pt, this message translates to:
  /// **'Modelo'**
  String get assetsFieldModel;

  /// No description provided for @assetsFieldInternalCode.
  ///
  /// In pt, this message translates to:
  /// **'Código interno'**
  String get assetsFieldInternalCode;

  /// No description provided for @assetsFieldType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get assetsFieldType;

  /// No description provided for @assetsTypeHardware.
  ///
  /// In pt, this message translates to:
  /// **'Hardware'**
  String get assetsTypeHardware;

  /// No description provided for @assetsTypeService.
  ///
  /// In pt, this message translates to:
  /// **'Serviço'**
  String get assetsTypeService;

  /// No description provided for @assetsFieldDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get assetsFieldDescription;

  /// No description provided for @assetsFieldDatasheet.
  ///
  /// In pt, this message translates to:
  /// **'Ficha técnica (URL)'**
  String get assetsFieldDatasheet;

  /// No description provided for @assetsFieldManual.
  ///
  /// In pt, this message translates to:
  /// **'Manual (arquivo)'**
  String get assetsFieldManual;

  /// No description provided for @assetsSaveProduct.
  ///
  /// In pt, this message translates to:
  /// **'Salvar produto'**
  String get assetsSaveProduct;

  /// No description provided for @assetsInsertAsset.
  ///
  /// In pt, this message translates to:
  /// **'Novo ativo'**
  String get assetsInsertAsset;

  /// No description provided for @assetsFilterByProduct.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get assetsFilterByProduct;

  /// No description provided for @assetsSerial.
  ///
  /// In pt, this message translates to:
  /// **'Número de série'**
  String get assetsSerial;

  /// No description provided for @assetsPartNumber.
  ///
  /// In pt, this message translates to:
  /// **'Part number'**
  String get assetsPartNumber;

  /// No description provided for @assetsDisplayName.
  ///
  /// In pt, this message translates to:
  /// **'Nome de exibição'**
  String get assetsDisplayName;

  /// No description provided for @assetsMovPrereq.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre produtos, ativos e ao menos um motivo de movimentação.'**
  String get assetsMovPrereq;

  /// No description provided for @assetsNewMovement.
  ///
  /// In pt, this message translates to:
  /// **'Nova movimentação'**
  String get assetsNewMovement;

  /// No description provided for @assetsColAsset.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get assetsColAsset;

  /// No description provided for @assetsMotivo.
  ///
  /// In pt, this message translates to:
  /// **'Motivo'**
  String get assetsMotivo;

  /// No description provided for @assetsDestino.
  ///
  /// In pt, this message translates to:
  /// **'Destino'**
  String get assetsDestino;

  /// No description provided for @assetsResponsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get assetsResponsible;

  /// No description provided for @assetsObservation.
  ///
  /// In pt, this message translates to:
  /// **'Observação'**
  String get assetsObservation;

  /// No description provided for @assetsSaveMovement.
  ///
  /// In pt, this message translates to:
  /// **'Registrar movimentação'**
  String get assetsSaveMovement;

  /// No description provided for @assetsEditAsset.
  ///
  /// In pt, this message translates to:
  /// **'Editar ativo'**
  String get assetsEditAsset;

  /// No description provided for @assetsEditProduct.
  ///
  /// In pt, this message translates to:
  /// **'Editar produto'**
  String get assetsEditProduct;

  /// No description provided for @assetsColActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get assetsColActive;

  /// No description provided for @assetsFilterSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar…'**
  String get assetsFilterSearch;

  /// No description provided for @assetsFilterSearchAssets.
  ///
  /// In pt, this message translates to:
  /// **'Buscar ativos…'**
  String get assetsFilterSearchAssets;

  /// No description provided for @assetsAllProducts.
  ///
  /// In pt, this message translates to:
  /// **'Todos os produtos'**
  String get assetsAllProducts;

  /// No description provided for @assetsFilterTipoAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos os tipos'**
  String get assetsFilterTipoAll;

  /// No description provided for @assetsFilterAtivoAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get assetsFilterAtivoAll;

  /// No description provided for @assetsFilterAtivoYes.
  ///
  /// In pt, this message translates to:
  /// **'Somente ativos'**
  String get assetsFilterAtivoYes;

  /// No description provided for @assetsFilterAtivoNo.
  ///
  /// In pt, this message translates to:
  /// **'Somente inativos'**
  String get assetsFilterAtivoNo;

  /// No description provided for @assetsYesShort.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get assetsYesShort;

  /// No description provided for @assetsNoShort.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get assetsNoShort;

  /// No description provided for @assetsProductTrackingHint.
  ///
  /// In pt, this message translates to:
  /// **'Ver ativos deste produto'**
  String get assetsProductTrackingHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
