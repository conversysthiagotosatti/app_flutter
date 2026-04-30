// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Conversys';

  @override
  String get language => 'Language';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'System default';

  @override
  String get loginSubtitle =>
      'Sign in to manage the modules available for your client.';

  @override
  String get usernameOrEmail => 'Username or email';

  @override
  String get usernameRequired => 'Enter your username';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get signIn => 'Sign in';

  @override
  String get invalidCredentials =>
      'Invalid credentials or client access not allowed.';

  @override
  String get blueHuddleTitle => 'The Blue Huddle';

  @override
  String get taglineConversys => 'A line engineered by Conversys';

  @override
  String get predefinedArchitectures => 'Predefined technology architectures';

  @override
  String get servicesIntro =>
      'Access your active services below or explore new integrated solutions from Conversys.';

  @override
  String get myServices => 'My services';

  @override
  String get noModulesForUser => 'No modules available for this user.';

  @override
  String get moduleDefaultName => 'Module';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String get accessConsole => 'Open console';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get signOut => 'Sign out';

  @override
  String get navClients => 'Clients';

  @override
  String get navContracts => 'Contracts';

  @override
  String get navTasks => 'Tasks';

  @override
  String moduleUnavailable(String name) {
    return 'The module \"$name\" is not yet available in the mobile app.';
  }

  @override
  String get inDevelopment => 'Under development';

  @override
  String get tarefasDashboard => 'Dashboard';

  @override
  String get tarefasTracking => 'Tracking & stock moves';

  @override
  String get tarefasCalendar => 'Calendar';

  @override
  String get tarefasCopilot => 'AI Copilot';

  @override
  String get tarefasAnalyzeAi => 'Analyze with AI';

  @override
  String get tarefasRegisterEpic => 'Register epic';

  @override
  String get tarefasNewTask => 'New task';

  @override
  String get tarefasKanban => 'Kanban';

  @override
  String get tarefasReports => 'Reports';

  @override
  String get tarefasDocuments => 'Documents';

  @override
  String get tarefasKanbanTitle => 'Task kanban';

  @override
  String get stockTrackingTitle => 'Tracking & stock moves';

  @override
  String get stockTrackingIntro =>
      'Look up a product by serial or pick it from the catalog. Record location changes with a reason and destination.';

  @override
  String get serialLabel => 'Serial';

  @override
  String get serialNumber => 'Serial number';

  @override
  String get serialRequired => 'Enter or scan the serial number.';

  @override
  String get search => 'Search';

  @override
  String get readQrCode => 'Scan QR code';

  @override
  String get qrOnlyMobile => 'QR scanning is available on Android/iOS.';

  @override
  String get catalogTitle => 'Tracked products catalog';

  @override
  String get catalogFilterHint => 'Filter by serial or location…';

  @override
  String get movementHistory => 'Movement history';

  @override
  String get noMovementsYet => 'No movements recorded yet.';

  @override
  String get newMovement => 'New movement';

  @override
  String get motivesAdminHint =>
      'Register reasons in Django Admin (Movement reasons).';

  @override
  String get motive => 'Reason';

  @override
  String get selectOption => 'Select';

  @override
  String get selectMotive => 'Select the movement reason.';

  @override
  String get registeredLocationsHint =>
      'Registered locations (tap to fill destination)';

  @override
  String get destinationRequired => 'Enter the destination location.';

  @override
  String get destinationLocation => 'Destination location';

  @override
  String get observationsOptional => 'Notes / details (optional)';

  @override
  String get registerMovement => 'Record movement';

  @override
  String get movementSaved => 'Movement saved.';

  @override
  String get selectedProduct => 'Selected product';

  @override
  String get client => 'Client';

  @override
  String get subclient => 'Branch / subclient';

  @override
  String get currentLocation => 'Current location';

  @override
  String get flashlightTooltip => 'Torch';

  @override
  String get scanQrTitle => 'Scan QR code';

  @override
  String get scanQrHint =>
      'Point at the product QR. It can be plain serial text or a link with ?sn=';

  @override
  String get serialLookupIntro =>
      'Look up stock by serial number (same as Django: serial tracking).';

  @override
  String get serialTrackTitle => 'Track product';

  @override
  String get productAllocationHeading => 'Product / allocation';

  @override
  String get stockUnitLabel => 'Stock unit';

  @override
  String get observationsLabel => 'Notes';

  @override
  String get updatedAtLabel => 'Updated at';

  @override
  String get subclientBranchLabel => 'Branch / subclient';

  @override
  String get enterSerialHint => 'Type or use the QR reader';

  @override
  String get helpdeskTitle => 'Helpdesk';

  @override
  String motivesLoadError(String error) {
    return 'Failed to load reasons: $error';
  }

  @override
  String get movementFrom => 'from:';

  @override
  String movementAuthor(String name) {
    return 'by $name';
  }

  @override
  String get expenseModuleTitle => 'Expenses';

  @override
  String get expenseListTile => 'List';

  @override
  String get expenseApprovalsTile => 'Approvals';

  @override
  String get expensePaymentsTile => 'Payments';

  @override
  String get expenseDashboardTile => 'Dashboard';

  @override
  String get expenseNoCompanies =>
      'No clients available for expenses. Check your access in the web portal.';

  @override
  String get expenseSelectClient => 'Client';

  @override
  String get expenseStatusFilter => 'Status';

  @override
  String get expenseStatusAll => 'All';

  @override
  String get expenseStatusDraft => 'Draft';

  @override
  String get expenseStatusPending => 'Pending';

  @override
  String get expenseStatusApproved => 'Approved';

  @override
  String get expenseStatusRejected => 'Rejected';

  @override
  String get expenseStatusAudited => 'Audited';

  @override
  String get expenseStatusPaid => 'Paid';

  @override
  String get expenseNew => 'New expense';

  @override
  String get expenseEdit => 'Edit';

  @override
  String get expenseDetail => 'Details';

  @override
  String get expenseFieldTitle => 'Title';

  @override
  String get expenseFieldDescription => 'Description';

  @override
  String get expenseFieldAmount => 'Amount';

  @override
  String get expenseFieldDate => 'Date';

  @override
  String get expenseFieldLocation => 'Location';

  @override
  String get expenseTipoDespesa => 'Expense type';

  @override
  String get expenseCentroCusto => 'Cost center (optional)';

  @override
  String get expenseContractId => 'Contract ID (optional)';

  @override
  String get expenseResponsible => 'Responsible user (optional)';

  @override
  String get expenseReceipt => 'Receipt';

  @override
  String get expensePickFile => 'Choose file';

  @override
  String get expenseSaveDraft => 'Save draft';

  @override
  String get expenseSubmitApproval => 'Submit for approval';

  @override
  String get expenseDelete => 'Delete';

  @override
  String get expenseApprove => 'Approve';

  @override
  String get expenseReject => 'Reject';

  @override
  String get expenseMarkAudited => 'Mark audited';

  @override
  String get expenseMarkPaid => 'Mark paid';

  @override
  String get expenseCommentHint => 'Comment (optional)';

  @override
  String get expenseAuditTitle => 'History';

  @override
  String get expenseRiskScore => 'Risk score';

  @override
  String get expenseOpenReceipt => 'Open receipt';

  @override
  String get expenseDuplicateWarning =>
      'This receipt may be a duplicate. Continue anyway?';

  @override
  String get expenseAnalyticsHint =>
      'Numeric summary from the API (same endpoint as the web portal).';

  @override
  String expenseLoadError(String message) {
    return 'Error: $message';
  }

  @override
  String get expenseEmptyList => 'No expenses for this filter.';

  @override
  String get expenseTitleRequired => 'Enter a title.';

  @override
  String get expenseAmountInvalid => 'Enter an amount greater than zero.';

  @override
  String get expenseAuthor => 'Author';

  @override
  String get expenseDeleteConfirm => 'Delete this draft permanently?';

  @override
  String get expenseGroupsTile => 'Groups';

  @override
  String get expenseBatchImportTile => 'Batch import';

  @override
  String get expenseAuditModuleTile => 'Audit';

  @override
  String get expenseRefresh => 'Refresh';

  @override
  String get expenseGroupListTitle => 'Groups (drafts)';

  @override
  String get expenseGroupDetailTitle => 'Batch';

  @override
  String get expenseGroupSubmitBatch => 'Submit batch for approval';

  @override
  String get expenseGroupMembers => 'Expenses in batch';

  @override
  String get expensePendingGroupsTitle => 'Pending groups';

  @override
  String get expenseByExpenseTitle => 'By expense';

  @override
  String get expenseApproveGroup => 'Approve group';

  @override
  String get expenseRejectGroup => 'Reject group';

  @override
  String get expensePaymentsScreenTitle => 'Payments (finance)';

  @override
  String get expenseSelectAll => 'Select all';

  @override
  String get expenseDeselectAll => 'Clear selection';

  @override
  String get expenseExportCsv => 'Copy CSV';

  @override
  String get expenseExportCsvDone => 'CSV copied to clipboard.';

  @override
  String get expenseApplyReturn => 'Apply return CSV';

  @override
  String get expenseSapSend => 'Send to SAP';

  @override
  String get expenseSapBulk => 'SAP selected';

  @override
  String get expenseFinanceApprove => 'Approve (finance)';

  @override
  String get expenseFinanceReject => 'Reject (finance)';

  @override
  String get expenseAnomaliesTitle => 'Anomalies';

  @override
  String get expenseExtractedTitle => 'Extracted data (OCR)';

  @override
  String get expenseApprovalsChainTitle => 'Approval levels';

  @override
  String get expenseAgrupamentoTitulo => 'Group title';

  @override
  String get expenseBatchImportHint =>
      'Enter the group title and pick receipt images. Draft expenses will be created (OCR + AI classification when available).';

  @override
  String get expenseOcrFill => 'Fill with OCR';

  @override
  String get expenseClassifyTipo => 'Suggest type (AI)';

  @override
  String get expenseStatusPendingFinance => 'Pending finance';

  @override
  String get expenseStatusFinanceApproved => 'Finance approved';

  @override
  String get expenseStatusFinanceRejected => 'Finance rejected';

  @override
  String get expenseDateFrom => 'From date';

  @override
  String get expenseDateTo => 'To date';

  @override
  String get expenseClearPeriod => 'Clear period';

  @override
  String get expenseApplyReturnResult => 'Return file result';

  @override
  String get expenseSelectOne => 'Select at least one expense.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get assetsModuleTitle => 'Asset control';

  @override
  String get assetsNoClient => 'Select a client to continue.';

  @override
  String get assetsTabProducts => 'Products';

  @override
  String get assetsTabAssets => 'Assets';

  @override
  String get assetsTabMovements => 'Movements';

  @override
  String get assetsInsertProduct => 'New product';

  @override
  String get assetsFieldName => 'Name';

  @override
  String get assetsFieldBrand => 'Brand';

  @override
  String get assetsFieldModel => 'Model';

  @override
  String get assetsFieldInternalCode => 'Internal code';

  @override
  String get assetsFieldType => 'Type';

  @override
  String get assetsTypeHardware => 'Hardware';

  @override
  String get assetsTypeService => 'Service';

  @override
  String get assetsFieldDescription => 'Description';

  @override
  String get assetsFieldDatasheet => 'Datasheet (URL)';

  @override
  String get assetsFieldManual => 'Manual (file)';

  @override
  String get assetsSaveProduct => 'Save product';

  @override
  String get assetsInsertAsset => 'New asset';

  @override
  String get assetsFilterByProduct => 'Product';

  @override
  String get assetsSerial => 'Serial number';

  @override
  String get assetsPartNumber => 'Part number';

  @override
  String get assetsDisplayName => 'Display name';

  @override
  String get assetsMovPrereq =>
      'Add products, assets, and at least one movement reason first.';

  @override
  String get assetsNewMovement => 'New movement';

  @override
  String get assetsColAsset => 'Asset';

  @override
  String get assetsMotivo => 'Reason';

  @override
  String get assetsDestino => 'Destination';

  @override
  String get assetsResponsible => 'Responsible';

  @override
  String get assetsObservation => 'Notes';

  @override
  String get assetsSaveMovement => 'Record movement';

  @override
  String get assetsEditAsset => 'Edit asset';

  @override
  String get assetsEditProduct => 'Edit product';

  @override
  String get assetsColActive => 'Active';

  @override
  String get assetsFilterSearch => 'Search…';

  @override
  String get assetsFilterSearchAssets => 'Search assets…';

  @override
  String get assetsAllProducts => 'All products';

  @override
  String get assetsFilterTipoAll => 'All types';

  @override
  String get assetsFilterAtivoAll => 'All';

  @override
  String get assetsFilterAtivoYes => 'Active only';

  @override
  String get assetsFilterAtivoNo => 'Inactive only';

  @override
  String get assetsYesShort => 'Yes';

  @override
  String get assetsNoShort => 'No';

  @override
  String get assetsProductTrackingHint => 'View assets for this product';
}
