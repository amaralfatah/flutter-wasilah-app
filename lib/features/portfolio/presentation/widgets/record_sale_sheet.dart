import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/decimal_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/market_valuation.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/sale_math.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/record_purchase_sheet.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/update_asset_value_controller.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_text_field.dart';

/// Membuka sheet "Catat penjualan" untuk [position].
Future<void> showRecordSaleSheet(
  BuildContext context,
  PortfolioPosition position,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => RecordSaleSheet(position: position),
  );
}

/// Pasangan [RecordPurchaseSheet]: total diterima (setelah fee) dan jumlah
/// dijual disalin dari riwayat broker, lalu jumlah unit dan modal dikurangi
/// proporsional serta untung/rugi terealisasi ditampilkan (lihat
/// [applySale]).
class RecordSaleSheet extends ConsumerStatefulWidget {
  const RecordSaleSheet({required this.position, super.key});

  final PortfolioPosition position;

  @override
  ConsumerState<RecordSaleSheet> createState() => _RecordSaleSheetState();
}

class _RecordSaleSheetState extends ConsumerState<RecordSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _receivedController = TextEditingController();
  final _quantityController = TextEditingController();

  /// Kurs manual, hanya ditampilkan bila kurs pasar tidak tersedia.
  final _rateController = TextEditingController();

  /// Form sudah pernah divalidasi (Simpan ditekan).
  bool _validated = false;

  PortfolioPosition get _position => widget.position;
  String get _currency => _position.effectivePriceCurrency;
  bool get _isIdr => _currency == 'IDR';
  bool get _isLot => lotToShareFactor(_position.marketSymbol) > 1;
  double get _held => _position.quantity ?? 0;

  @override
  void dispose() {
    _receivedController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isLoading = ref.watch(updateAssetValueControllerProvider).isLoading;
    final marketRateValue = _isIdr
        ? const AsyncData<double>(1)
        : ref.watch(fxRateToIdrProvider(_currency));
    final marketRate = marketRateValue.valueOrNull;
    // Field kurs manual hanya saat kurs pasar gagal, bukan selama dimuat.
    final needsManualRate = marketRate == null && marketRateValue.hasError;
    final rate = marketRate ?? _manualRate;
    final result = _preview(rate);
    final canSell = _held > 0;
    final totalCost = _position.totalCost;
    final realized = result?.realizedProfit;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.recordSaleTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  _position.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!canSell) ...[
                  Text(
                    l10n.saleIncompleteMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                AppTextField(
                  label: l10n.saleReceivedLabel,
                  helperText: l10n.saleReceivedHelper,
                  controller: _receivedController,
                  keyboardType: _isIdr
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(decimal: true),
                  // Non-IDR disalin apa adanya dari broker, jadi tidak
                  // diformat ulang: titik di sini desimal.
                  inputFormatters: _isIdr
                      ? const [RupiahInputFormatter()]
                      : [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
                  validator: _validateReceived,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: TradeUnitSuffix(_currency),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.saleQuantityLabel,
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [DecimalInputFormatter()],
                  validator: (_) => _validateQuantity(),
                  onChanged: (_) => setState(() {}),
                  suffixIcon: _isLot ? TradeUnitSuffix(l10n.lotUnit) : null,
                ),
                if (canSell)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: isLoading ? null : _sellAll,
                      child: Text(l10n.sellAllButton),
                    ),
                  ),
                if (needsManualRate) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.fxRateFieldLabel(_currency),
                    helperText: l10n.fxRateManualHint,
                    controller: _rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [
                      DecimalInputFormatter(maxDecimals: 2),
                    ],
                    validator: (value) {
                      final parsed = value == null
                          ? null
                          : parseDecimalInput(value);
                      return parsed == null || parsed <= 0
                          ? l10n.invalidNumberMessage
                          : null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                TradeChangeRow(
                  label: l10n.quantityLabel,
                  before: canSell ? formatQuantity(_held) : '-',
                  after: result == null
                      ? null
                      : formatQuantity(result.quantity),
                ),
                const SizedBox(height: AppSpacing.sm),
                TradeChangeRow(
                  label: l10n.totalCostLabel,
                  before: totalCost == null ? '-' : formatNumber(totalCost),
                  after: result?.totalCost == null
                      ? null
                      : formatNumber(result!.totalCost!),
                ),
                if (realized != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.realizedProfitLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        formatSignedNumber(realized),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: realized >= 0
                              ? AppColors.positiveOf(context)
                              : AppColors.negativeOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: l10n.commonSave,
                  onPressed: isLoading || !canSell ? null : () => _submit(rate),
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Isi jumlah dijual dengan seluruh jumlah dimiliki. Bila form sudah
  /// pernah divalidasi, validasi ulang supaya error lama di field jumlah
  /// tidak tertinggal.
  void _sellAll() {
    setState(() => _quantityController.text = formatQuantity(_held));
    if (_validated) {
      _formKey.currentState?.validate();
    }
  }

  double? _parseReceived(String text) =>
      _isIdr ? parseCurrencyInput(text) : parseLooseDecimal(text);

  /// Jumlah dijual. Teks hasil "Jual semua" dipetakan ke jumlah persis
  /// supaya pembulatan tampilan tidak menyisakan debu unit.
  double? get _soldQuantity {
    final text = _quantityController.text.trim();
    if (_held > 0 && text == formatQuantity(_held)) {
      return _held;
    }
    return parseDecimalInput(text);
  }

  double? get _manualRate {
    final rate = parseDecimalInput(_rateController.text);
    return rate == null || rate <= 0 ? null : rate;
  }

  SaleResult? _preview(double? rate) {
    final received = _parseReceived(_receivedController.text);
    final sold = _soldQuantity;
    if (received == null || sold == null || rate == null) {
      return null;
    }
    return applySale(
      quantity: _position.quantity,
      avgBuyPrice: _position.avgBuyPrice,
      totalCost: _position.totalCost,
      soldQuantity: sold,
      received: received,
      rateToIdr: rate,
      lotFactor: lotToShareFactor(_position.marketSymbol),
    );
  }

  String? _validateReceived(String? value) {
    final parsed = value == null ? null : _parseReceived(value);
    return parsed == null || parsed < 0
        ? context.l10n.invalidNumberMessage
        : null;
  }

  String? _validateQuantity() {
    final sold = _soldQuantity;
    if (sold == null || sold <= 0) {
      return context.l10n.invalidNumberMessage;
    }
    if (sold > _held) {
      return context.l10n.saleExceedsMessage(formatQuantity(_held));
    }
    return null;
  }

  Future<void> _submit(double? rate) async {
    _validated = true;
    if (!_formKey.currentState!.validate() || rate == null) {
      return;
    }
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();

    try {
      await ref
          .read(updateAssetValueControllerProvider.notifier)
          .recordSale(
            position: _position,
            soldQuantity: _soldQuantity!,
            received: _parseReceived(_receivedController.text)!,
            rateToIdr: rate,
            recordedAt: DateTime(now.year, now.month, now.day),
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.saleRecordedMessage(_position.name))),
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is InvalidSaleException
                ? l10n.saleIncompleteMessage
                : l10n.saleFailedMessage,
          ),
        ),
      );
    }
  }
}
