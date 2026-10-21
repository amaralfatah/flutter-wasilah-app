import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/errors/app_exceptions.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/decimal_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/rupiah_input_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/validators.dart';
import 'package:flutter_wasilah_app/features/market/providers/market_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/market_valuation.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/purchase_math.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/update_asset_value_controller.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_primary_button.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_text_field.dart';

/// Membuka sheet "Catat pembelian" untuk [position].
Future<void> showRecordPurchaseSheet(
  BuildContext context,
  PortfolioPosition position,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => RecordPurchaseSheet(position: position),
  );
}

/// Dua angka yang tinggal disalin dari riwayat transaksi broker -- total
/// dibayar (fee termasuk) dan jumlah didapat -- lalu jumlah unit, harga
/// rata-rata beli, dan modal dihitung ulang (lihat [applyPurchase]).
class RecordPurchaseSheet extends ConsumerStatefulWidget {
  const RecordPurchaseSheet({required this.position, super.key});

  final PortfolioPosition position;

  @override
  ConsumerState<RecordPurchaseSheet> createState() =>
      _RecordPurchaseSheetState();
}

class _RecordPurchaseSheetState extends ConsumerState<RecordPurchaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _paidController = TextEditingController();
  final _quantityController = TextEditingController();

  /// Kurs manual, hanya ditampilkan bila kurs pasar tidak tersedia.
  final _rateController = TextEditingController();

  PortfolioPosition get _position => widget.position;
  String get _currency => _position.effectivePriceCurrency;
  bool get _isIdr => _currency == 'IDR';
  bool get _isLot => lotToShareFactor(_position.marketSymbol) > 1;

  @override
  void dispose() {
    _paidController.dispose();
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
    final canAverage = _canAverage;

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
                  l10n.recordPurchaseTitle,
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
                if (!canAverage) ...[
                  Text(
                    l10n.purchaseIncompleteMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                AppTextField(
                  label: l10n.purchasePaidLabel,
                  helperText: l10n.purchasePaidHelper,
                  controller: _paidController,
                  keyboardType: _isIdr
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(decimal: true),
                  // Non-IDR disalin apa adanya dari broker (`19.8782376`),
                  // jadi tidak diformat ulang: titik di sini desimal.
                  inputFormatters: _isIdr
                      ? const [RupiahInputFormatter()]
                      : [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
                  validator: (value) => _validatePositive(value, _parsePaid),
                  onChanged: (_) => setState(() {}),
                  suffixIcon: TradeUnitSuffix(_currency),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.purchaseQuantityLabel,
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [DecimalInputFormatter()],
                  validator: (value) =>
                      _validatePositive(value, parseDecimalInput),
                  onChanged: (_) => setState(() {}),
                  suffixIcon: _isLot ? TradeUnitSuffix(l10n.lotUnit) : null,
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
                    validator: (value) =>
                        _validatePositive(value, parseDecimalInput),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                TradeChangeRow(
                  label: l10n.avgBuyPriceLabel,
                  before: _position.avgBuyPrice == null
                      ? '-'
                      : formatPrice(_position.avgBuyPrice!, _currency),
                  after: result == null
                      ? null
                      : formatPrice(result.avgBuyPrice, _currency),
                ),
                const SizedBox(height: AppSpacing.sm),
                TradeChangeRow(
                  label: l10n.quantityLabel,
                  before: _position.quantity == null
                      ? '-'
                      : formatQuantity(_position.quantity!),
                  after: result == null
                      ? null
                      : formatQuantity(result.quantity),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: l10n.commonSave,
                  onPressed: isLoading || !canAverage
                      ? null
                      : () => _submit(rate),
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double? _parsePaid(String text) =>
      _isIdr ? parseCurrencyInput(text) : parseLooseDecimal(text);

  double? get _manualRate {
    final rate = parseDecimalInput(_rateController.text);
    return rate == null || rate <= 0 ? null : rate;
  }

  /// Posisi lama cukup lengkap untuk dirata-rata, diuji dengan pembelian
  /// dummy.
  bool get _canAverage => _apply(boughtQuantity: 1, paid: 1, rate: 1) != null;

  PurchaseResult? _preview(double? rate) {
    final paid = _parsePaid(_paidController.text);
    final quantity = parseDecimalInput(_quantityController.text);
    if (paid == null || quantity == null || rate == null) {
      return null;
    }
    return _apply(boughtQuantity: quantity, paid: paid, rate: rate);
  }

  PurchaseResult? _apply({
    required double boughtQuantity,
    required double paid,
    required double rate,
  }) => applyPurchase(
    quantity: _position.quantity,
    avgBuyPrice: _position.avgBuyPrice,
    totalCost: _position.totalCost,
    boughtQuantity: boughtQuantity,
    paid: paid,
    rateToIdr: rate,
    lotFactor: lotToShareFactor(_position.marketSymbol),
  );

  String? _validatePositive(String? value, double? Function(String) parse) {
    final parsed = value == null ? null : parse(value);
    return parsed == null || parsed <= 0
        ? context.l10n.invalidNumberMessage
        : null;
  }

  Future<void> _submit(double? rate) async {
    if (!_formKey.currentState!.validate() || rate == null) {
      return;
    }
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();

    try {
      await ref
          .read(updateAssetValueControllerProvider.notifier)
          .recordPurchase(
            position: _position,
            boughtQuantity: parseDecimalInput(_quantityController.text)!,
            paid: _parsePaid(_paidController.text)!,
            rateToIdr: rate,
            recordedAt: DateTime(now.year, now.month, now.day),
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.purchaseRecordedMessage(_position.name))),
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is InvalidPurchaseException
                ? l10n.purchaseIncompleteMessage
                : l10n.purchaseFailedMessage,
          ),
        ),
      );
    }
  }
}

/// Satuan di ujung field (`USD`, `lot`); dipakai juga sheet catat jual.
class TradeUnitSuffix extends StatelessWidget {
  const TradeUnitSuffix(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Align(
        widthFactor: 1,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Baris "label   lama → baru"; panah dan nilai baru muncul setelah input
/// lengkap. Dipakai juga sheet catat jual.
class TradeChangeRow extends StatelessWidget {
  const TradeChangeRow({
    required this.label,
    required this.before,
    required this.after,
    super.key,
  });

  final String label;
  final String before;
  final String? after;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final after = this.after;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(before, style: theme.textTheme.bodyMedium),
        if (after != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(
              Icons.arrow_forward,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            after,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
