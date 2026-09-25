// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navDashboardLabel => 'Home';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDisplaySection => 'Display';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsBackupSection => 'Backup';

  @override
  String get settingsAppSection => 'App';

  @override
  String get settingsAboutApp => 'About app';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get languageIndonesian => 'Indonesian';

  @override
  String get languageEnglish => 'English';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaveChanges => 'Save changes';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonAsset => 'Asset';

  @override
  String get commonCategoryLabel => 'Category';

  @override
  String get commonRecordedAtLabel => 'Recording date';

  @override
  String get commonSelectDatePlaceholder => 'Select date';

  @override
  String get commonCurrentValueLabel => 'Current value';

  @override
  String get commonTotalCostOptionalLabel => 'Total cost (optional)';

  @override
  String get commonReturnLabel => 'Return';

  @override
  String get profitLossGainLabel => 'Gain';

  @override
  String get profitLossLossLabel => 'Loss';

  @override
  String get commonEmptyAssetsTitle => 'No assets yet';

  @override
  String get commonAddAssetLabel => 'Add asset';

  @override
  String get commonAddTargetLabel => 'Add target';

  @override
  String get commonEmptyTargetsTitle => 'No allocation targets yet';

  @override
  String get commonDeleteHistoryTitle => 'Delete history?';

  @override
  String get commonDeleteHistoryMessage =>
      'This month\'s history entry will be deleted.';

  @override
  String get commonHistoryDeletedMessage => 'History deleted.';

  @override
  String get commonDeleteHistoryFailedMessage => 'Failed to delete history.';

  @override
  String get commonEmptyHistoryTitle => 'No history yet';

  @override
  String get updateAssetValueTitle => 'Update asset value';

  @override
  String get assetDropdownLabel => 'Asset';

  @override
  String get updateTypeLabel => 'Update type';

  @override
  String get updateTypeOverride => 'Override';

  @override
  String get updateTypeIncrement => 'Add';

  @override
  String get totalValueFieldLabel => 'Total asset value';

  @override
  String get incrementValueFieldLabel => 'Value addition';

  @override
  String get totalValueFieldHelper =>
      'The asset value will be set to this amount.';

  @override
  String get incrementValueFieldHelper =>
      'This amount will be added to the current asset value.';

  @override
  String get totalCostFieldHelper =>
      'Total funds already contributed. Leave blank if the cost is unchanged.';

  @override
  String get incrementCostFieldLabel => 'Cost addition (optional)';

  @override
  String get incrementCostFieldHelper =>
      'Newly contributed funds. Leave blank if the addition comes from investment gains.';

  @override
  String get noteFieldLabel => 'Note (optional)';

  @override
  String get previewLabel => 'Preview';

  @override
  String get addedValueLabel => 'Added value';

  @override
  String get latestValueLabel => 'Latest value';

  @override
  String get currentCostLabel => 'Current cost';

  @override
  String get addedCostLabel => 'Added cost';

  @override
  String get latestCostLabel => 'Latest cost';

  @override
  String assetValueUpdatedMessage(String assetName) {
    return '$assetName value updated successfully.';
  }

  @override
  String get updateAssetValueFailedMessage =>
      'Failed to update asset value. Try again.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyTwrSinceStartLabel => 'Return since start';

  @override
  String historyTwrYearLabel(String year) {
    return 'Return $year';
  }

  @override
  String get historyTwrAnnualizedLabel => 'Annualized';

  @override
  String get historyTwrCaption =>
      'Time-weighted return: unaffected by deposits, measures strategy results';

  @override
  String get emptyHistoryMessage =>
      'History appears once an asset value is recorded.';

  @override
  String get allFilterLabel => 'All';

  @override
  String get noFilteredDataTitle => 'No data for this filter';

  @override
  String get noFilteredDataMessage => 'Choose another year.';

  @override
  String get initialDataLabel => 'Initial data';

  @override
  String get assetNotFoundTitle => 'Asset not found';

  @override
  String get assetNotFoundMessage => 'The asset you opened is not available.';

  @override
  String get totalCostLabel => 'Total cost';

  @override
  String get allocationLabel => 'Portfolio allocation';

  @override
  String get lastUpdatedLabel => 'Last updated';

  @override
  String get updateValueButton => 'Update value';

  @override
  String get historySectionTitle => 'Value history';

  @override
  String get emptyAssetHistoryMessage =>
      'History appears once the value is updated.';

  @override
  String get defaultAssetDetailTitle => 'Asset detail';

  @override
  String get editAssetTooltip => 'Edit asset';

  @override
  String get targetNotFoundMessage => 'Target not found.';

  @override
  String get editTargetTitle => 'Edit target';

  @override
  String get addTargetTitle => 'Add target';

  @override
  String get targetAllocationLabel => 'Allocation target';

  @override
  String get deleteTargetButton => 'Delete target';

  @override
  String get targetPercentageRequired => 'Allocation target is required.';

  @override
  String get targetPercentageInvalid => 'Invalid allocation target.';

  @override
  String get targetPercentageRange =>
      'Allocation target must be between 0 and 100%.';

  @override
  String get targetSaveFailedMessage => 'Failed to save target. Try again.';

  @override
  String get deleteTargetTitle => 'Delete target?';

  @override
  String deleteTargetMessage(String category) {
    return 'The $category target will be deleted.';
  }

  @override
  String get targetDeleteFailedMessage => 'Failed to delete target. Try again.';

  @override
  String get targetPercentageExceededMessage =>
      'Total allocation target cannot exceed 100%.';

  @override
  String get restoreTitle => 'Restore from backup';

  @override
  String get backupListLoadFailedTitle => 'Failed to load backup list';

  @override
  String get emptyBackupTitle => 'No backups yet';

  @override
  String get emptyBackupMessage => 'Your first backup will appear here.';

  @override
  String get restoreDataTitle => 'Restore this data?';

  @override
  String restoreDataMessage(String date) {
    return 'Your current portfolio data will be replaced with the backup from $date. This action cannot be undone.';
  }

  @override
  String get restoreLabel => 'Restore';

  @override
  String get restoreSuccessMessage => 'Data restored successfully.';

  @override
  String get restoreFailedMessage => 'Restore failed. Try again.';

  @override
  String get assetNotFoundFormMessage => 'Asset not found.';

  @override
  String get editAssetTitle => 'Edit asset';

  @override
  String get addAssetTitle => 'Add asset';

  @override
  String get assetNameLabel => 'Asset name';

  @override
  String get assetNameRequired => 'Asset name is required.';

  @override
  String get assetCodeLabel => 'Asset code';

  @override
  String get assetCodeRequired => 'Asset code is required.';

  @override
  String get totalCostOptionalHelper =>
      'Total funds contributed, used to calculate profit/loss.';

  @override
  String get deleteAssetButton => 'Delete asset';

  @override
  String get deleteAssetTitle => 'Delete asset?';

  @override
  String deleteAssetMessage(String assetName) {
    return 'The asset $assetName will be deleted.';
  }

  @override
  String get assetSaveFailedMessage => 'Failed to save asset. Try again.';

  @override
  String get targetDetailTitle => 'Target detail';

  @override
  String get editTargetTooltip => 'Edit target';

  @override
  String get targetNotFoundTitle => 'Target not found';

  @override
  String get targetNotFoundDetailMessage =>
      'The target you opened is not available.';

  @override
  String get actualValueLabel => 'Actual value';

  @override
  String get targetValueLabel => 'Target value';

  @override
  String assetsInCategoryTitle(String category) {
    return '$category assets';
  }

  @override
  String get emptyAssetsInCategoryMessage => 'No assets in this category yet.';

  @override
  String get reasonableRangeTitle => 'Reasonable range';

  @override
  String toleranceInfoText(String lower, String upper, String tolerance) {
    return '$lower - $upper (tolerance ±$tolerance)';
  }

  @override
  String get toleranceRuleExplanation =>
      'Follows the 5/25 rule: a rebalance is needed once allocation drifts past 5 percentage points or 25% of the target, whichever is smaller.';

  @override
  String get addAssetTooltip => 'Add asset';

  @override
  String get inactiveAssetsLabel => 'Inactive assets';

  @override
  String get targetTitle => 'Target';

  @override
  String get addTargetTooltip => 'Add target';

  @override
  String get emptyTargetsMessage =>
      'Set the ideal share for each asset category so portfolio progress can be calculated.';

  @override
  String get connectGoogleMessage =>
      'Connect a Google account to back up your portfolio data.';

  @override
  String get connectGoogleButton => 'Connect Google account';

  @override
  String get connectedAccountFallback => 'Google account connected';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get autoBackupLabel => 'Automatic backup';

  @override
  String get restoringMessage => 'Restoring data...';

  @override
  String get neverBackedUpMessage => 'Never backed up.';

  @override
  String lastBackupMessage(String date) {
    return 'Last backup: $date';
  }

  @override
  String get backupNowButton => 'Back up now';

  @override
  String get restoreFromBackupButton => 'Restore from backup';

  @override
  String get confirmBackupTitle => 'Back up now?';

  @override
  String get confirmBackupMessage =>
      'A copy of your current portfolio data will be uploaded to Google Drive and the next automatic backup schedule will be recalculated.';

  @override
  String get backupLabel => 'Backup';

  @override
  String get confirmDisconnectTitle => 'Disconnect Google account?';

  @override
  String get confirmDisconnectMessage =>
      'Automatic backup will stop and the app will no longer have access to Google Drive. Data on this device and existing backups will not be deleted.';

  @override
  String get connectFailedMessage => 'Failed to connect Google account.';

  @override
  String get backupFailedMessage => 'Backup failed. Try again later.';

  @override
  String get googleNotConnectedMessage => 'Google account is not connected.';

  @override
  String get googleAuthorizationRequiredMessage =>
      'Google Drive authorization is required.';

  @override
  String get invalidBackupFileMessage => 'Invalid backup file.';

  @override
  String get emptyAssetsDashboardMessage =>
      'Record your first asset to see a summary.';

  @override
  String get noTargetsCardMessage =>
      'Create an allocation target first so portfolio progress can be calculated correctly.';

  @override
  String get mainAssetsTitle => 'Main assets';

  @override
  String get viewAllLabel => 'View all';

  @override
  String get invalidCurrentValueMessage =>
      'Asset value cannot be less than zero.';

  @override
  String get invalidTotalCostMessage => 'Total cost cannot be less than zero.';

  @override
  String get dashboardPortfolioValueLabel => 'Total Equity';

  @override
  String get dashboardCashLabel => 'Cash';

  @override
  String get dashboardCapitalLabel => 'Invested';

  @override
  String get dashboardAssetCountLabel => 'Asset Count';

  @override
  String get dashboardProfitLossLabel => 'P&L';

  @override
  String get dashboardViewHistoryLabel => 'View history';

  @override
  String dashboardTotalPortfolioSemantic(String totalValue, String cash) {
    return 'Total portfolio $totalValue. Cash $cash';
  }

  @override
  String dashboardProfitLossSemantic(
    String cost,
    String profitLossLabel,
    String amount,
  ) {
    return 'Capital $cost. $profitLossLabel $amount';
  }

  @override
  String get assetTableCodeHeader => 'Code';

  @override
  String get assetTableNameHeader => 'Name';

  @override
  String get assetTableAllocationHeader => 'Allocation';

  @override
  String get assetTableValueHeader => 'Value';

  @override
  String get assetTableUpdatedHeader => 'Updated';

  @override
  String get assetTableCurrentPriceHeader => 'Current Price';

  @override
  String get assetTableProfitLossHeader => 'P/L';

  @override
  String assetSemanticValueAllocation(String value, String allocation) {
    return 'Value $value, allocation $allocation';
  }

  @override
  String assetSemanticCostProfitLoss(
    String cost,
    String profitLossWord,
    String amount,
  ) {
    return 'Cost $cost, $profitLossWord $amount';
  }

  @override
  String historyChartSemanticLabelWithCost(
    String startMonth,
    String endMonth,
    String minValue,
    String maxValue,
  ) {
    return 'Value and capital chart from $startMonth to $endMonth, lowest $minValue, highest $maxValue';
  }

  @override
  String historyChartSemanticLabelValueOnly(
    String startMonth,
    String endMonth,
    String minValue,
    String maxValue,
  ) {
    return 'Value chart from $startMonth to $endMonth, lowest $minValue, highest $maxValue';
  }

  @override
  String get historyChartPlaceholderMessage =>
      'Chart appears once there are at least two recorded values.';

  @override
  String allocationBadgeSemanticLabel(String percentage) {
    return 'Allocation $percentage of portfolio';
  }

  @override
  String get targetProgressDefaultLabel => 'Allocation Target';

  @override
  String get targetProgressDefaultSubtitle => 'Ideal portfolio allocation';

  @override
  String targetProgressSemanticLabel(
    String label,
    String percentage,
    String subtitle,
  ) {
    return '$label $percentage percent. $subtitle';
  }

  @override
  String categoryDonutSemanticItem(String category, String percentage) {
    return '$category $percentage percent';
  }

  @override
  String categoryDonutSemanticLabel(String summary) {
    return 'Actual allocation chart by category: $summary';
  }

  @override
  String categoryDonutCategoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Categories',
      one: '1 Category',
    );
    return '$_temp0';
  }

  @override
  String targetAllocationActualOfTarget(String actual, String target) {
    return 'Actual $actual of target $target';
  }

  @override
  String targetAllocationProgressSemanticLabel(String category) {
    return 'Allocation progress $category';
  }

  @override
  String get sectionHeaderInfoTooltip => 'Info';

  @override
  String get appErrorDefaultTitle => 'Data could not be loaded.';

  @override
  String get appErrorDefaultMessage =>
      'Something went wrong while reading the data. Try again.';

  @override
  String get appErrorRetryButtonLabel => 'Try again';

  @override
  String get marketPriceTitle => 'Market Price';

  @override
  String get marketSymbolLabel => 'Yahoo Finance symbol (optional)';

  @override
  String get marketSymbolHelper => 'Example: BMRI.JK · BTC-USD · SPY';

  @override
  String marketAsOf(String dateTime) {
    return 'as of $dateTime';
  }

  @override
  String get marketOfflineChip => 'Offline';

  @override
  String get marketLoading => 'Loading price…';

  @override
  String get marketUnavailableShort => 'Price unavailable';

  @override
  String marketSymbolNotFound(String symbol) {
    return 'Symbol $symbol was not found on Yahoo Finance.';
  }

  @override
  String get marketUnavailable =>
      'Price couldn\'t be loaded. Pull to try again.';

  @override
  String get marketChartEmpty => 'Chart data isn\'t available yet.';

  @override
  String get marketStatsTitle => 'Trading data';

  @override
  String get statPrevClose => 'Previous close';

  @override
  String get statDayHigh => 'Day high';

  @override
  String get statDayLow => 'Day low';

  @override
  String get statVolume => 'Volume';

  @override
  String get statFiftyTwoWeekHigh => '52-week high';

  @override
  String get statFiftyTwoWeekLow => '52-week low';

  @override
  String get editAssetButton => 'Edit Asset';

  @override
  String get chartRange1D => '1D';

  @override
  String get chartRange1W => '1W';

  @override
  String get chartRange1M => '1M';

  @override
  String get chartRange3M => '3M';

  @override
  String get chartRangeYTD => 'YTD';

  @override
  String get chartRange1Y => '1Y';

  @override
  String get chartRange3Y => '3Y';

  @override
  String get chartRange5Y => '5Y';

  @override
  String get chartPeriodToday => 'Today';

  @override
  String get chartPeriodPastWeek => 'Past Week';

  @override
  String get chartPeriodPastMonth => 'Past Month';

  @override
  String get chartPeriodPastThreeMonths => 'Past 3 Months';

  @override
  String get chartPeriodYearToDate => 'Year to Date';

  @override
  String get chartPeriodPastYear => 'Past Year';

  @override
  String get chartPeriodPastThreeYears => 'Past 3 Years';

  @override
  String get chartPeriodPastFiveYears => 'Past 5 Years';

  @override
  String get avgBuyPriceLabel => 'Average buy price';

  @override
  String get avgBuyPriceOptionalLabel => 'Average buy price (optional)';

  @override
  String get avgBuyPriceHelper =>
      'Price per unit in its native currency. E.g. BMRI in IDR, SPY in USD.';

  @override
  String get quantityOptionalLabel => 'Quantity (optional)';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get quantityHelper => 'Number of lots, shares, coins, or grams held.';

  @override
  String get priceCurrencyLabel => 'Buy price currency';

  @override
  String valueSuggestionChip(String value) {
    return 'Use suggestion: $value';
  }

  @override
  String valueSuggestionDetail(String quantity, String price) {
    return '$quantity units × $price (latest price)';
  }

  @override
  String valueSuggestionFxDetail(String currency, String rate) {
    return 'Rate: 1 $currency = $rate';
  }

  @override
  String get assetHasHoldingMessage =>
      'This asset is still in your portfolio. Remove it from the portfolio before deleting.';

  @override
  String get removeFromPortfolioButton => 'Remove from portfolio';

  @override
  String get removeFromPortfolioTitle => 'Remove from portfolio?';

  @override
  String removeFromPortfolioMessage(String assetName) {
    return 'The value and history of $assetName will be removed from the portfolio. The asset itself is kept.';
  }

  @override
  String get portfolioTitle => 'Portfolio';

  @override
  String get masterAssetsTitle => 'Master assets';

  @override
  String get settingsDataSection => 'Data';

  @override
  String get masterAssetsSettingsSubtitle =>
      'Name, code, category, and market symbol';

  @override
  String get emptyMasterAssetsMessage =>
      'Add assets (e.g. stocks, crypto, cash) before recording their value in the portfolio.';

  @override
  String get emptyPortfolioTitle => 'Your portfolio is empty';

  @override
  String get emptyPortfolioMessage =>
      'Pick an asset from the master list and record its value.';

  @override
  String get emptyPortfolioNoMasterMessage =>
      'Create a master asset in Settings first, then record its value here.';

  @override
  String get openMasterAssetsLabel => 'Manage master assets';

  @override
  String get addToPortfolioLabel => 'Record asset value';
}
