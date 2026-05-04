// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Conversys';

  @override
  String get language => 'Idioma';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSystem => 'Predeterminado del sistema';

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
  String get headerSettings => 'Configuracion';

  @override
  String get headerLogout => 'Salir';

  @override
  String get headerLogoutConfirm => 'Realmente deseas cerrar sesion?';

  @override
  String get userRoleLider => 'Lider';

  @override
  String get userRoleGerenteProjeto => 'Gerente de proyecto';

  @override
  String get userRoleAnalista => 'Analista';

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
  String get expenseFormSave => 'Save';

  @override
  String get expenseFormSend => 'Send';

  @override
  String get expenseReceiptSection => 'Receipt (image)';

  @override
  String get expenseReceiptOcrHint =>
      'Uses OpenAI (same OPENAI_API_KEY as the server) to read the receipt. Select an image file or use Take photo.';

  @override
  String get expenseTakePhoto => 'Take photo';

  @override
  String get expenseReceiptEmptyPreview =>
      'La vista previa del comprobante aparecerá aquí después de tomar una foto o elegir un archivo.';

  @override
  String get expenseFieldClient => 'Client';

  @override
  String get expenseApproverProfileHint =>
      'Set on your user profile; cannot be changed here.';

  @override
  String get expenseFieldApprover => 'Approver';

  @override
  String get expenseFieldFinanceApprover => 'Finance approver';

  @override
  String get expenseContractNone => '(no contract)';

  @override
  String get expenseCentroNone => '(no cost center)';

  @override
  String get expenseDraftSavedSnackbar => 'Draft saved.';

  @override
  String get expenseAgrupamentoHint =>
      'Optional. Suggestions from your previous groupings; you can type another title or leave blank.';

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
  String get expenseSessionClientLabel => 'Session client';

  @override
  String get expenseListSelectClienteApp =>
      'Select a company in the app header to list expenses.';

  @override
  String get expenseFilterPeriod => 'Period';

  @override
  String get expenseFilterPeriodAll => 'All time';

  @override
  String get expenseFilterPeriodLast7Days => 'Last 7 days';

  @override
  String get expenseFilterPeriodCurrentMonth => 'Current month';

  @override
  String get expenseFilterPeriodCurrentYear => 'Current year';

  @override
  String get expenseFilterPeriodLast30Days => 'Last 30 days';

  @override
  String get expenseFilterPeriodLastYear => 'Last year';

  @override
  String get expenseFilterPeriodCustom => 'Custom range';

  @override
  String get expenseFilterGroupAll => 'All groups';

  @override
  String get expenseFilterUserAll => 'All users';

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

  @override
  String get assetsClearFilters => 'Clear filters';

  @override
  String get assetsListProducts => 'Products';

  @override
  String get assetsColName => 'Name';

  @override
  String get assetsColBrand => 'Brand';

  @override
  String get assetsColModel => 'Model';

  @override
  String get assetsColDescription => 'Description';

  @override
  String get assetsColDatasheet => 'Datasheet';

  @override
  String get assetsColManual => 'Manual';

  @override
  String get assetsColType => 'Type';

  @override
  String get assetsColCode => 'Code';

  @override
  String get assetsColUpdated => 'Updated';

  @override
  String get assetsColTracking => 'Tracking';

  @override
  String get assetsProductsEmpty => 'No products yet.';

  @override
  String get assetsEmptyProductsFiltered =>
      'No products match the current filters.';

  @override
  String get assetsListAssets => 'Assets';

  @override
  String get assetsColProduct => 'Product';

  @override
  String get assetsAssetsEmpty => 'No assets yet.';

  @override
  String get assetsEmptyAssetsFiltered =>
      'No assets match the current filters.';

  @override
  String get assetsFilterSearchMovements => 'Search movements…';

  @override
  String get assetsFilterByAsset => 'Filter by asset';

  @override
  String get assetsAllAssets => 'All assets';

  @override
  String get assetsMovementList => 'Movements';

  @override
  String get assetsNoMovements => 'No movements recorded yet.';

  @override
  String get assetsEmptyMovementsFiltered =>
      'No movements match the current filters.';

  @override
  String get assetsColWhen => 'When';

  @override
  String get assetsColRegisteredBy => 'Recorded by';

  @override
  String get assetsFieldSelectAsset => 'Asset';

  @override
  String get assetsServiceSerialOrPart =>
      'For service products, enter a serial number and/or part number.';

  @override
  String get assetsSaveAsset => 'Save asset';

  @override
  String get assetsPickAsset => 'Select an asset';

  @override
  String get assetsNoMotives =>
      'No movement reasons registered. Add them in Django Admin.';

  @override
  String get assetsNoStockLocations => 'No stock locations for this client.';

  @override
  String get assetsReplaceManualHint => 'Replace manual (optional file)';

  @override
  String get assetsFieldProduct => 'Product';

  @override
  String get assetsFilterByProductLabel => 'Filter by product';

  @override
  String get marketplaceModuleTitle => 'Marketplace';

  @override
  String get marketplaceTabCatalog => 'Catalog';

  @override
  String get marketplaceTabCredits => 'Credits';

  @override
  String get marketplaceSubtitle =>
      'Browse service groups and acquire products for your client.';

  @override
  String get marketplaceBackGroups => 'Back to groups';

  @override
  String get marketplaceGroupDetailIntro =>
      'Products are grouped by subgroup. Use Acquire to add an item to the client basket when a price is active.';

  @override
  String get marketplaceLoading => 'Loading…';

  @override
  String get marketplaceRetry => 'Refresh';

  @override
  String get marketplaceErrorTitle => 'Could not load';

  @override
  String get marketplaceErrorGeneric => 'Something went wrong. Try again.';

  @override
  String get marketplaceEmptyTitle => 'No groups yet';

  @override
  String get marketplaceEmpty =>
      'There are no marketplace catalog groups configured.';

  @override
  String get marketplaceBadgeActive => 'Active';

  @override
  String get marketplaceInactive => 'Inactive';

  @override
  String get marketplaceNoDescription => 'No description';

  @override
  String get marketplaceSubgroupsCount => 'subgroups';

  @override
  String get marketplaceEmptySubgroups => 'This group has no subgroups.';

  @override
  String get marketplaceEmptyProducts => 'No products in this subgroup.';

  @override
  String get marketplaceTableColProduct => 'Product';

  @override
  String get marketplaceTableColDescription => 'Description';

  @override
  String get marketplaceTableColValue => 'Price';

  @override
  String get marketplaceTableColPeriod => 'Period';

  @override
  String get marketplaceTableColStatus => 'Status';

  @override
  String get marketplaceTableColAction => 'Action';

  @override
  String get marketplaceNoPriceVigente => 'No current price';

  @override
  String get marketplaceAcquireInactive => 'Inactive product';

  @override
  String get marketplaceAcquireNeedClient =>
      'Select a client to acquire products.';

  @override
  String get marketplaceAcquireLoading => 'Acquiring…';

  @override
  String get marketplaceAcquireButton => 'Acquire';

  @override
  String get marketplaceAcquireSuccessIntro => 'Item added.';

  @override
  String get marketplaceAcquireVigenciaStart => 'Valid from';

  @override
  String get marketplaceAcquireVigenciaEnd => 'Valid until';

  @override
  String get marketplaceAcquireError => 'Could not acquire product.';

  @override
  String get marketplacePeriodoDIARIO => 'Daily';

  @override
  String get marketplacePeriodoMENSAL => 'Monthly';

  @override
  String get marketplacePeriodoANUAL => 'Yearly';

  @override
  String get marketplacePeriodoPOR_SEGUNDO => 'Per second';

  @override
  String get marketplacePeriodoPOR_HORA => 'Per hour';

  @override
  String get marketplaceCreditsTitle => 'Marketplace credits';

  @override
  String get marketplaceCreditsBalance => 'Available balance';

  @override
  String get marketplaceCreditsBasket => 'Acquired products';

  @override
  String get marketplaceCreditsBasketEmpty => 'No acquired items yet.';

  @override
  String get marketplaceCreditsBasketColProduct => 'Product';

  @override
  String get marketplaceCreditsBasketColStart => 'Start';

  @override
  String get marketplaceCreditsBasketColEnd => 'End';

  @override
  String get marketplaceCreditsBasketColAcquired => 'Acquired at';

  @override
  String get marketplaceCreditsAddSection => 'Add credit';

  @override
  String get marketplaceCreditsAmount => 'Amount (BRL)';

  @override
  String get marketplaceCreditsInvalidAmount =>
      'Enter a valid amount greater than zero.';

  @override
  String get marketplaceCreditsSubmit => 'Add credit';

  @override
  String get marketplaceCreditsSubmitting => 'Submitting…';

  @override
  String get marketplaceCreditsHistory => 'History';

  @override
  String get marketplaceCreditsEmptyHistory => 'No movements yet.';

  @override
  String get marketplaceCreditsTableDate => 'Date';

  @override
  String get marketplaceCreditsTableType => 'Type';

  @override
  String get marketplaceCreditsTableAmount => 'Amount';

  @override
  String get marketplaceCreditsTableAfter => 'Balance after';

  @override
  String get marketplaceCreditsTableDesc => 'Description';

  @override
  String get marketplaceCreditsTypeIn => 'Credit in';

  @override
  String get marketplaceCreditsTypeOut => 'Debit out';

  @override
  String get marketplaceCreditsLoadError => 'Could not load credit data.';

  @override
  String get marketplaceCreditsNoClient => 'Select a client to manage credits.';

  @override
  String get settingsTabProfile => 'My profile';

  @override
  String get settingsTabClients => 'Clients';

  @override
  String get settingsTabTeam => 'Team';

  @override
  String get settingsTabSecurity => 'Security';

  @override
  String get settingsTabDesign => 'Design';

  @override
  String get settingsFirstName => 'First name';

  @override
  String get settingsLastName => 'Last name';

  @override
  String get settingsContactEmail => 'Contact email';

  @override
  String get settingsLoginReadonly => 'Login (read-only)';

  @override
  String get settingsSapUserCode => 'SAP user code';

  @override
  String get settingsSapDeptSelect => 'SAP department';

  @override
  String get settingsSapDeptCode => 'SAP department code';

  @override
  String get settingsSapNone => '(none)';

  @override
  String get settingsSaveProfile => 'Save profile';

  @override
  String get settingsProfileSaved => 'Profile updated.';

  @override
  String get settingsProfileError => 'Could not save profile.';

  @override
  String get settingsPickAvatar => 'Change photo';

  @override
  String get settingsPasswordIntro =>
      'Change your password. You will use the new password on next sign-in.';

  @override
  String get settingsCurrentPassword => 'Current password';

  @override
  String get settingsNewPassword => 'New password';

  @override
  String get settingsConfirmNewPassword => 'Confirm new password';

  @override
  String get settingsChangePasswordButton => 'Change password';

  @override
  String get settingsPasswordChanging => 'Changing…';

  @override
  String get settingsPasswordChanged => 'Password changed successfully.';

  @override
  String get settingsPasswordMismatch => 'Confirmation does not match.';

  @override
  String get settingsPasswordTooShort =>
      'New password must be at least 6 characters.';

  @override
  String get settingsPasswordFillAll => 'Fill in all fields.';

  @override
  String get settingsClientsTitle => 'Manage clients';

  @override
  String get settingsNewClient => 'New client';

  @override
  String get settingsEditClient => 'Edit client';

  @override
  String get settingsClientName => 'Name';

  @override
  String get settingsClientDocument => 'Document (tax id)';

  @override
  String get settingsClientEmail => 'Contact email';

  @override
  String get settingsClientPhone => 'Phone';

  @override
  String get settingsSaveClient => 'Save client';

  @override
  String get settingsDeleteClient => 'Delete client';

  @override
  String get settingsDeleteClientConfirm =>
      'Delete this client? This cannot be undone.';

  @override
  String get settingsSubclientes => 'Branches';

  @override
  String get settingsAddSubcliente => 'Add branch';

  @override
  String get settingsSubclienteName => 'Unit name';

  @override
  String get settingsSubclienteCnpj => 'Tax id';

  @override
  String get settingsTeamTitle => 'Create new user';

  @override
  String get settingsUsername => 'Username';

  @override
  String get settingsPassword => 'Password';

  @override
  String get settingsIdSoftdesk => 'Softdesk ID';

  @override
  String get settingsTeamCreate => 'Create user';

  @override
  String get settingsTeamCreating => 'Creating…';

  @override
  String get settingsTeamSuccess => 'User created successfully.';

  @override
  String get settingsTeamNeedMembership =>
      'Add at least one client membership.';

  @override
  String get settingsSelectCliente => 'Client';

  @override
  String get settingsSelectRole => 'Role';

  @override
  String get settingsAddMembership => 'Add membership';

  @override
  String get settingsMenuLogoUrl => 'Menu logo (URL)';

  @override
  String get settingsFrameLogoUrl => 'Frame logo (URL)';

  @override
  String get settingsMenuBg => 'Sidebar menu background';

  @override
  String get settingsMenuText => 'Sidebar menu text';

  @override
  String get settingsHelpdeskNewBg => 'Helpdesk new ticket background';

  @override
  String get settingsFinanceApprover => 'Finance approver (expenses)';

  @override
  String get settingsExpenseApprover => 'Expense approver';

  @override
  String get settingsNoneOption => '— None —';

  @override
  String get settingsDesignTitle => 'Active client design';

  @override
  String get settingsDesignSave => 'Save design';

  @override
  String get settingsLoadError => 'Could not load.';

  @override
  String get settingsShowPassword => 'Show password';

  @override
  String get settingsHidePassword => 'Hide password';

  @override
  String get settingsTipoUsuario => 'User type';

  @override
  String get settingsRemoveMembership => 'Remove membership';
}
